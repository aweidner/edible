local BTree = require("btree").BTree
local Row = require("btree").Row

describe("BTree", function()
    it("Should be able to get and retrieve a value", function()

        local tree = BTree:new(20)
        tree:insert(Row:new(1, {10, 10}))
        tree:insert(Row:new(2, {10, 10}))
        tree:insert(Row:new(3, {30, 30}))
        tree:insert(Row:new(4, {40, 40}))

        assert.equal(tree:select(1):id(), 1)
        assert.equal(tree:select(2):id(), 2)
        assert.equal(tree:select(3):id(), 3)
        assert.equal(tree:select(4):id(), 4)
    end)
end)
