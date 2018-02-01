local Page = require('btree').Page
local Row = require('btree').Row
local NilCell = require('btree').NilCell
local LeafNode = require('btree').LeafNode

describe("Internal Node", function()

    it("Page should be able to store instances of leaf nodes", function()
        local page = Page:new(20, {
            LeafNode:new(
                Page:new(20, {
                    Row:new(1, {NilCell, NilCell}),
                    Row:new(2, {NilCell, NilCell})
                })
            )
        })

        assert.equal(page:size(), 16)

        page:add(LeafNode:new(
            Page:new(20, {
                Row:new(1, {NilCell, NilCell}),
                Row:new(2, {NilCell, NilCell})
            })
        ))

        assert.equal(page:size(), 24)
    end)

    it("Should allow adding new leaf nodes", function()
    end)

    it("Should get the correct id of a page of leaf nodes", function()
    end)

    it("Should iterate through a page of leaf nodes", function()
    end)

    it("Should be able to get a certain leaf node by id", function()
    end)

    it("Should split a page of leaf nodes correctly", function()
    end)

    it("Should implement should split on a page of leaf nodes correctly", function()
    end)

    it("Should be able to get a row by id", function()
        -- Requires navigating through an internal tree structure
        -- to get a row by id
    end)

    it("Should be able to iterate over all of it's rows", function()
    end)

    it("Should be able to split itself when it grows too large", function()
    end)

end)
