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

function Schema.Column:copy()
    -- Copy constructor for columns.  This is particularly important to
    -- prevent from corrupting the indexes which change whenever a schema
    -- changes
    local new_column = {
        index = self.index,
        fqn = self.fqn,
        display = self.display,
        type = self.type
    }
    setmetatable(new_column, self)
    self.__index = self
    return new_column
end

function Schema.from_create_table(create_table_structure)
    -- Factory method to create a schema from a standard create table structure.
    -- Structure looks like:
    --
    -- {
    --  table_name = "test",
    --  columns = {
    --      {type = "string", name = "test"},
    --      {type = "number", name = "test2"}
    -- }
    local function make_column(index, column_definition)
        return Schema.Column:new(column_definition,
            create_table_structure.table_name, index)
    end

    return Schema.Schema:new(make_column, create_table_structure.columns)
end

function Schema.from_column_definitions(column_definitions)
    -- Factory method to create a schema from a table of column definitions.
    -- Most often used internally as a copy constructor
    local function make_column(index, column_definition)
        local latest_column = column_definition:copy()
        latest_column.index = index
        return latest_column
    end

    return Schema.Schema:new(make_column, column_definitions)
end

function Schema.Schema:new(make_column, column_definitions)
    -- Hidden constructor method.  Should not be used publicly.
    -- Args:
    --  make_column: factory function used to produce a Schema.Column from
    --      the index of the column and the definition of the column which
    --      will be one of the entries in `column_definitions`
    --  column_definitions: table containing any type of object as long as the factory
    --      method `make_column` can take one of its elements as an argument
    --      and produce a Schema.Column
    local columns = {}
    local columns_by_fqn = {}

    for index, column_definition in ipairs(column_definitions) do
        local latest_column = make_column(index, column_definition)
        table.insert(columns, latest_column)
        columns_by_fqn[latest_column.fqn] = latest_column
    end

    local new_schema = {
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
    assert(self.columns_by_fqn[fully_qualified_name], string.format(
        "Column %s not found in this schema", table))
    return self.columns_by_fqn[fully_qualified_name]
end

function Schema.Schema:by_index(index)
    -- Look up a column by its position within the schema
    assert(index > 0 and index <= self:length(), "Index out of bounds")
    return self.columns[index]
end

function Schema.Schema:filter_select(columns)
    -- Take the current schema and filter it by the list of
    -- fqn column names given
    --
    -- Example: {"test.test2", "test.test"}
    if not columns or #columns == 0 then return self end

    local columns_selected = {}
    for _, fqn in pairs(columns) do
        table.insert(columns_selected, self:by_fqn(fqn))
    end

    return Schema.from_column_definitions(columns_selected)
end

function Schema.Schema:combine(other_schema)
    -- Concatenate the two schemas together in order to
    -- form one schema
    local all_column_definitions = {}
    for _, column_definition in pairs(self.columns) do
        table.insert(all_column_definitions, column_definition:copy())
    end

    for _, column_definition in pairs(other_schema.columns) do
        table.insert(all_column_definitions, column_definition:copy())
    end
    return Schema.from_column_definitions(all_column_definitions)
end

return Schema
