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

return Table
