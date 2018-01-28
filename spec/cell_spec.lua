local Cell = require('btree').Cell

describe("Cell", function()
    it("Should be able to store data of integer type", function()
        local cell = Cell:new(37)
        assert.equal(cell.data, 37)
    end)

    it("Should be able to store data of string (blob) type", function()
        local cell = Cell:new("hello world")
        assert.equal(cell.data, "hello world")
    end)

    it("Should be able to return the size in bytes of the object stored in the cell", function()
        -- The size of the cell must be the size of the data plus 8 bytes overhead to store the
        -- size of the number itself
        local cell = Cell:new(42)
        assert.equal(cell.size, 16)

        cell = Cell:new("Hello World")
        assert.equal(cell.size, 19)
    end)

    it("Should be able to get the appropriate size for unicode strings", function()
        local cell = Cell:new("΅ Ά · Έ Ή Ί Ό Ύ Ώ ΐ Α Β")

        -- Each greek character takes two code points plus 11 spaces should yield
        -- 24 bytes + 11 for the spaces == 35
        assert.equal(cell.size, 43)

        cell = Cell:new("∇∈")

        -- Each mathematical operator takes 3 bytes in utf-8
        assert.equal(cell.size, 14)
    end)
end)

