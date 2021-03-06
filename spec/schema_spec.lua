local Schema = require("src/schema")

describe("Schema", function()

    it("Should be able to be created from create table statement", function()
        local schema = Schema.from_create_table({
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        })

        assert.equals(schema:length(), 2)
    end)

    it("Should be able to get the index of a column based on FQN", function()
        local schema = Schema.from_create_table({
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        })

        assert.equals(schema:by_fqn("test.test2").index, 2)
        assert.equals(schema:by_fqn("test.test").index, 1)
    end)

    it("Should be able to get the FQN of a column by index", function()
        local schema = Schema.from_create_table({
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        })

        assert.equals(schema:by_index(2).fqn, "test.test2")
        assert.equals(schema:by_index(1).fqn, "test.test")
    end)

    it("Should hold type information about a column", function()
        local schema = Schema.from_create_table({
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        })

        assert.equals(schema:by_index(2).type, "number")
        assert.equals(schema:by_index(1).type, "string")
    end)

    it("Should hold display name information about a column", function()
        local schema = Schema.from_create_table({
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        })

        assert.equals(schema:by_index(2).display, "test2")
        assert.equals(schema:by_index(1).display, "test")
    end)

    it("Should throw an exception if the column information cannot be found", function()
        local schema = Schema.from_create_table({
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        })

        assert.has.error(function() schema:by_index(47) end)
        assert.has.error(function() schema:by_fqn("hello") end)
    end)
end)

describe("filter select", function()

    it("Should be able to produce a schema when all columns are selected", function()
        local schema = Schema.from_create_table({
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }):filter_select()

        assert.equals(schema:length(), 2)
    end)

    it("Should be able to produce a schema when some columns are selected", function()
        local schema = Schema.from_create_table({
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }):filter_select({"test.test2"})

        assert.equals(schema:by_index(1).fqn, "test.test2")
        assert.equals(schema:by_index(1).index, 1)
    end)

    it("Should be able to produce columns in the right order", function()
        local schema = Schema.from_create_table({
            table_name = "test",
            columns = {
                {type = "string", name = "test"},
                {type = "number", name = "test2"}
            }
        }):filter_select({"test.test2", "test.test"})

        assert.equals(schema:by_fqn("test.test2").index, 1)
        assert.equals(schema:by_fqn("test.test").index, 2)
    end)

    it("Should be able to produce a union of multiple schemas", function()
        local schema = Schema.from_create_table({
            table_name = "a_schema",
            columns = {
                {type = "string", name = "hello"},
                {type = "number", name = "world"}
            }
        }):combine(Schema.from_create_table({
            table_name = "a_second_schema",
            columns = {
                {type = "string", name = "goodbye"},
                {type = "number", name = "world"}
            }
        })):filter_select({"a_second_schema.goodbye", "a_schema.hello"})

        assert.equals(schema:by_fqn("a_second_schema.goodbye").index, 1)
        assert.equals(schema:by_fqn("a_schema.hello").index, 2)
    end)
end)
