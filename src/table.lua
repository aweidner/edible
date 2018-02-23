local BTree = require("btree").BTree
local Row = require("btree").Row
local Cell = require("btree").Cell
local NilCell = require("btree").NilCell
local lib = require("lib")

local Table = {}

local function matches_type(edible_type, lua_type)
    return (edible_type == "int" and lua_type == "number" or
            edible_type == "string" and lua_type == "string")
end

local function valid_schema(columns)
    for index, column in pairs(columns) do
        assert(column.name ~= nil, "Column name not defined at index " .. tostring(index))
        assert(column.type ~= nil, "Type not defined for column " .. column.name)
    end

    return true
end

local function parse_condition(condition)
    -- TODO: Nearly has to be a better way to do this,
    -- passing in the environment to load?
    if condition == nil then
        return
    end

    return function(result_to_test)
        local ld = "return " .. condition
        local f, message = load(ld, ld, ld, result_to_test)

        assert(message == nil, message)
        return f()
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

local function all_columns_requested_are_in(table_columns, select_structure_columns)
    if not select_structure_columns then
        return true
    end

    for _, column in pairs(select_structure_columns) do
        local found = false
        for _, table_column in pairs(table_columns) do
            found = column.name == table_column.name
            if found then
                break
            end
        end
        -- TODO: Need better assertion here, easier to debug error
        assert(found, "Column " .. column.name .. " was not found in table")
    end

    return true
end

-- TODO: Make configurable
local PAGE_SIZE = 256

Table.Table = {}

function Table.Table:new(structure)
    assert(structure.table_name ~= nil, "Table name must be defined")
    assert(valid_schema(structure.columns))

    local new_table = {
        row_id = 1,
        name = structure.table_name,
        columns = structure.columns,
        tree = BTree:new(PAGE_SIZE)
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

function Table.Table:insert(values)
    assert(self:matches_structure(values))
    self.tree:insert(Row:new(self.row_id, lib.l_comprehend(values, function(value)
        if value == lib.NIL then
            return NilCell
        end
        return Cell:new(value)
    end)))
    self.row_id = self.row_id + 1
end

function Table.Table:get(row_id)
    local success, data = pcall(function() return self.tree:select(row_id) end)
    if not success then
        -- TODO: Is there a better way to handle this than simply
        -- returning nil?
        return nil
    end

    return self:format_row(data)
end

function Table.Table:find(select_structure)
    assert(fqn_tables_come_from(self.name, select_structure.columns))
    assert(all_columns_requested_are_in(self.columns, select_structure.columns))

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

function Table.Table:matches_structure(values)
    assert(#self.columns == #values, "Columns must be the same length as schema")
    for index, column in ipairs(self.columns) do
        if values[index] ~= lib.NIL then
            assert(matches_type(column.type, type(values[index])),
                "Mismatch at column index " .. tostring(index))
        end
    end
    return true
end

return Table
