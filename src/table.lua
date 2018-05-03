local BTree = require("btree").BTree
local Row = require("btree").Row
local Cell = require("btree").Cell
local NilCell = require("btree").NilCell
local lib = require("lib")
local config = require("config")
local Schema = require("schema")

local Table = {}

Table.ColumnLookup = {}
Table.Table = {}

function Table.Table:new(table_name, schema)
    local new_table = {
        row_id = 1,
        schema = schema,
        name = table_name,
        tree = BTree:new(config.PAGE_SIZE)
    }

    setmetatable(new_table, self)
    self.__index = self
    return new_table
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

function Table.Table:format_row(data)
    local result = {}
    for index, column in ipairs(self.schema.columns) do
        result[column.display] = data:get(index).data
    end
    return result
end

function Table.Table:insert(structure)
    local fqn_column_names = {}

    -- Translate column names to fully qualified names
    for _, column in pairs(structure.columns) do
        table.insert(fqn_column_names, Schema.fqnify(self.name, column.name))
    end

    -- Translate selected columns to list of values at indexes
    -- to insert.  Assert if a fully qualified name is not found
    local intermediate_values_to_insert = {}
    local values = structure.values
    for index, fqn in ipairs(fqn_column_names) do
        local column_definition = self.schema:by_fqn(fqn)
        local value = values[index].value

        assert(column_definition, string.format(
            "Column %s does not exist on table %s", fqn, self.name))
        assert(column_definition.type == type(value) or value == lib.NIL, string.format(
            "Data at column %s is the wrong type: found [%s] expected [%s]",
                fqn, type(value), column_definition.type))

        intermediate_values_to_insert[column_definition.index] = value
    end

    -- Translate intermediate values to final values filling in
    -- any index gaps with nil
    local final_values_to_insert = {}
    for index = 1, self.schema:length() do
        table.insert(final_values_to_insert,
            intermediate_values_to_insert[index] or lib.NIL)
    end

    -- Insert values into btree mapping lib.NIL to NilCell
    self.tree:insert(Row:new(self.row_id, lib.map(final_values_to_insert, function(value)
        if value == lib.NIL then
            return NilCell
        end
        return Cell:new(value)
    end)))

    -- Increment row id for bookkeeping
    self.row_id = self.row_id + 1
end

function Table.Table:update(structure)
    for _, update in ipairs(structure.updates) do
        update.name = Schema.fqnify(self.name, update.name)
    end

    for row in self.tree:iterate() do
        for _, update in ipairs(structure.updates) do
            local column_index = self.schema:by_fqn(update.name).index
            row:get(column_index).data = update.value
        end
    end
end

function Table.Table:iterate()
    return coroutine.wrap(function()
        for row in self.tree:iterate() do
            coroutine.yield(self:format_row(row))
        end
    end)
end

return Table
