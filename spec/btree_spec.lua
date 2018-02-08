local BTree = require("btree").BTree
local Row = require("btree").Row
local Cell = require("btree").Cell

describe("BTree", function()
    it("Should be able to get and retrieve a value", function()

        local tree = BTree:new(1024)
        tree:insert(Row:new(1, {Cell:new(10), Cell:new(10)}))
        tree:insert(Row:new(2, {Cell:new(10), Cell:new(10)}))
        tree:insert(Row:new(3, {Cell:new(30), Cell:new(30)}))
        tree:insert(Row:new(4, {Cell:new(40), Cell:new(40)}))

        assert.equal(tree:select(1):id(), 1)
        assert.equal(tree:select(2):id(), 2)
        assert.equal(tree:select(3):id(), 3)
        assert.equal(tree:select(4):id(), 4)
    end)

    it("Should be split after the page size is exceeded", function()

        -- With this page size, the root is set up in such
        -- a way as to allow two elements per page
        local tree = BTree:new(24)

        tree:insert(Row:new(1, {Cell:new(1)}))
        tree:insert(Row:new(2, {Cell:new(2)}))


        -- At this point the tree looks like this
        --          *
        --         / \
        --        1   2
        assert.equal(tree.root.page.elements[1].page.elements[1]:id(), 1)
        assert.equal(tree.root.page.elements[2].page.elements[1]:id(), 2)

        -- Now we are inserting 3, making the tree look like this
        --          *
        --         /|\
        --        1 2 3
        tree:insert(Row:new(3, {Cell:new(3)}))

        -- Because of the page size, the resulting tree
        -- must look like:
        --
        --          *
        --        /   \
        --       *     *
        --      /     / \
        --     1     2   3

        --  This looks a little weird because of the balancing algorithm used
        --  where the split off pages can be potentially bigger than the original
        --  pages, but it works fine in practice
        assert.equal(tree.root.page.elements[1].page.elements[1].page.elements[1]:id(), 1)
        assert.equal(tree.root.page.elements[2].page.elements[1].page.elements[1]:id(), 2)
        assert.equal(tree.root.page.elements[2].page.elements[2].page.elements[1]:id(), 3)

        -- And I can still get to node 2 or 3
        assert.equal(tree:select(2):id(), 2)
        assert.equal(tree:select(3):id(), 3)


        -- If we add 4 then the table will become:
        --           *
        --         /   \
        --        *     *
        --       /     / \
        --      *     *   *
        --     /     /   / \
        --    1     2   3   4
        tree:insert(Row:new(4, {Cell:new(4)}))

        assert.equal(tree.root.page.elements[1]
                              .page.elements[1]
                              .page.elements[1]
                              .page.elements[1]:id(), 1)

        assert.equal(tree.root.page.elements[2]
                              .page.elements[1]
                              .page.elements[1]
                              .page.elements[1]:id(), 2)

        assert.equal(tree.root.page.elements[2]
                              .page.elements[2]
                              .page.elements[1]
                              .page.elements[1]:id(), 3)

        assert.equal(tree.root.page.elements[2]
                              .page.elements[2]
                              .page.elements[2]
                              .page.elements[1]:id(), 4)

    end)

    it("Should be able to accept and query a large amount of data after splitting", function()
        -- Should end up with a roughly evenly balanced tree that we can
        -- query through.  Multiple split operations will happen here, so this
        -- is sort of a final aggregation test to put it all together
        local tree = BTree:new(24)
        for i = 1, 100 do
            tree:insert(Row:new(i, {Cell:new(i)}))
        end

        for i = 1, 100 do
            assert.equal(tree:select(i):id(), i)
        end

    end)
end)
