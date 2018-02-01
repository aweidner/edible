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
BTree.Node = {}

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

    local new_row = {cells = cells or {}, _id = row_id}

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
    end)) + get_size(self._id)
end

function BTree.Row:id()
    -- Implemented as a function for consistency of interface
    -- with other "id-ables"
    return self._id
end

-- In order for page to store something, it must implement the following methods:
--      :size() - Returns the integer size cost of storing this object in a page
--      :id() - The identifier for this item used in sorting

function BTree.Page:new(max_size, elements)
    -- A Page is a collection of elements which meet a size constraint supplied in
    -- `max_size`.  A page will not be split when it is over the maximum size,
    -- and will continue adding data to it.  Users of `Page` should
    -- regularly call `should_split` to see if the Page can now be split.  If
    -- the page can be split, users should call `split` which will return two
    -- pages split as evenly as possible*
    --
    -- Rows are kept in sorted order within a page. Rows will be sorted upon being
    -- supplied to a page if they are not already sorted.

    table.sort(elements, function(a, b)
        return a:id() < b:id()
    end)

    local new_page = {max_size = max_size, elements = elements or {}}
    setmetatable(new_page, self)
    self.__index = self
    return new_page
end

function BTree.Page:id()
    -- The Page id is the maximum element id.  This makes it
    -- simpler when constructing a tree of pages to figure
    -- out which page to navigate to based on the element being
    -- searched for.
    return self.elements[#self.elements]:id()
end

function BTree.Page:add(element)
    -- Add a new element at the appropriate position based on element_id
    table.insert(self.elements, lib.bisect(self.elements, element:id(), function(compare)
        return compare:id()
    end), element)
end

function BTree.Page:size()
    -- Return the total size of this page in memory
    return lib.sum(coroutine.wrap(function()
        for _, element in ipairs(self.elements) do
            coroutine.yield(element:size())
        end
    end)) + get_size(self.max_size)
end

function BTree.Page:iterate()
    -- Iterate through all the elements in order
    return coroutine.wrap(function()
        for _, element in ipairs(self.elements) do
            coroutine.yield(element)
        end
    end)
end

function BTree.Page:get(element_id)
    -- Returns the element with the given `element_id` if it exists in this page.
    -- If the elements does not exist in this page an error will be returned
    local element_index = lib.find(self.elements, function(element)
        return element_id - element:id()
    end)
    assert(element_index > 0, "Row was not located in this page")
    return self.elements[element_index]
end

function BTree.Page:check(element_id)
    -- Check to see if the given elements is in this page
    if pcall(function() self:get(element_id) end) then
        return true
    else
        return false
    end
end

function BTree.Page:should_split()
    -- Determine if the page should be split.  Pages must be split
    -- when they contain more than one element AND their size is greater
    -- than the maximum size.  A page with only one element cannot be split
    -- since element are indivisible.
    return self:size() > self.max_size and #self.elements > 1
end

function BTree.Page:split()
    -- Split the Page into two pages.
    --
    -- The first page will contain all of the original elements except
    -- those that are split two the second page.
    --
    -- The second page will contain elements which have an id strictly
    -- greater than the last node in the first page (elements will
    -- be split from the right end).  The size of the second page
    -- should be no larger than the max size allowed for the page it
    -- was split from.  The exception to this rule is that there will
    -- ALWAYS be at least one element split from the first page even
    -- when that element would violate the size constraint rule.
    --
    -- The algorithm will attempt to split elements from the right side
    -- so that the sizes of both pages are roughly equal at the end
    -- however the second page may be larger than the first
    -- page.
    --
    -- There is no expectation on the number of elements that will be
    -- taken for the new page.  The first page may also need to
    -- be split additional times however this should not be the normal
    -- operation.
    assert(self:should_split(), "Page cannot be split")

    local moved_elements = {}
    local moved_elements_size = 0
    local remaining_elements_size = self:size()

    for i = #self.elements, 2, -1 do
        local element_size = self.elements[i]:size()

        -- If the total size of the moved elements is greater than that of
        -- the remaining elements then do not split any more elements
        if (moved_elements_size >= remaining_elements_size or
            moved_elements_size >= self.max_size) then
            break
        end

        -- Otherwise the element is safe to move.
        table.insert(moved_elements, 1, table.remove(self.elements, i))
        moved_elements_size = moved_elements_size + element_size
        remaining_elements_size = remaining_elements_size - element_size
    end

    return BTree.Page:new(self.max_size, moved_elements)
end

function BTree.Node:new(page)
    -- Nodes hold all the actual data in our BTree.  For this purpose,
    -- they are essentially just wrappers around the Page object
    local new_node = {page = page}
    setmetatable(new_node, self)
    self.__index = self
    return new_node
end

function BTree.Node:id()
    -- The node's id is the page's id
    return self.page:id()
end

function BTree.Node:should_split()
    -- nodes can only be split if their page can be split
    return self.page:should_split()
end

function BTree.Node:split()
    -- Splitting a node just means returning the split page wrapped
    -- in a new node.  Again this node may need to be split itself
    return BTree.Node:new(self.page:split())
end

function BTree.Node:visit()
    -- Provide an iterator to visit all of the elements encapsulated in this node's page
    return coroutine.wrap(function()
        for element in self.page:iterate() do
            coroutine.yield(element)
        end
    end)
end

function BTree.Node.size()
    -- Nodes are always just their reference.
    return 8
end

return BTree
