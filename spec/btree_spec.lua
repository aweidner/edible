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

    it("Should be able to iterate over every value", function()
        local tree = BTree:new(256)
        for i = 1, 50 do
            tree:insert(Row:new(i, {Cell:new(i)}))
        end

        local expected_value = 1
        for value in tree:iterate() do
            assert.equal(value:get(1).data, expected_value)
            expected_value = expected_value + 1
        end
    end)

    it("Should be able to deal with random insertions and hold order", function()
        local tree = BTree:new(256)
        local indexes = {}

        -- Generate 100 unique indexes for rows
        for i = 1, 100 do
            table.insert(indexes, i)
        end

        -- Shuffle them
        for i = #indexes, 1, -1 do
            local j = math.random(1, #indexes)
            local temp = indexes[i]
            indexes[i] = indexes[j]
            indexes[j] = temp
        end

        -- Insert them
        for i = 1, #indexes do
            tree:insert(Row:new(indexes[i], {Cell:new(i)}))
        end

        -- Assert that the ids should be in sorted order
        -- when we iterate over them
        local previous_value = 0
        for value in tree:iterate() do
            assert.equal(previous_value < value:id(), true)
            previous_value = value:id()
        end

    end)

    it("Should be able to store unicode strings along with integers", function()
        local tree = BTree:new(256)

        tree:insert(Row:new(1, {Cell:new(34), Cell:new("Some string  ओ औ ")}))
        tree:insert(Row:new(2, {Cell:new(34), Cell:new("Some string  ओ औ ")}))
        tree:insert(Row:new(3, {Cell:new(34), Cell:new("Some string  ओ औ ")}))
        tree:insert(Row:new(4, {Cell:new(34), Cell:new("Some string  ओ औ ")}))
        tree:insert(Row:new(5, {Cell:new(34), Cell:new("Some string  ओ औ ")}))

        assert.equal(tree:select(3):get(2).data, "Some string  ओ औ ")
    end)

    it("Should work with non-integer row ids", function()
        local tree = BTree:new(256)

        tree:insert(Row:new("c", {Cell:new(34), Cell:new("Third entry")}))
        tree:insert(Row:new("b", {Cell:new(34), Cell:new("Second entry")}))
        tree:insert(Row:new("a", {Cell:new(34), Cell:new("First entry")}))
        tree:insert(Row:new("d", {Cell:new(34), Cell:new("Fourth entry")}))
        tree:insert(Row:new("e", {Cell:new(34), Cell:new("Fifth entry")}))

        local expected_row_ids = {"a", "b", "c", "d", "e"}

        local index = 1
        for value in tree:iterate() do
            assert.equal(value._id, expected_row_ids[index])
            index = index + 1
        end
    end)

    it("Should work with composite row ids", function()
        local tree = BTree:new(256)

        tree:insert(Row:new({1, 2}, {Cell:new(3), Cell:new("Third entry")}))
        tree:insert(Row:new({0, 1}, {Cell:new(2), Cell:new("Second entry")}))
        tree:insert(Row:new({0, 0}, {Cell:new(1), Cell:new("First entry")}))
        tree:insert(Row:new({1, 3}, {Cell:new(4), Cell:new("Fourth entry")}))
        tree:insert(Row:new({3, 4}, {Cell:new(5), Cell:new("Fifth entry")}))

        local expected_data = {1, 2, 3, 4, 5}

        local index = 1
        for value in tree:iterate() do
            assert.equal(value:get(1).data, expected_data[index])
            index = index + 1
        end
    end)

    it("Should work with composite heterogeneous duplicate row ids", function()
        local tree = BTree:new(256)

        tree:insert(Row:new({"a", "z", 3}, {Cell:new(5), Cell:new("Fifth entry")}))
        tree:insert(Row:new({"a", "b", 3}, {Cell:new(3), Cell:new("Third entry")}))
        tree:insert(Row:new({"a", "b", 3}, {Cell:new(2), Cell:new("Second entry")}))
        tree:insert(Row:new({"a", "b", 25}, {Cell:new(1), Cell:new("First entry")}))
        tree:insert(Row:new({"a", "b", 26}, {Cell:new(4), Cell:new("Fourth entry")}))

        local expected_data = {2, 3, 1, 4, 5}

        local index = 1
        for value in tree:iterate() do
            assert.equal(value:get(1).data, expected_data[index])
            index = index + 1
        end
    end)

    it("Should allow get to work with non integer composite keys", function()
        local tree = BTree:new(256)
        tree:insert(Row:new({"a", "b"}, {Cell:new(2), Cell:new("Second entry")}))
        assert.equals(tree:select({"a", "b"}):get(1).data, 2)
    end)
end)

describe("B+Tree Characteristics", function()
    it("Should be able to hold the pointer to the head", function()
        local tree = BTree:new(256)

        tree:insert(Row:new(1, {Cell:new(1)}))
        assert.equals(tree.head:get(1):get(1).data, 1)
    end)

    it("Should be able to hold the pointer to the head after some splits", function()
        local tree = BTree:new(24)

        tree:insert(Row:new(0, {Cell:new(0)}))
        tree:insert(Row:new(-1, {Cell:new(-1)}))
        tree:insert(Row:new(1, {Cell:new(1)}))
        tree:insert(Row:new(-3, {Cell:new(-3)}))
        tree:insert(Row:new(-2, {Cell:new(-2)}))
        tree:insert(Row:new(2, {Cell:new(2)}))

        -- Row id is -3 and we want the first cell in -3
        assert.equals(tree.head:get(-3):get(1).data, -3)
    end)
end)
