local match_pattern = require("parser").match_pattern
local pattern = require("parser").pattern
local any_of = require("parser").any_of
local compose = require("parser").compose
local types = require("parser").types
local column_def = require("parser").column_def
local one_or_more_of = require("parser").one_or_more_of
local create_table = require("parser").create_table
local insert = require("parser").insert
local find = require("parser").find

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

describe("pattern", function()
    it("Should be able to match one pattern and give output", function()
        local result = pattern("[a-e]+")("abcdefgh")
        assert.equals(result.matched, "abcde")
        assert.equals(result.success, true)
    end)
end)

describe("any_of", function()
    it("Should be able to match any of a set of pattern matchers", function()
        local result = any_of({pattern("[a-e]"), pattern("[z]+")})("zzzz")
        assert.equals(result.matched, "zzzz")
    end)

    it("Should return false and the original text if it could not match", function()
        local result = any_of({pattern("[a-e]"), pattern("[z]+")})("yyyy")
        assert.equals(result.matched, "")
        assert.equals(result.rem, "yyyy")
    end)
end)

describe("compose", function()
    it("Should be able to combine multiple matchers", function()
        local result = compose({
            pattern("[a-e]+"), pattern("%s+"), pattern("zzz")})("aaa zzzbbbb")

        assert.equals(result.matched, "aaa zzz")
        assert.equals(result.rem, "bbbb")
    end)

    it("Should return as much as it could match", function()
        local result = compose({pattern("aaa"), pattern("zzz")})("aaa  zzz")
        assert.equals(result.rem, "  zzz")
        assert.equals(result.success, false)
    end)
end)

describe("types and column def", function()
    it("Should be able to parse a type", function()
        local result = types("int")
        assert.equals(result.type, "int")

        result = types("string")
        assert.equals(result.type, "string")

        result = types("does not exist")
        assert.equals(result.success, false)
    end)

    it("Should parse a column definition", function()
        local result = column_def("hello_world int")
        assert.equals(result.name, "hello_world")
        assert.equals(result.type, "int")

        result = column_def("hello_world nonsense_type")
        assert.equals(result.name, "hello_world")
        assert.equals(result.success, false)
    end)
end)

describe("one_or_more_of", function()
    it("Should match at least one", function()
        local result = one_or_more_of(column_def, pattern("%s*,%s*"))("hello_world int")
        assert.equals(result.parts[1].name, "hello_world")
        assert.equals(result.parts[1].type, "int")
    end)

    it("Should match one or more", function()
        local matcher = one_or_more_of(column_def, pattern("%s*,%s*"))
        local result = matcher("hello_world int , test string")

        assert.equals(result.parts[1].name, "hello_world")
        assert.equals(result.parts[1].type, "int")
        assert.equals(result.parts[2].name, "test")
        assert.equals(result.parts[2].type, "string")
    end)

    it("Should not match 0", function()
        local matcher = one_or_more_of(column_def, pattern("%s*,%s*"))
        local result = matcher("some garbage that doesn't, match")

        assert.equals(result.success, false)
    end)
end)

describe("Create table", function()
    it("Should be able to match a create table statement", function()
        local result = create_table("CREATE TABLE test (test string, test2 int)")

        assert.equals(result.table_name, "test")
        assert.equals(result.columns[1].name, "test")
        assert.equals(result.columns[1].type, "string")
        assert.equals(result.columns[2].name, "test2")
        assert.equals(result.columns[2].type, "int")
    end)
end)

describe("insert into", function()
    it("Should be able to get the list of columns and values to insert into", function()
        local result = insert("INSERT INTO test " ..
            "(test1, test2, test3, test4, test5) " ..
            "VALUES ('hello', 1, 34, NULL, 'ਡ ਢ ਣ ਤ ਥ ਦ ਧ')")

        assert.equals(result.table_name, "test")

        assert.equals(result.columns[1].name, "test1")
        assert.equals(result.columns[2].name, "test2")
        assert.equals(result.columns[3].name, "test3")
        assert.equals(result.columns[4].name, "test4")
        assert.equals(result.columns[5].name, "test5")

        assert.equals(result.values[1].value, "hello")
        assert.equals(result.values[2].value, 1)
        assert.equals(result.values[3].value, 34)
        assert.equals(result.values[4].value, nil)
        assert.equals(result.values[5].value, "ਡ ਢ ਣ ਤ ਥ ਦ ਧ")
    end)
end)

describe("select", function()
    it("Should be able to get the table name, list of columns, and condition", function() 
        local result = find(
            "SELECT a_table.test1, test2 FROM a_table WHERE test1 == 5 and test2 == 34")

        assert.equals(result.columns[1].name, "test1")
        assert.equals(result.columns[1].table_name, "a_table")

        assert.equals(result.columns[2].name, "test2")
        assert.equals(result.columns[2].table_name, nil)

        assert.equals(result.table_name, "a_table")

        assert.equals(result.condition, "test1 == 5 and test2 == 34")
    end)

    it("Should be able to support selecting all columns", function()
        local result = find(
            "SELECT * FROM a_table WHERE test1 == 5 and test2 == 34")
        assert.equals(result.columns, nil)
        assert.equals(result.table_name, "a_table")
    end)

    it("Should be able to take an optional where statement", function()
        local result = find("SELECT * FROM a_table")

        assert.equals(result.success, true)
        assert.equals(result.condition, nil)
        assert.equals(result.table_name, "a_table")
    end)
end)
