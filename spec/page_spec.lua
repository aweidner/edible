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

        assert.has.errors(function() page:get_row(27) end)
    end)

    it("Should allow checking if a certain id exists in a row", function()
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
        assert.equal(page:check_row(27), false)
        assert.equal(page:check_row(1), true)
    end)

    it("Should have a max size", function()
        assert.equal(Page:new(20, {}).max_size, 20)
    end)

    it("Should indicate when it needs to be split based on the size of its rows", function()
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

        assert.equal(page:should_split(), true)
    end)

    it("Should not say it needs to be split when the contents are not over the max size", function()
        assert.equal(Page:new(40, {}):should_split(), false)
    end)

    it("Should accept new rows that can be added to it", function()
        local page = Page:new(40, {})
        page:add_row(Row:new(1, {}))

        assert.equal(page:get_row(1).id, 1)
    end)

    it("Should not indicate it can be split if it only has one row", function()
        assert.equal(Page:new(4, {
            Row:new(1, NilCell)
        }):should_split(), false)
    end)

    it("Should have an id which is the greatest row id", function()
        local page = Page:new(40, {})
        page:add_row(Row:new(1, {}))
        assert.equal(page:id(), 1)

        page:add_row(Row:new(3, {}))
        assert.equal(page:id(), 3)
    end)

    it("Should split itself into evenly sized pages based on row size", function()
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

        local second_page = page:split()

        assert.equal(page:check_row(1), true)
        assert.equal(page:check_row(2), false)
        assert.equal(second_page:check_row(2), true)
    end)

    it("Should try to split as evenly as possible even when the row sizes are skewed", function()
        local page = Page:new(60, {
            Row:new(1, {
                NilCell,
                NilCell,
                NilCell,
                NilCell,
                NilCell,
                NilCell,
                NilCell,
                NilCell,
                NilCell,
                NilCell,
                NilCell
            }),
            Row:new(2, {
                NilCell,
            }),
            Row:new(3, {
                NilCell,
            }),
            Row:new(4, {
                NilCell,
            })
        })

        local second_page = page:split()

        assert.equal(second_page:check_row(2), true)
        assert.equal(second_page:check_row(3), true)
        assert.equal(second_page:check_row(4), true)
    end)

    it("The split page should be no larger than the max size allowed", function()
        local page = Page:new(10, {
            Row:new(1, {
                NilCell,
            }),
            Row:new(2, {
                NilCell,
            }),
            Row:new(3, {
                NilCell,
            }),
            Row:new(4, {
                NilCell,
            })
        })

        local second_page = page:split()

        assert.equal(second_page:check_row(4), true)
        assert.equal(second_page:check_row(3), false)
    end)

    it("There will always be at least one element split even when the size constraint would be violated", function()
        local page = Page:new(1, {
            Row:new(1, {
                NilCell,
            }),
            Row:new(2, {
                NilCell,
            }),
        })

        local second_page = page:split()

        assert.equal(second_page:check_row(2), true)
    end)

    it("Will have the correct page ids after a split", function()
        local page = Page:new(20, {
            Row:new(1, {
                NilCell,
            }),
            Row:new(2, {
                NilCell,
            }),
            Row:new(3, {
                NilCell,
            }),
            Row:new(4, {
                NilCell,
            })
        })

        local second_page = page:split()

        assert.equal(page:id(), 2)
        assert.equal(second_page:id(), 4)
    end)
end)
