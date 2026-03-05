/*
 REQUIRED TRIGGERS
 1. DONE + update protection
 2. DONE
 3. DONE
 4. DONE
 5. DONE

 NOT REQUIRED TRIGGERS
 1. Storefront_Manager_Trigger -- Storefront must ALWAYS have a manager
 2. Storeshift_Manager_Trigger -- StoreShifts must ALWAYS have a manager
 3. Session_Instructor_Trigger -- Session instructors must be an employee of INSTRUCTOR role
 4. Transfer_History_Trigger -- FromStoreId and ToStoreId CANNOT be the same storefrontID
 */
CREATE TRIGGER prevent_rental_overlap -- insert protection
BEFORE INSERT ON ContractUnit
FOR EACH ROW
WHEN EXISTS (
    SELECT 1 -- find all instances
    FROM ContractUnit cu
    JOIN RentalContract rc
        ON cu.contractId = rc.contractId -- Join ContractUnit and RentalContract to get isActive field
    WHERE cu.unitId = NEW.unitId                  -- Where our NEW unit exits in ContractUnit
    AND rc.isActive = 1                           -- AND our contract is active
) -- Prevents a unit being double booked by an active contract, by checking if the Contract a unit is tied to is active
BEGIN
    SELECT RAISE(ABORT, 'Cannot insert contract, there is already an active contract');
END;

CREATE TRIGGER prevent_activation_overlap -- update protection
BEFORE UPDATE of isActive on RentalContract
FOR EACH ROW
WHEN NEW.isActive = 1 -- if updating to be active
AND EXISTS (
    SELECT 1 -- find all instances
    FROM ContractUnit cu1
    JOIN ContractUnit cu2
        ON cu1.unitId = cu2.unitId -- Find all rows with the same Unit
    JOIN RentalContract rc
        ON cu2.contractId = rc.contractId
    WHERE cu1.contractId = NEW.contractId
    AND rc.isActive = 1
    AND cu1.contractId != cu2.contractId -- Eliminates matching the same row
    )
BEGIN
    SELECT RAISE(ABORT, 'Cannot update contract, there is already an active contract');
END;

CREATE TRIGGER membership_validation_check -- insert check membership // MODIFIED FROM LAB DOC, MEMBERS CANNOT ASSOCIATE IN A SALE WITHOUT A MEMBERSHIP
BEFORE INSERT ON RetailSale
FOR EACH ROW
WHEN NEW.customerId IS NOT NULL -- check if a customer is assigned
AND NOT EXISTS ( -- prevents a situation where a customer might have two active memberships
    SELECT 1
    FROM CustomerMembership
    WHERE customerId = NEW.customerId
    AND isActive = 1
    )
    BEGIN
        RAISE(ABORT, 'No active membership could be found for this customer');
    END;
END;

CREATE TRIGGER sale_total_maintainance
AFTER INSERT ON ProductSale
FOR EACH ROW
BEGIN
   UPDATE RetailSale
   SET subtotalAmount = (
       SELECT IFNULL(SUM(ps.quantity * rp.standardPrice), 0) -- Caluclating sum by joining line items with the product prices, IF NULL PRICE IS ZERO
       FROM ProductSale ps
       JOIN RetailProduct rp --Linking RP that has the price with the PS that has qunatity to allow multiplying
          ON ps.productSKU = rp.productSKU
        WHERE ps.saleId = NEW.saleId --ensures it only updates the specific RS row that matches the sale
   )
    WHERE saleId = NEW.saleId;
END;


-- Trigger 4
DROP TRIGGER IF EXISTS auto_logging;
CREATE TRIGGER auto_logging
AFTER UPDATE ON RentalContract
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog(valueId, tableName, oldValue, newValue, time)      -- Timestamp is in quotes here cause it is a keyword
    VALUES(OLD.contractId, 'RentalContract',OLD.isActive, NEW.isActive, datetime('now'));
END;


-- Trigger 5
-- NOTE: The ticket table as of starting this trigger does NOT have a completionDate value, so I will be adding one
CREATE TRIGGER repair_status_automation
AFTER UPDATE ON Ticket      -- Where our repairs are tracked
FOR EACH ROW
WHEN NEW.status = 'Complete'
BEGIN
    UPDATE Ticket
    SET completionDate = datetime('now')
        WHERE ticketId = NEW.ticketId;
END;




