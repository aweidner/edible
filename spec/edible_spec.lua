local Edible = require("edible")

describe("Edible", function()
    it("Should be able to execute some commands against a database", function()

        local db = Edible:new()
        db:execute("CREATE TABLE shippers (ShipperID int, CompanyName string, Phone string)")
        db:execute("INSERT INTO shippers (ShipperID, CompanyName, Phone) VALUES (1, 'Speedy Express', '(503) 555-9831')")
        db:execute("INSERT INTO shippers (ShipperID, CompanyName, Phone) VALUES (2, 'United Package', '503-555-3199')")
        db:execute("INSERT INTO shippers (ShipperID, CompanyName, Phone) VALUES (3, 'Federal Shipping', '503-555-9931')")
        local result = db:execute("SELECT * FROM shippers")

        local all_results = {}
        for item in result do
            table.insert(all_results, item)
        end

        assert.equals(#all_results, 3)
        assert.equals(all_results[1].CompanyName, "Speedy Express")
        assert.equals(all_results[2].CompanyName, "United Package")
        assert.equals(all_results[3].CompanyName, "Federal Shipping")
    end)

    it("Should raise an error if it cannot understand a statement", function()
        local db = Edible:new()
        db:execute("CREATE TABLE shippers (ShipperID int, CompanyName string, Phone string)")
        assert.has.errors(function()
            db:execute("Makes no sense")
        end)
    end)
end)
