describe("select", function()
    it("Should support running the select structure", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        created_table:insert(make_from({"test", "test2"}, {"hello1", 34}))
        created_table:insert(make_from({"test", "test2"}, {"hello2", 5}))

        local cursor = created_table:find({
            columns = {
                {name = "test"},
            },
            condition = "test2 > 5"
        })

        local result = {}
        for item in cursor do
            table.insert(result, item)
        end

        assert.equals(#result, 1)
        assert.equals(result[1].test, "hello1")
        assert.equals(result[1].test2, nil)
    end)

    it("Should raise an error if one of the FQN columns does not come from this table", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }

        assert.has.error(function() Table:new(table_structure):find({
            columns = {{table_name = "table34", name = "test"}}
        }) end)
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
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        assert.has.error(function()
            local cursor = created_table:find({
                columns = {{name = "test"}},
                condition = "test2 > 5"
            })
            -- Have to consume the iterator
            for _ in cursor do  end
        end)
    end)

    it("Should be able to work with NULL in a select condition", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "NULL34"},
                {type = "number", name = "SOME_OTHER_NULL"}
            }
        }

        local created_table = Table:new(table_structure)
        created_table:insert(make_from({"NULL34", "SOME_OTHER_NULL"}, {"hello1", 34}))

        local cursor = created_table:find({
            columns = {{name = "SOME_OTHER_NULL"}},
            condition = "NULL34 ~= nil"
        })

        for item in cursor do
            assert.equals(item.SOME_OTHER_NULL, 34)
        end
    end)

    it("Should work with nil condition", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "NULL34"},
                {type = "number", name = "SOME_OTHER_NULL"}
            }
        }

        local created_table = Table:new(table_structure)
        created_table:insert(make_from({"NULL34", "SOME_OTHER_NULL"}, {"hello1", 34}))

        local cursor = created_table:find({
            columns = {{name = "SOME_OTHER_NULL"}},
        })

        for item in cursor do
            assert.equals(item.SOME_OTHER_NULL, 34)
        end
    end)

    it("Should work with nil columns", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "NULL34"},
                {type = "number", name = "SOME_OTHER_NULL"}
            }
        }

        local created_table = Table:new(table_structure)
        created_table:insert(make_from({"NULL34", "SOME_OTHER_NULL"}, {"hello1", 34}))

        local cursor = created_table:find({
            columns = {{name = "SOME_OTHER_NULL"}},
        })

        for item in cursor do
            assert.equals(item.SOME_OTHER_NULL, 34)
        end
    end)

    it("Should insert values in the correct order", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "NULL34"},
                {type = "number", name = "SOME_OTHER_NULL"}
            }
        }

        local created_table = Table:new(table_structure)
        created_table:insert(make_from({"SOME_OTHER_NULL", "NULL34"}, {34, "hello1"}))

        local cursor = created_table:find({
            columns = {{name = "SOME_OTHER_NULL"}},
        })

        for item in cursor do
            assert.equals(item.SOME_OTHER_NULL, 34)
        end
    end)

    it("Should fill in nil for any values that are not specified", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "NULL34"},
                {type = "number", name = "SOME_OTHER_NULL"}
            }
        }

        local created_table = Table:new(table_structure)
        created_table:insert(make_from({"NULL34"}, {"hello1"}))

        local cursor = created_table:find({
            columns = {{name = "SOME_OTHER_NULL"}},
        })

        for item in cursor do
            assert.equals(item.SOME_OTHER_NULL, nil)
        end
    end)
end)
