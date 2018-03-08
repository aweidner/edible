local Row = require('btree').Row
local Cell = require('btree').Cell
local NilCell = require('btree').NilCell

describe("Row", function()
    it("Should accept a row id", function()
        assert(Row:new(1).id, 1)
    end)

    it("Should throw an error if no row id is provided", function()
        assert.has.errors(function() Row:new() end)
    end)

    it("Should accept an optional list of cells", function()
        local row = Row:new(1, {
            NilCell,
            Cell:new(3),
            Cell:new(47),
            Cell:new("Hello World")
        })

        assert.equal(row:get(1).data, nil)
        assert.equal(row:get(3).data, 47)
    end)

    it("Should be able to return the total size of all cells", function()
        local row = Row:new(1, {
            NilCell,
            Cell:new(3),
            Cell:new("Hello World")
        })

        assert.equal(row:size(), 51)
    end)

    it("Should get the appropriate size if the row id is composite", function()
        -- The cell size is 43 + 24 bits for the composite key size
        -- yields 67 bits
        local row = Row:new({1, 2, 3}, {
            NilCell,
            Cell:new(3),
            Cell:new("Hello World")
        })

        assert.equal(row:size(), 67)
    end)
end)
