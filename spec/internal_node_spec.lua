-- These are test cases to make sure that
-- a page of nodes (basically what an internal node
-- wraps) can function correctly

local Page = require('btree').Page
local NodePage = require('btree').NodePage
local Row = require('btree').Row
local NilCell = require('btree').NilCell
local Node = require('btree').Node

describe("Internal Node", function()

    it("Page should be able to store instances of nodes", function()
        local page = NodePage:new(20, {
            Node:new(
                Page:new(20, {
                    Row:new(1, {NilCell, NilCell}),
                    Row:new(2, {NilCell, NilCell})
                })
            )
        })

        assert.equal(page:size(), 16)
    end)

    it("Should be able to get a node by id", function()
        local page = NodePage:new(1000, {
            Node:new(
                Page:new(20, {
                    Row:new(1, {NilCell, NilCell}),
                    Row:new(2, {NilCell, NilCell})
                })
            ),
            Node:new(
                Page:new(20, {
                    Row:new(3, {NilCell, NilCell}),
                    Row:new(4, {NilCell, NilCell})
                })
            ),
            Node:new(
                Page:new(20, {
                    Row:new(5, {NilCell, NilCell}),
                    Row:new(6, {NilCell, NilCell})
                })
            ),
            Node:new(
                Page:new(20, {
                    Row:new(7, {NilCell, NilCell}),
                    Row:new(8, {NilCell, NilCell})
                })
            )
        })

        assert.equal(page:get(2):id(), 2)
    end)

    it("Should iterate through a page of nodes", function()
        local page = NodePage:new(1000, {
            Node:new(
                Page:new(20, {
                    Row:new(1, {NilCell, NilCell}),
                    Row:new(2, {NilCell, NilCell})
                })
            ),
            Node:new(
                Page:new(20, {
                    Row:new(3, {NilCell, NilCell}),
                    Row:new(4, {NilCell, NilCell})
                })
            ),
        })

        -- The reason this is multiplied by two is because each
        -- node contains a page with two rows.  The id of
        -- the first node should therefore be two and the id
        -- of the second should be four
        local index = 1
        for node in page:iterate() do
            assert.equal(node:id(), index * 2)
            index = index + 1
        end
    end)

    it("Should have the correct id", function()
        local page = NodePage:new(1000, {
            Node:new(
                Page:new(20, {
                    Row:new(1, {NilCell, NilCell}),
                    Row:new(2, {NilCell, NilCell})
                })
            )
        })

        assert.equals(page:id(), 2)
    end)

    it("Should be able to get a row by id at multiple levels", function()
        local page = NodePage:new(1000, {
            Node:new(
                Page:new(20, {
                    Row:new(1, {NilCell, NilCell}),
                    Row:new(2, {NilCell, NilCell})
                })
            ),
            Node:new(
                Page:new(20, {
                    Row:new(3, {NilCell, NilCell}),
                    Row:new(4, {NilCell, NilCell})
                })
            ),
        })

        assert.equals(page:get(3):id(), 3)
        assert.has.error(function() page:get(10):id() end)
    end)

    it("Should be able to get a node by id at the end of a list", function()
        local page = NodePage:new(1000, {
            Node:new(
                Page:new(20, {
                    Row:new(1, {NilCell, NilCell}),
                    Row:new(2, {NilCell, NilCell})
                })
            ),
            Node:new(
                Page:new(20, {
                    Row:new(3, {NilCell, NilCell}),
                    Row:new(4, {NilCell, NilCell})
                })
            ),
            Node:new(
                Page:new(20, {
                    Row:new(5, {NilCell, NilCell}),
                    Row:new(6, {NilCell, NilCell})
                })
            ),
            Node:new(
                Page:new(20, {
                    Row:new(7, {NilCell, NilCell}),
                    Row:new(8, {NilCell, NilCell})
                })
            )
        })

        assert.equal(page:get(8):id(), 8)
        assert.equal(page:get(7):id(), 7)
    end)

    it("Should be able to tell when to split the page", function()
        local page = NodePage:new(24)
        assert.equals(page:size(), 8)

        -- Now we are going to add one Node with a Page to it

        page:add(Row:new(1, {NilCell}))
        assert.equals(page:size(), 16)
        assert.equals(page:should_split(), false)

        -- The page does not yet need to be split.  We add another node
        page:add(Row:new(2, {NilCell}))
        assert.equals(page:size(), 24)
        assert.equals(page:should_split(), false)

        -- Now the page itself needs to be split
        page:add(Row:new(3, {NilCell}))
        assert.equals(page:size(), 32)
        assert.equals(page:should_split(), true)
    end)
end)
