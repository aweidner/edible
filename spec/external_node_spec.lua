local Page = require('btree').Page
local Row = require('btree').Row
local NilCell = require('btree').NilCell
local LeafNode = require('btree').LeafNode

describe("Leaf Node", function()
    it("Has an id which corresponds to the page id", function()
        local node = LeafNode:new(Page:new(20, {Row:new(1, {NilCell})}))
        assert.equal(node:id(), 1)
    end)

    it("Knows when it needs to be split based on the page split algorithm", function()
        local node = LeafNode:new(Page:new(4, {
            Row:new(1, {NilCell}),
            Row:new(2, {NilCell})
        }))

        assert.equal(node:should_split(), true)
    end)

    it("Should allow itself to be split into two leaf nodes", function()
        local node = LeafNode:new(Page:new(4, {
            Row:new(1, {NilCell}),
            Row:new(2, {NilCell})
        }))

        local node_two = node:split()
        assert.equal(node:id(), 1)
        assert.equal(node_two:id(), 2)
    end)


    it("Should be visitable which returns an iterator for rows", function()
        -- We define some invalid row semantics here but it's fine since this
        -- is just for testing
        local node = LeafNode:new(Page:new(4, {
            Row:new(1, {NilCell}),
            Row:new(1, {NilCell})
        }))

        for row in node:visit() do
            assert.equal(row.id, 1)
        end
    end)
end)
