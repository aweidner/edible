-- Don't accidentally shadow table from the lua standard lib
local Table = require("src/table").Table
local lib = require("lib")

describe("Table", function()
    it("Should be able to create a BTree with the appropriate table information", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "int", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        created_table:insert({"hello", 34})
        local row = created_table:get(1)

        assert.equals(row.test, "hello")
        assert.equals(row.test2, 34)
    end)

    it("Should keep the row id when inserting into the table", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "int", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        created_table:insert({"hello1", 34})
        created_table:insert({"hello2", 34})
        created_table:insert({"hello3", 34})
        created_table:insert({"hello4", 34})

        local row = created_table:get(3)

        assert.equals(row.test, "hello3")
    end)

    it("Should raise an error when the insert contents don't match the structure", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "int", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        assert.has.error(function() created_table:insert({"hello", 34, "hello"}) end)
        assert.has.error(function() created_table:insert({56, 34}) end)
    end)

    it("Should allow nils", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "int", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        -- Implicit assertion for allowed nils here
        created_table:insert({lib.NIL, lib.NIL})
    end)

    it("Should raise an error if table name is not defined", function()
        local table_structure = {
            columns = {
                {type = "string", name = "test"},
                {type = "int", name = "test2"}
            }
        }

        assert.has.error(function() Table:new(table_structure) end)
    end)

    it("Should raise an error if columns are not defined", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string"},
                {type = "int", name = "test2"}
            }
        }

        assert.has.error(function() Table:new(table_structure) end)
    end)

    it("Should return nil if the value could not be found in the table", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "int", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        created_table:insert({"hello1", 34})
        assert.equals(created_table:get(3), nil)
    end)

    it("Should support running the select structure", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "int", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        created_table:insert({"hello1", 34})
        created_table:insert({"hello2", 5})

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
    end)

    it("Should raise an error if one of the columns does not exist in this table", function()
    end)

    it("Should raise an error if the condition cannot be parsed in lua", function()
    end)

    it("Should be able to work with NULL in a select condition", function()
    end)
end)
