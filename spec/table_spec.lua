-- Don't accidentally shadow table from the lua standard lib
local Table = require("src/table").Table
local lib = require("lib")

local function make_from(original_columns, original_values)
    -- Produce an insert structure from the contents
    local columns = {}
    local values = {}

    for _, v in pairs(original_columns) do
        table.insert(columns, {name = v})
    end

    for _, v in pairs(original_values) do
        table.insert(values, {value = v})
    end

    return {
        values = values,
        columns = columns
    }
end

describe("Table", function()
    it("Should be able to create a BTree with the appropriate table information", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        created_table:insert(make_from({"test", "test2"}, {"hello", 34}))
        local row = created_table:get(1)

        assert.equals(row.test, "hello")
        assert.equals(row.test2, 34)
    end)

    it("Should keep the row id when inserting into the table", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)
        created_table:insert(make_from({"test", "test2"}, {"hello1", 34}))
        created_table:insert(make_from({"test", "test2"}, {"hello2", 34}))
        created_table:insert(make_from({"test", "test2"}, {"hello3", 34}))
        created_table:insert(make_from({"test", "test2"}, {"hello4", 34}))

        local row = created_table:get(3)

        assert.equals(row.test, "hello3")
    end)

    it("Should raise an error when the insert contents don't match the structure", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        assert.has.error(function() created_table:insert(make_from({"test", "test2", "test3"}, {"hello", 34, "hello"})) end)
        assert.has.error(function() created_table:insert(make_from({"test", "test2"}, {"hello", "34"})) end)
    end)

    it("Should allow nils", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        -- Implicit assertion for allowed nils here
        created_table:insert(make_from({"test", "test2"}, {lib.NIL, lib.NIL}))
    end)

    it("Should raise an error if table name is not defined", function()
        local table_structure = {
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }

        assert.has.error(function() Table:new(table_structure) end)
    end)

    it("Should raise an error if columns are not defined", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string"},
                {type = "number", name = "test2"}
            }
        }

        assert.has.error(function() Table:new(table_structure) end)
    end)

    it("Should return nil if the value could not be found in the table", function()
        local table_structure = {
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }

        local created_table = Table:new(table_structure)

        created_table:insert(make_from({"test", "test2"}, {"hello1", 34}))
        assert.equals(created_table:get(3), nil)
    end)
end)
