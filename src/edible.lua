local Table = require("src/table").Table
local parser = require("parser")

local Edible = {}

function Edible:new()
    local new_edible = {tables = {}}
    setmetatable(new_edible, self)
    self.__index = self
    return new_edible
end

function Edible:execute(statement)
    if statement:find("^CREATE TABLE") then
        self:create_table(statement)
    elseif statement:find("^INSERT INTO") then
        self:insert(statement)
    elseif statement:find("^SELECT") then
        return self:find(statement)
    elseif statement:find("^DROP TABLE") then
        return self:drop_table(statement)
    else
        assert(false, "Unable to understand request")
    end
end

function Edible:create_table(statement)
    local new_table = Table:new(parser.create_table(statement))
    self.tables[new_table.name] = new_table
end

function Edible:insert(statement)
    local insert_structure = parser.insert(statement)
    self:assert_table_exists(insert_structure.table_name)
    self.tables[insert_structure.table_name]:insert(insert_structure)
end

function Edible:drop_table(statement)
    local table_name = parser.drop_table(statement).table_name
    self:assert_table_exists(table_name)
    self.tables[table_name] = nil
end

function Edible:find(statement)
    local select_structure = parser.find(statement)
    self:assert_table_exists(select_structure.table_name)
    return self.tables[select_structure.table_name]:find(select_structure)
end

function Edible:assert_table_exists(table_name)
    assert(self.tables[table_name], string.format("Table %s does not exist", table_name))
end


return Edible
