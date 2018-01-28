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

    it("Should throw an error if an invalid row id is provided", function()
        assert.has.errors(function() Row:new(-1) end)
        assert.has.errors(function() Row:new("not a number") end)
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

        assert.equal(row:size(), 43)
    end)
end)
