package.path = package.path .. ";src/?.lua"

local BTree = require("btree").BTree
local Row = require("btree").Row
local Cell = require("btree").Cell

local function benchmark(title, f, parameters)
    local trials = 3
    local overall_results = {}

    for k, v in pairs(parameters) do
        local total = 0
        for trial = 1, trials do
            local start = os.clock()
            f(table.unpack(v))
            total = total + (os.clock() - start)
        end
        local average_for_these_parameters = total / trials

        overall_results[k] = average_for_these_parameters
    end

    print("Runs for ", title)
    for k, v in pairs(overall_results) do
        print(k, v)
    end
end

benchmark("Insert 100000 integers (one cell rows)", function(page_size)
    local tree = BTree:new(page_size)
    for i = 1, 100000 do
        tree:insert(Row:new(i, {Cell:new(i)}))
    end
end, {{64}, {128}, {256}, {512}, {1024}, {2048}})
