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
        local edible = Edible:new()
        edible:execute("CREATE TABLE test (column_a string)")
        edible:execute("CREATE TABLE test2 (column_b string)")
        edible:execute("CREATE TABLE test3 (column_c string)")
        edible:execute("CREATE TABLE test4 (column_d string)")
        edible:execute("CREATE TABLE test5 (column_e string, column_f string, column_g string)")

        edible:execute("INSERT INTO test (column_a) VALUES ('1')")
        edible:execute("INSERT INTO test (column_a) VALUES ('2')")
        edible:execute("INSERT INTO test (column_a) VALUES ('3')")
        edible:execute("INSERT INTO test (column_a) VALUES ('4')")
        edible:execute("INSERT INTO test (column_a) VALUES ('5')")

        edible:execute("INSERT INTO test2 (column_b) VALUES ('1')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('2')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('3')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('4')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('5')")

        edible:execute("INSERT INTO test3 (column_c) VALUES ('1')")
        edible:execute("INSERT INTO test3 (column_c) VALUES ('2')")
        edible:execute("INSERT INTO test3 (column_c) VALUES ('3')")
        edible:execute("INSERT INTO test3 (column_c) VALUES ('4')")
        edible:execute("INSERT INTO test3 (column_c) VALUES ('5')")

        edible:execute("INSERT INTO test4 (column_d) VALUES ('1')")
        edible:execute("INSERT INTO test4 (column_d) VALUES ('2')")
        edible:execute("INSERT INTO test4 (column_d) VALUES ('3')")
        edible:execute("INSERT INTO test4 (column_d) VALUES ('4')")
        edible:execute("INSERT INTO test4 (column_d) VALUES ('5')")

        edible:execute("INSERT INTO test5 (column_e, column_f, column_g) VALUES ('1', 'a', 'b')")
        edible:execute("INSERT INTO test5 (column_e, column_f, column_g) VALUES ('2', 'a', 'b')")
        edible:execute("INSERT INTO test5 (column_e, column_f, column_g) VALUES ('3', 'a', 'b')")
        edible:execute("INSERT INTO test5 (column_e, column_f, column_g) VALUES ('4', 'a', 'b')")
        edible:execute("INSERT INTO test5 (column_e, column_f, column_g) VALUES ('5', 'a', 'b')")

        local cursor = edible:execute(
            "SELECT * FROM test JOIN test2 ON test.column_a == test2.column_b " ..
            "JOIN test3 ON test2.column_b == test3.column_c " ..
            "JOIN test4 ON test3.column_c == test4.column_d " ..
            "JOIN test5 ON test4.column_d == test5.column_e")

        local result = {}
        for item in cursor do
            table.insert(result, item)
        end

        assert.equals(#result, 5)

        for index, value in ipairs(result) do
            assert.equals(value.column_a, tostring(index))
            assert.equals(value.column_b, tostring(index))
            assert.equals(value.column_c, tostring(index))
            assert.equals(value.column_d, tostring(index))
            assert.equals(value.column_e, tostring(index))
            assert.equals(value.column_f, "a")
            assert.equals(value.column_g, "b")
        end

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

    it("Should show positive result for joining two tables with condition", function()
        local edible = Edible:new()
        edible:execute("CREATE TABLE test (column_a string)")
        edible:execute("CREATE TABLE test2 (column_b string)")

        edible:execute("INSERT INTO test (column_a) VALUES ('1')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('1')")
        edible:execute("INSERT INTO test (column_a) VALUES ('2')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('2')")
        edible:execute("INSERT INTO test (column_a) VALUES ('3')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('3')")
        edible:execute("INSERT INTO test (column_a) VALUES ('4')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('4')")
        edible:execute("INSERT INTO test (column_a) VALUES ('5')")
        edible:execute("INSERT INTO test2 (column_b) VALUES ('5')")

        local cursor = edible:execute(
            "SELECT * FROM test " ..
            "JOIN test2 ON test.column_a == test2.column_b " ..
            "WHERE test2.column_b == '3'")

        local result = {}
        for item in cursor do
            table.insert(result, item)
        end

        -- The one result is when both values are 3
        assert.equals(#result, 1)
    end)

    it("Should be able to work with numbers", function()
        local edible = Edible:new()
        edible:execute("CREATE TABLE test (column_a number)")
        edible:execute("CREATE TABLE test2 (column_b number)")

        edible:execute("INSERT INTO test (column_a) VALUES (1)")
        edible:execute("INSERT INTO test2 (column_b) VALUES (1)")
        edible:execute("INSERT INTO test (column_a) VALUES (2)")
        edible:execute("INSERT INTO test2 (column_b) VALUES (2)")
        edible:execute("INSERT INTO test (column_a) VALUES (3)")
        edible:execute("INSERT INTO test2 (column_b) VALUES (3)")
        edible:execute("INSERT INTO test (column_a) VALUES (4)")
        edible:execute("INSERT INTO test2 (column_b) VALUES (4)")
        edible:execute("INSERT INTO test (column_a) VALUES (5)")
        edible:execute("INSERT INTO test2 (column_b) VALUES (5)")

        local cursor = edible:execute(
            "SELECT * FROM test " ..
            "JOIN test2 ON test.column_a == test2.column_b " ..
            "WHERE test2.column_b >= 3")

        local result = {}
        for item in cursor do
            table.insert(result, item)
        end

        -- We should take entries 3, 4, and 5
        assert.equals(#result, 3)
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
