local Edible = require("edible")

describe("select", function()
    it("Should support running the select structure", function()
        local edible = Edible:new()
        edible:create_table("CREATE TABLE test (test string, test2 number)")
        edible:insert("INSERT INTO test (test, test2) VALUES ('hello1', 34)")
        edible:insert("INSERT INTO test (test, test2) VALUES ('hello2', 5)")
        local cursor = edible:find("SELECT test.test FROM test WHERE test.test2 > 5")

        local result = {}
        for item in cursor do
            table.insert(result, item)
        end

        assert.equals(#result, 1)
        assert.equals(result[1].test, "hello1")
        assert.equals(result[1].test2, nil)
    end)

    it("Should raise an error if one of the FQN columns does not come from this table", function()
        local edible = Edible:new()
        edible:create_table("CREATE TABLE test (test string, test2 number)")
        assert.has.error(function() edible:find("SELECT table34.test FROM test") end)
    end)

    it("Should raise an error if one of the columns does not exist in this table", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }

        assert.has.error(function() Table:new(table_structure):find({
            columns = {{name = "test99"}}
        }) end)
    end)

    it("Should raise an error if the condition cannot be parsed in lua", function()
        local edible = Edible:new()
        edible:create_table("CREATE TABLE test (test string, test2 number)")
        edible:insert("INSERT INTO test (test, test2) VALUES ('hello1', 34)")
        edible:insert("INSERT INTO test (test, test2) VALUES ('hello2', 5)")

        assert.has.error(function()
            local cursor = edible:find("SELECT test.test FROM test WHERE test.test > 5")

            -- Have to consume the iterator
            for _ in cursor do  end
        end)
    end)

    it("Should be able to work with NULL in a select condition", function()
        local edible = Edible:new()
        edible:create_table("CREATE TABLE test (NULL34 string, SOME_OTHER_NULL number)")
        edible:insert("INSERT INTO test (NULL34, SOME_OTHER_NULL) VALUES ('hello1', 34)")
        local cursor = edible:find(
            "SELECT test.SOME_OTHER_NULL FROM test WHERE test.NULL34 ~= nil")

        for item in cursor do
            assert.equals(item.SOME_OTHER_NULL, 34)
        end
    end)

    it("Should work without condition", function()
        local edible = Edible:new()
        edible:create_table("CREATE TABLE test (NULL34 string, SOME_OTHER_NULL number)")
        edible:insert("INSERT INTO test (NULL34, SOME_OTHER_NULL) VALUES ('hello1', 34)")
        local cursor = edible:find(
            "SELECT test.SOME_OTHER_NULL FROM test")

        for item in cursor do
            assert.equals(item.SOME_OTHER_NULL, 34)
        end
    end)
end)
