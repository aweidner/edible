local update = require("parser").update

describe("Update parsing", function()
    it("Should be able to parse out the table name", function()
        assert.equal(update("UPDATE test SET a = 'b' WHERE a = 'c'").table_name, "test")
    end)

    it("Should be able to parse out the column names and values", function()
        local result = update("UPDATE test SET a='b', b=2 WHERE a='c'")

        assert.equals(result.updates[1].name, "a")
        assert.equals(result.updates[1].value, "b")
        assert.equals(result.updates[2].name, "b")
        assert.equals(result.updates[2].value, 2)
    end)

    it("Should be able to parse out the select condition", function()
        local result = update("UPDATE test SET a='b', b=2 WHERE a='c'")
        assert.equals(result.condition, "a='c'")
    end)

    it("Should be able to take an optional condition", function()
        local result = update("UPDATE test SET a='b', b=2")
        assert.equals(result.success, true)
        assert.equals(result.condition, nil)
    end)
end)
