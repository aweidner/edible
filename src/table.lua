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

local function matches_type(edible_type, lua_type)
    return (edible_type == "int" and lua_type == "number" or
            edible_type == "string" and lua_type == "string")
end

function Table.ColumnLookup:new(columns)
    local new_column_lookup = {
        columns = columns
    }
    setmetatable(new_column_lookup, self)
    self.__index = self
    return new_column_lookup
end

function Table.ColumnLookup:iterate()
    return ipairs(self.columns)
end

function Table.ColumnLookup:by_name(name)
    for _, column in pairs(self.columns) do
        if column.name == name then
            return column
        end
    end

    return nil
end

function Table.ColumnLookup:names()
    if not self.columns then
        return {}
    end

    local names = {}
    for _, column in pairs(self.columns) do
        table.insert(names, column.name)
    end
    return names
end

function Table.Table:new(structure)
    check.table_structure(structure)

    local new_table = {
        row_id = 1,
        name = structure.table_name,
        column_lookup = Table.ColumnLookup:new(structure.columns),
        tree = BTree:new(config.PAGE_SIZE)
    }

    setmetatable(new_table, self)
    self.__index = self
    return new_table
end

function Table.Table:format_row(data)
    local result = {}
    for index, column in self.column_lookup:iterate() do
        result[column.name] = data:get(index).data
    end
    return result
end

function Table.Table:insert(columns)
    assert(#columns.values == #columns.columns,
        "Mismatch between number of columns and values")

    local values = {}
    for index, column in ipairs(columns.columns) do
        local column_name = column.name
        local value = columns.values[index].value
        local existing_column = self.column_lookup:by_name(column_name)

        assert(existing_column,
            "Column " .. column_name .. " was not defined")

        assert(value == lib.NIL or matches_type(existing_column.type, type(value)))
        table.insert(values, value)
    end

    self.tree:insert(Row:new(self.row_id, lib.map(values, function(value)
        if value == lib.NIL then
            return NilCell
        end
        return Cell:new(value)
    end)))

    self.row_id = self.row_id + 1
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
    check.subset(self.column_lookup:names(),
                 Table.ColumnLookup:new(select_structure.columns):names())


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
