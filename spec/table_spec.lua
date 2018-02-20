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

        local table = Table:new(table_structure)

        table:insert({"hello", 34})
        local row = table:get(1)

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

        local table = Table:new(table_structure)

        table:insert({"hello1", 34})
        table:insert({"hello2", 34})
        table:insert({"hello3", 34})
        table:insert({"hello4", 34})

        local row = table:get(3)

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

        local table = Table:new(table_structure)

        assert.has.error(function() table:insert({"hello", 34, "hello"}) end)
        assert.has.error(function() table:insert({56, 34}) end)
    end)

    it("Should allow nils", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "int", name = "test2"}
            }
        }

        local table = Table:new(table_structure)

        -- Implicit assertion for allowed nils here
        table:insert({lib.NIL, lib.NIL})
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

        local table = Table:new(table_structure)

        table:insert({"hello1", 34})
        assert.equals(table:get(3), nil)
    end)
end)
