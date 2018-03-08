local lib = require("lib")

describe("Less than", function()

    it("Can work with numbers", function()
        assert.equal(lib.lt(1, 2), true)
        assert.equal(lib.lt(2, 1), false)
        assert.equal(lib.lt(1, 1), false)
    end)

    it("Can work with strings", function()
        assert.equal(lib.lt("a", "b"), true)
        assert.equal(lib.lt("b", "a"), false)
        assert.equal(lib.lt("a", "a"), false)
    end)

    it("Can work with tables", function()
        assert.equal(lib.lt({"a"}, {"b"}), true)
        assert.equal(lib.lt({"b"}, {"a"}), false)
        assert.equal(lib.lt({"a"}, {"a"}), false)
        assert.equal(lib.lt({"a", "b", "c"}, {"a", "z", "c"}), true)
    end)

    it("Compare tables of different lengths", function()
        assert.equal(lib.lt({}, {"b"}), true)
        assert.equal(lib.lt({}, {}), false)
        assert.equal(lib.lt({"b"}, {"a", "a"}), false)
        assert.equal(lib.lt({"a"}, {"a", "a"}), true)
    end)

    it("Will refuse to compare different types", function()
        assert.has.error(function() lib.lt({}, 5) end)
        assert.has.error(function() lib.lt("a", 5) end)
    end)

    it("Will refuse to compare tables that contain different types of data", function()
        assert.has.error(function() lib.lt({"a"}, {5}) end)
    end)

    it("Can work with math.huge and -math.huge", function()
        assert.equal(lib.lt({}, math.huge), true)
        assert.equal(lib.lt(math.huge, {}), false)
        assert.equal(lib.lt(-math.huge, {}), true)
        assert.equal(lib.lt({}, -math.huge), false)
    end)

    it("Works on table values when the second value is shorter than the first", function()
        assert.equal(lib.lt({"a", "a"}, {"a"}), false)
    end)
end)

describe("Greater than", function()
    it("Can work with numbers", function()
        assert.equal(lib.gt(1, 2), false)
        assert.equal(lib.gt(2, 1), true)
        assert.equal(lib.gt(1, 1), false)
    end)

    it("Can work with strings", function()
        assert.equal(lib.gt("a", "b"), false)
        assert.equal(lib.gt("b", "a"), true)
        assert.equal(lib.gt("a", "a"), false)
    end)

    it("Can work with tables", function()
        assert.equal(lib.gt({"a"}, {"b"}), false)
        assert.equal(lib.gt({"b"}, {"a"}), true)
        assert.equal(lib.gt({"a"}, {"a"}), false)
        assert.equal(lib.gt({"a", "b", "c"}, {"a", "z", "c"}), false)
    end)

    it("Compare tables of different lengths", function()
        assert.equal(lib.gt({}, {"b"}), false)
        assert.equal(lib.gt({}, {}), false)
        assert.equal(lib.gt({"b"}, {"a", "a"}), true)
        assert.equal(lib.gt({"a"}, {"a", "a"}), false)
    end)

    it("Will refuse to compare different types", function()
        assert.has.error(function() lib.gt({}, 5) end)
        assert.has.error(function() lib.gt("a", 5) end)
    end)

    it("Will refuse to compare tables that contain different types of data", function()
        assert.has.error(function() lib.gt({"a"}, {5}) end)
    end)

    it("Can work with math.huge and -math.huge", function()
        assert.equal(lib.gt({}, math.huge), false)
        assert.equal(lib.gt(math.huge, {}), true)
        assert.equal(lib.gt(-math.huge, {}), false)
        assert.equal(lib.gt({}, -math.huge), true)
    end)
end)

describe("Equal to", function()
    it("Can work with numbers", function()
        assert.equal(lib.eq(1, 2), false)
        assert.equal(lib.eq(2, 1), false)
        assert.equal(lib.eq(1, 1), true)
    end)

    it("Can work with strings", function()
        assert.equal(lib.eq("a", "b"), false)
        assert.equal(lib.eq("b", "a"), false)
        assert.equal(lib.eq("a", "a"), true)
    end)

    it("Can work with tables", function()
        assert.equal(lib.eq({"a"}, {"b"}), false)
        assert.equal(lib.eq({"b"}, {"a"}), false)
        assert.equal(lib.eq({"a"}, {"a"}), true)
        assert.equal(lib.eq({"a", "z", "c"}, {"a", "z", "c"}), true)
    end)

    it("Compare tables of different lengths", function()
        assert.equal(lib.eq({}, {"b"}), false)
        assert.equal(lib.eq({}, {}), true)
        assert.equal(lib.eq({"b"}, {"a", "a"}), false)
        assert.equal(lib.eq({"a"}, {"a", "a"}), false)
    end)

    it("Can work with math.huge and -math.huge", function()
        assert.equal(lib.eq({}, math.huge), false)
        assert.equal(lib.eq(math.huge, {}), false)
        assert.equal(lib.eq(-math.huge, {}), false)
        assert.equal(lib.eq({}, -math.huge), false)
    end)
end)
