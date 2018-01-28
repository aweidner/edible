-- Defines the fundamental B-Tree structure used in Edible including any components
-- that structure relies on.
local BTree = {}

BTree.Cell = {}

local function get_size(data)
    -- Return the size of the data based on type.  This makes it
    -- easier to enforce page size rules
    --
    -- ASSUMPTION: We are operating on the standard Lua with 64 bit
    -- integers and 8 byte per code point strings

    if type(data) == "number" then
        return 8
    elseif type(data) == "string" then
        return #data
    end
end

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

return BTree
