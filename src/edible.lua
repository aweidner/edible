local lib = require("lib")
local Table = require("src/table").Table
local parser = require("parser")
local check = require("check")
local Schema = require("schema")

local Edible = {}

local function insert_structure_to_testable_structure(insert_structure)
    local result = {}

    for index, column in pairs(insert_structure.columns) do
        local table_name, column_name = Schema.defqnify(column.name)
        local value = insert_structure.values[index].value

        if not result[table_name] then
            result[table_name] = {}
        end

        result[table_name][column_name] = value
    end

    return result
end

local function parse_condition(condition)
    if condition == nil then
        return function() return true end
    end

    return function(result_to_test)
        local created_code = "return " .. condition
        local matches_condition, message = load(
            created_code,
            created_code,
            created_code, result_to_test)

        assert(message == nil, message)
        return matches_condition()
    end
end

local function matches_condition(insert_structure, condition)
    condition =  parse_condition(condition)
    return condition(insert_structure_to_testable_structure(
        insert_structure))
end

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
    local create_table_structure = parser.create_table(statement)
    check.table_structure(create_table_structure)

    local new_table = Table:new(create_table_structure.table_name,
        Schema.from_create_table(create_table_structure))
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

    local source_table = self.tables[select_structure.table_name]
    local source_schema = source_table.schema

    source_schema = source_schema:filter_select(lib.map(
        select_structure.columns or {},
        function(item)
            return Schema.fqnify(item.table_name, item.name)
        end))
    local temp_table = Table:new("temp", source_schema)

    for row in source_table:iterate() do
        local insert_structure = {
            columns = {},
            values = {}
        }

        local check_structure = {
            columns = {},
            values = {}
        }


        for key, value in pairs(row) do
            local fqn = Schema.fqnify(source_table.name, key)
            if source_schema:has_fqn(fqn) then
                table.insert(insert_structure.columns, {name = fqn})
                table.insert(insert_structure.values, {value = value})
            end
            table.insert(check_structure.columns, {name = fqn})
            table.insert(check_structure.values, {value = value})
        end

        if matches_condition(check_structure, select_structure.condition) then
            temp_table:insert(insert_structure)
        end
    end

    return coroutine.wrap(function()
        for entry in temp_table:iterate() do
            coroutine.yield(entry)
        end
    end)
end

function Edible:assert_table_exists(table_name)
    assert(self.tables[table_name], string.format("Table %s does not exist", table_name))
end


return Edible
