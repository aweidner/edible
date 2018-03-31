-- Schema contains all metadata pertaining to a table.  It has information
-- about how many columns are in the table, their fully qualified names,
-- indexes, etc
local Schema = {}

Schema.Column = {}
Schema.Schema = {}

function Schema.Column:new(column_definition, table_name, index, display)
    -- Create a new column definition.  Columns are only data classes and have
    -- no methods
    local new_column = {
        index = index,
        fqn = table_name .. "." .. column_definition.name,
        display = display or column_definition.name,
        type = column_definition.type
    }
    setmetatable(new_column, self)
    self.__index = self
    return new_column
end

function Schema.Schema:from_create_table(create_table_structure)
    -- Create a schema from a select statement.  Schemas allow columns
    -- to be referenced both by fully qualified name and index.  Thus
    -- they must hold two maps.  One to map by fully qualified name and
    -- one to map by index.  The column references are the same in either case.
    local columns = {}
    local columns_by_fqn = {}

    -- Build the column definitions and both maps
    for index, column_definition in ipairs(create_table_structure.columns) do
        local latest_column = Schema.Column:new(column_definition,
            create_table_structure.table_name, index)
        table.insert(columns, latest_column)
        columns_by_fqn[latest_column.fqn] = latest_column
    end

    local new_schema = {
        table_name = create_table_structure.table_name,
        columns = columns,
        columns_by_fqn = columns_by_fqn
    }

    setmetatable(new_schema, self)
    self.__index = self
    return new_schema
end

function Schema.Schema:length()
    -- Length is simply the number of columns
    return #self.columns
end

function Schema.Schema:by_fqn(fully_qualified_name)
    -- Look up a column by the fully qualified name (including table name)
    local table, _ = fully_qualified_name:match("^(.+)%.(.+)$")
    assert(self.table_name == table, string.format(
        "Table name %s not found in this schema", table))
    return self.columns_by_fqn[fully_qualified_name]
end

function Schema.Schema:by_index(index)
    -- Look up a column by its position within the schema
    assert(index > 0 and index <= self:length(), "Index out of bounds")
    return self.columns[index]
end

return Schema
