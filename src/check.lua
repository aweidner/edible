-- Library to make working with assertions easier.  Locate all
-- assertions used in the code to one place for convinience and
-- to keep from having validation logic scattered.
--
-- All functions return nil OR raise an error if there
-- is any validation failure

local check = {}

function check.table_structure(structure)
    -- Check that the table structure in `structure` is valid.  Valid table structures:
    --
    -- 1. MUST have a name in the `table_name` field
    -- 2. MUST have columns which:
    --      a. Have a `type` ~= nil
    --      b. Have a `name`
    assert(structure.table_name ~= nil, "Table name must be defined")

    for index, column in pairs(structure.columns) do
        assert(column.name ~= nil, string.format(
            "Column name not defined at index %d for table %s",
            index, structure.table_name))
        assert(column.type ~= nil, string.format(
            "Type not defined for column %s in table %s",
            column.name, column.name))
    end
end

return check
