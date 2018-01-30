local Page = require('btree').Page
local Row = require('btree').Row
local NilCell = require('btree').NilCell

describe("Page", function()
    it("Should have a set of rows stored in sorted order", function()
        local page = Page:new(20, {
            Row:new(1, {
                NilCell,
                NilCell
            }),
            Row:new(2, {
                NilCell,
                NilCell
            })
        })
        assert.equal(page:size(), 56)
    end)

    it("Should be able to traverse rows with an iterator", function()
        local page = Page:new(20, {
            Row:new(1, {
                NilCell,
                NilCell
            }),
            Row:new(2, {
                NilCell,
                NilCell
            })
        })

        for row in page:iterate_rows() do
            assert.equal(row:get(1).size, 8)
            assert.equal(row:get(2).size, 8)
        end
    end)

    it("Should show the rows in sorted order even if they are not originally sorted", function()
        local page = Page:new(20, {
            Row:new(2, {
                NilCell,
                NilCell
            }),
            Row:new(1, {
                NilCell,
                NilCell
            })
        })

        assert.equal(page.rows[1].id, 1)
        assert.equal(page.rows[2].id, 2)
    end)

    it("Should be able to get a row by id", function()
        local page = Page:new(20, {
            Row:new(2, {
                NilCell,
                NilCell
            }),
            Row:new(1, {
                NilCell,
                NilCell
            })
        })

        assert.equal(page:get_row(2).id, 2)
    end)

    it("If there is no row matching the id it should throw an exception", function()

    end)

    it("Should allow checking if a certain id exists in a row", function()

    end)

    it("Should have a max size", function()
    end)

    it("Should indicate when it needs to be split based on the size of its rows", function()
    end)

    it("Should split itself into evenly sized pages based on row size", function()
    end)

    it("Should not indicate it can be split if it only has one row", function()
    end)

    it("Should have an id which is the greatest row id", function()
    end)
end)
