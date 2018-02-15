local match_pattern = require("parser").match_pattern

describe("Match Pattern", function()
    it("Should be able to parse the text create table", function()
        local result = match_pattern("CREATE TABLE", "CREATE TABLE")
        assert.equals(result.success, true)
        assert.equals(result.rem, "")
    end)

    it("Should be able to parse it with remaining characters", function()
        local result = match_pattern("CREATE TABLE something else", "CREATE TABLE")
        assert.equals(result.success, true)
        assert.equals(result.rem, " something else")
    end)

    it("Should be able to match multiple based on a lua character match", function()
        local result = match_pattern("abcdefg hello", "[^ ]*")
        assert.equals(result.success, true)
        assert.equals(result.rem, " hello")
    end)
end)