/*
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!!!!!!!!!! TEST CASES START HERE !!!!!!!!!!!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/
-- Insert Statements (sample data)
-- Note all inserts should pass unless stated otherwise

INSERT INTO RetailProduct(productSKU, name, brand, category, standardPrice, taxStatus, activeStatus)
    VALUES(10000001, 'Toolbox', 'Craftsman', 'Hardware', 19.99, 'Exempt', 'Active'),
            (10000002, 'Toolbox Red', 'Craftsman', 'Hardware', 19.99, 'Exempt', 'Active'),
            (10000003, 'Toolbox White', 'Craftsman', 'Hardware', 19.99, 'Exempt', 'Active'),
            (10000004, 'Ball-Peen Hammer', 'Stanley', 'Tools', 9.99, 'Non-exempt', 'Active'),
            (10000005, 'Claw Hammer', 'Stanley', 'Tools', 8.99, 'Non-exempt', 'Active'),
            (10000006, 'Drill/Driver Kit', 'Dewalt', 'Tools', 99.99, 'Exempt', 'Active'),
            (10000007, 'Thermal Gloves', 'Dewalt', 'Workwear', 7.99, 'Exempt', 'Active'),
            (10000008, 'Welding Gloves', 'Dewalt', 'Workwaer', 39.99, 'Exempt', 'Active');

INSERT INTO Customer(customerId,creationDate)
    VALUES(1001,'2025-03-01 14:30:00'),
            (1002,'2025-09-01 14:30:00'),
            (1003,'2025-10-01 14:30:00');

INSERT INTO CustomerName(customerId, firstName, lastName)
    VALUES(1001, 'Matthew', 'Desjardins'),
            (1002, 'Dillion', 'Buchanan'),
            (1003, 'Jacob', 'Gillenwater');

INSERT INTO CustomerPhone(customerId, phoneNumber)
    VALUES(1001, 4234396951),
            (1002, 4234395599),
            (1003, 4234396970);

INSERT INTO RentalModel(modelId, rentalType)
    VALUES(201, 'Hourly'),
          (202, 'Daily'),
          (203, 'Weekly');

INSERT INTO Role(roleId, roleTitle, permissionLevel)
    VALUES(1,'Sales', 2),
          (2, 'Repair Tech', 4),
          (3, 'Trainer', 6);

INSERT INTO Vendor(vendorID, vendorName)
    VALUES(900, 'Craftsman'),
          (901, 'Dewalt'),
          (902, 'Stanley');

INSERT INTO RentalUnit(unitId, name, conditionStatus, purchaseDate, modelId, storefrontId)
    VALUES(301, 'Forklift A', 'Good', '2024-05-01', 202, 1),
          (302, 'Forklift B', 'Fair', '2024-06-15', 202, 1),
          (303, 'Pallet Jack', 'Good', '2024-07-10', 201, 1);

INSERT INTO RentalContract(contractId, startDate, expectedReturnDate, depositAmount, lateFee, isActive, customerId, employeeId, storeId)
    VALUES (601, '2026-04-01', '2026-04-05', 50, 10, 1, 1001, 1, 1);

INSERT INTO ContractUnit(contractId, unitId)
    VALUES(501, 301);

INSERT INTO Membership(membershipId, membershipName)
    VALUES(1, 'Basic'),
          (2, 'Premium');

INSERT INTO CustomerMembership(membershipId, customerId, isActive)
    VALUES(1, 1001, 1);

-- This insert should FAIL if trigger works
INSERT INTO CustomerMembership(membershipId, customerId, isActive)
    VALUES(2, 1001, 1);

INSERT INTO RetailSale(saleId, saleDate, taxAmount, subtotalAmount, customerId, storefrontId, employeeId)
    VALUES(7001, '2026-02-15 10:00:00', 2.50, 25.00, 1001, 1, 1);

INSERT INTO ProductSale(saleId, productSKU, quantity)
    VALUES(7001, 10000001, 1),
          (7001, 10000004, 2),
          (7001, 10000007, 1);

INSERT INTO Discount(discountId, discountName, discountType)
    VALUES(301, 'Winter Sale', 'Percentage');

INSERT INTO SaleDiscount(saleId, discountId)
    VALUES(7001, 301);

INSERT INTO Ticket(ticketId, priority, status, labor, billAmount, unitId)
    VALUES (901, 'Medium', 'In Progress', 'Replace belt', 75, 301);

INSERT INTO Part(partId, partName, quantity, unitId)
    VALUES(901, 'Hydraulic Hose', 10, 301),
          (902, 'Hydraulic Fluid', 5, 301);

INSERT INTO TicketPart(partId, ticketId, quantity)
    VALUES(901, 801, 1),
          (902, 801, 2);

INSERT INTO UnitPart(partId, unitId)
    VALUES(901, 301),
          (902, 301);

-- This insert is supposed to FAIL
INSERT INTO Employee(employeeId, storeId, roleId, firstName, lastName, hireDate, hourlyRate, isActive)
    VALUES(000123456, NULL, 3, 'Steve', 'Rogers', '2026-02-01 14:30:00', 12.00, NULL);
-- This insert is supposed to FAIL
INSERT INTO RentalUnit(unitId, name, conditionStatus, purchaseDate, modelId, storefrontId)
    VALUES(401, 'Forklift','Good', '2025-03-21 14:30:00', 202, NULL);
-- This insert is supposed to FAIL
INSERT INTO Storefront(storefrontId, managerId, storeAddress, phoneNumber)
    VALUES(301,NULL, NULL, 123456789);
-- This insert is supposed to FAIL
INSERT INTO CustomerAddress(customerId, zipCode, addressLine1, addressLine2, city, state, country, isPreferred)
    VALUES(1001, 37877, '456 Main Street', NULL,'Talbott', 'TN', 'USA', 2);
-- This insert is supposed to FAIL
INSERT INTO CustomerMembership(membershipId, customerId, isActive)
    VALUES(8, 1001, 5);


 -- UPDATE Statements (used for triggers 4 and 5)
 UPDATE RentalContract
    SET isActive = 0
    WHERE contractId = 601;

UPDATE Ticket
    SET status = 'Complete'
    WHERE ticketId = 901;


-- Delete Statements (please run these after testing insert statements, or they will not work)
DELETE FROM RetailProduct;
DELETE FROM Customer;
DELETE FROM CustomerName;
DELETE FROM CustomerPhone;
DELETE FROM RentalModel;
DELETE FROM Role;
DELETE FROM Vendor;
DELETE FROM Employee;
DELETE FROM RentalUnit;
DELETE FROM Storefront;
DELETE FROM CustomerAddress;
DELETE FROM CustomerMembership;
DELETE FROM RentalUnit;
DELETE FROM RentalContract;
DELETE FROM ContractUnit;
DELETE FROM Membership;
DELETE FROM CustomerMembership;
DELETE FROM RetailSale;
DELETE FROM ProductSale;
DELETE FROM Discount;
DELETE FROM SaleDiscount;
DELETE FROM Ticket;
DELETE FROM Part;
DELETE FROM TicketPart;
DELETE FROM UnitPart;


