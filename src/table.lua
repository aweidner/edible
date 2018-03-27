local BTree = require("btree").BTree
local Row = require("btree").Row
local Cell = require("btree").Cell
local NilCell = require("btree").NilCell
local lib = require("lib")
local config = require("config")
local check = require("check")

local Table = {}

Table.ColumnLookup = {}
Table.Table = {}

local function parse_condition(condition)
    if condition == nil then
        return
    end

    return function(result_to_test)
        local created_code = "return " .. condition
        local matches_condition, message = load(
            created_code,
            created_code,
            created_code, result_to_test)

        assert(message == nil, message)
        return matches_condition()
    end
end

local function fqn_tables_come_from(table_name, columns)
    if not columns or #columns == 0 then
        return true
    end

    for _, column in pairs(columns) do
        assert(column.table_name == nil or column.table_name == table_name)
    end

    return true
end

local function assert_operation_columns_are_subset_of_table_columns(
        table_columns, operation_columns)
    local return_name = (function(column) return column.name end)
    check.subset(lib.map(table_columns, return_name),
                 lib.map(operation_columns, return_name))
end

function Table.Table:new(structure)
    check.table_structure(structure)

    local new_table = {
        row_id = 1,
        name = structure.table_name,
        columns = structure.columns,
        tree = BTree:new(config.PAGE_SIZE)
    }

    setmetatable(new_table, self)
    self.__index = self
    return new_table
end

function Table.Table:format_row(data)
    local result = {}
    for index, column in ipairs(self.columns) do
        result[column.name] = data:get(index).data
    end
    return result
end

function Table.Table:insert(columns)
    assert(#columns.values == #columns.columns,
        "Mismatch between number of columns and values")
    assert_operation_columns_are_subset_of_table_columns(
        self.columns, columns.columns)

    local values_to_insert = {}

    -- This could alternatively be done by zipping the items
    -- from columns.columns and columns.values into one table
    -- and then iterating through it, but seeking instead of
    -- zipping means only one iteration
    for _, column in ipairs(self.columns) do
        -- Find the index of the column in columns.columns
        local index_of_value = nil
        for index, column_definition in ipairs(columns.columns) do
            if column_definition.name == column.name then
                -- Column was found, this index is also the index
                -- of the value
                index_of_value = index
            end
        end

        if index_of_value then
            local this_value = columns.values[index_of_value].value
            assert(type(this_value) == column.type or this_value == lib.NIL)
            table.insert(values_to_insert, this_value)
        else
            table.insert(values_to_insert, lib.NIL)
        end
    end

    self:insert_all(values_to_insert)
    self.row_id = self.row_id + 1
end

function Table.Table:insert_all(values_to_insert)
    -- Values may contain the Nil representation.  Translate this into
    -- a NilCell for the BTree
    local final_values = lib.map(values_to_insert, function(value)
        if value == lib.NIL then
            return NilCell
        end
        return Cell:new(value)
    end)

    self.tree:insert(Row:new(self.row_id, final_values))
end

function Table.Table:get(row_id)
    -- Attempt to get a single row by id from the B-Tree.  If the row id
    -- does not exist in the B-Tree, return nil.
    --
    -- This method does not interact with SELECT statements in any way,
    -- it simply attempts to fetch a row by row id.
    local success, data = pcall(function() return self.tree:select(row_id) end)
    if not success then
        return nil
    end

    return self:format_row(data)
end

function Table.Table:find(select_structure)
    assert(fqn_tables_come_from(self.name, select_structure.columns))
    assert_operation_columns_are_subset_of_table_columns(
        self.columns, select_structure.columns or {})

    local matches_condition = (parse_condition(select_structure.condition) or
                               (function() return true end))

    return coroutine.wrap(function()
        for row in self.tree:iterate() do
            local formatted_row = self:format_row(row)
            if matches_condition(formatted_row) then

                -- Format the columns into only the selected columns or return
                -- all columns if no columns were requested
                if select_structure.columns then
                    local selected_columns = {}
                    for _, column in pairs(select_structure.columns) do
                        selected_columns[column.name] = formatted_row[column.name]
                    end
                    coroutine.yield(selected_columns)
                else
                    coroutine.yield(formatted_row)
                end
            end
        end
    end)
end

return Table
