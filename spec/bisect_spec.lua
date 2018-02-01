local bisect = require("lib").bisect

describe("Bisect", function()
    it("Should find the location to insert an element when elements are all equal", function()
        assert.equal(bisect({17, 17, 17, 17}, 17), 3)
    end)

    it("Should find the location to insert an element when elements are very close", function()
        assert.equal(bisect({17, 18, 19, 20}, 18), 3)
    end)

    it("Should find the location to insert an element in an empty list", function()
        assert.equal(bisect({}, 18), 1)
    end)

    it("Should find the location to insert an element in a differing list", function()
        assert.equal(bisect({1, 17, 34, 99, 134, 167, 256, 389, 436}, 18), 3)
        assert.equal(bisect({1, 17, 34, 99, 134, 167, 256, 389, 436}, 300), 8)
    end)

    it("Should find the insert location for a one element list", function()
        assert.equal(bisect({1}, -1), 1)
        assert.equal(bisect({1}, 3), 2)
    end)

    it("Should be able to insert a value at the start of a list", function()
        assert.equal(bisect({1, 17, 34, 99, 134, 167, 256, 389, 436}, -10), 1)
    end)

    it("Should be able to insert a value at the end of a list", function()
        assert.equal(bisect({1, 17, 34, 99, 134, 167, 256, 389, 436}, 500), 10)
    end)
end)
