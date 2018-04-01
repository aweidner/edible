local Edible = require("edible")

describe("Join", function()
    it("Should be able to join two tables without condition", function()
        local edible = Edible:new()
        edible:execute("CREATE TABLE test (column_a string)")
        edible:execute("CREATE TABLE test2 (column_b string)")
        edible:execute("INSERT INTO test (column_a) VALUES ('1')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('1')")
        local cursor = edible:execute(
            "SELECT * FROM test JOIN test2 ON test.column_a == test2.column_b")

        local result = {}
        for item in cursor do
            table.insert(result, item)
        end

        assert.equals(#result, 1)
        assert.equals(result[1].column_a, "1")
        assert.equals(result[1].column_b, "1")
    end)

    it("Should work for a very complicated join", function()
    end)

    it("Should be able to join two tables with condition", function()
        local edible = Edible:new()
        edible:execute("CREATE TABLE test (column_a string)")
        edible:execute("CREATE TABLE test2 (column_b string)")
        edible:execute("INSERT INTO test (column_a) VALUES ('1')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('1')")
        local cursor = edible:execute(
            "SELECT * FROM test " ..
            "JOIN test2 ON test.column_a == test2.column_b " ..
            "WHERE test2.column_b == '3'")

        local result = {}
        for item in cursor do
            table.insert(result, item)
        end

        assert.equals(#result, 0)
    end)

    it("Should support inner join by default", function()
        local edible = Edible:new()
        edible:execute("CREATE TABLE test (column_a string)")
        edible:execute("CREATE TABLE test2 (column_b string)")
        edible:execute("INSERT INTO test (column_a) VALUES ('1')")
        edible:execute("INSERT INTO test (column_a) VALUES ('2')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('1')")
        local cursor = edible:execute(
            "SELECT * FROM test JOIN test2 ON test.column_a == test2.column_b")

        local result = {}
        for item in cursor do
            table.insert(result, item)
        end

        -- Because this is an inner join, only those results that match both
        -- sides of the join condition will show up in the result set
        assert.equals(#result, 1)
        assert.equals(result[1].column_a, "1")
        assert.equals(result[1].column_b, "1")
    end)

    it("Should still filter columns based on what is selected", function()
        local edible = Edible:new()
        edible:execute("CREATE TABLE test (column_a string)")
        edible:execute("CREATE TABLE test2 (column_b string)")
        edible:execute("INSERT INTO test (column_a) VALUES ('1')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('1')")
        local cursor = edible:execute(
            "SELECT test.column_a FROM test JOIN test2 ON test.column_a == test2.column_b")

        local result = {}
        for item in cursor do
            table.insert(result, item)
        end

        assert.equals(#result, 1)
        assert.equals(result[1].column_a, "1")
        assert.equals(result[1].column_b, nil)
    end)
end)
