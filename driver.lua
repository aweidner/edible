package.path = package.path .. ";src/?.lua"

local Edible = require("edible")

local db = Edible:new()
while true do
    io.write("> ")
    local statement = io.read()
    local success, result = pcall(function() return db:execute(statement) end)

    if not success then
        print(result)
    else
        if type(result) == "function" then
            for row in result do
                local printable_table = {}
                for k, v in pairs(row) do
                    table.insert(printable_table, k .. " = " .. tostring(v))
                end
                print(table.concat(printable_table, ", "))
            end
        end
    end
end
