local Table = require("src/table").Table
local parser = require("parser")
local inspect = require("optional/inspect")

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
    self.tables[insert_structure.table_name]:insert(insert_structure)
end

function Edible:find(statement)

    -- Create a temp table that has the schema of the tables
    -- that are being joined into it
    --
    -- For each entry in each table
    --   If the join condition is met
    --     If the select condition is met
    --       Create a row index either by integer or by what we're sorting by
    --       Create the row based on which columns were selected
    --       Insert the row with the row id
    --     end
    --   end
    -- end
end

return Edible
