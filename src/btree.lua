local lib = require('lib')

-- Defines the fundamental B-Tree structure used in Edible including any components
-- that structure relies on.
local BTree = {}

local function get_size(data)
    -- Return the size of the data based on type.  This makes it
    -- easier to enforce page size rules
    --
    -- ASSUMPTION: We are operating on the standard Lua with 64 bit
    -- integers and 8 byte per code point strings
    assert(data == nil or type(data) == "number" or type(data) == "string")

    if type(data) == "number" then
        return 8
    elseif type(data) == "string" then
        return #data
    elseif type(data) == "nil" then
        return 0
    end
end

BTree.Cell = {}
BTree.Row = {}
BTree.Page = {}

function BTree.Cell:new(data)
    -- A cell is the fundamental data container in edible.  Cells are capable of storing
    -- any type of Lua data type in the `data` attribute.  Cells also store their
    -- size.  Cells are meant to be immutable, once created they can **should** never be edited.

    local new_cell = {data = data, size = 0}
    setmetatable(new_cell, self)
    self.__index = self

    new_cell.size = get_size(new_cell.data) + get_size(new_cell.size)
    return new_cell
end


-- Instance of a cell with no value.  Flyweight to keep overhead down for cells that don't have
-- a value
BTree.NilCell = BTree.Cell:new()

function BTree.Row:new(row_id, cells)
    -- Rows are containers for cells with an attached id.  Row IDs should be unique
    -- within the context of a single BTree (or Table)
    --
    -- ASSUMPTION: Cells may only contain Cell objects, they may not contain
    -- primitive values.  Additionally if a cell should contain no data, then
    -- it should be an instance of NilCell for efficiency

    assert(row_id ~= nil, "Row ID may not be nil")
    assert(type(row_id) == "number", "Row ID must be a number")
    assert(row_id > 0, "Row ID must be greater than 0")

    local new_row = {cells = cells or {}, id = row_id}

    setmetatable(new_row, self)
    self.__index = self
    return new_row
end

function BTree.Row:get(cell_position)
    -- Return the cell at the given position
    return self.cells[cell_position]
end

function BTree.Row:size()
    -- The size of a BTree row is the sum of all the cell sizes plus
    -- the size of the row id (a number)
    return lib.sum(coroutine.wrap(function()
        for _, cell in ipairs(self.cells) do
            coroutine.yield(cell.size)
        end
    end)) + get_size(self.id)
end

function BTree.Page:new(max_size, rows)
    table.sort(rows, function(a, b)
        return a.id < b.id
    end)

    local new_page = {max_size = max_size, rows = rows}
    setmetatable(new_page, self)
    self.__index = self
    return new_page
end

function BTree.Page:size()
    return lib.sum(coroutine.wrap(function()
        for _, row in ipairs(self.rows) do
            coroutine.yield(row:size())
        end
    end)) + get_size(self.max_size)
end

function BTree.Page:iterate_rows()
    return coroutine.wrap(function()
        for _, row in ipairs(self.rows) do
            coroutine.yield(row)
        end
    end)
end

function BTree.Page:get_row(row_id)
    local row_index = lib.find(self.rows, function(row)
        return row.id - row_id
    end)
    assert(row_index > 0, "Row was not located in this page")
    return self.rows[row_index]
end

return BTree
