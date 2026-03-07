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
    INSERT INTO AuditLog(valueId, tableName, oldValue, newValue, time)
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

CREATE TRIGGER ensure_storefront_manager -- ensures storefront manager is an employee that has manager role
BEFORE INSERT ON StoreFront
FOR EACH ROW
BEGIN
    SELECT RAISE(ABORT, 'Cannot insert storefront, there is no assigned manager.')
    WHERE NOT EXISTS (
        SELECT 1
        FROM Employee e
        JOIN role r
            ON e.roleId = r.roleId
        WHERE e.employeeId = NEW.managerId
        AND r.roleTitle = 'Manager'
        );
END;
END;
CREATE TRIGGER maintain_storefront_manager -- ensures updated manager is an employee with manager role
BEFORE UPDATE OF managerId ON Storefront
FOR EACH ROW
BEGIN
    SELECT RAISE(ABORT, 'Cannot update storefront, employee is not a manager')
    WHERE NOT EXISTS (
        SELECT 1
        FROM Employee e
        JOIN role r
            ON e.roleId = r.roleId
        WHERE e.employeeId = NEW.managerId
        AND r.roleTitle = 'Manager'
        );
END;

CREATE TRIGGER session_instructor_validation --checks that a session instructor is an employee with role of instructor
BEFORE INSERT ON SessionInstructor
FOR EACH ROW
BEGIN
    SELECT
    CASE 
    WHEN ( 
    SELECT r.roleTitle
    FROM Employee e
    JOIN Role r ON e.roleId = r.roleId
    WHERE e.employeeId = NEW.instructor 
    ) != 'instructor' THEN RAISE(ABORT, 'The selected employee does not have a instrustor role, cannot be selected as session instructor.')
END;
END;

CREATE TRIGGER same_transfer_locations_prevention -- Prevents tranfers where the origin and destination storefronts are the same
BEFORE INSERT ON TransferHistory
FOR EACH ROW
BEGIN
    SELECT
    CASE
    WHEN NEW.fromStoreId = new.toStoreId 
    THEN RAISE(ABORT, 'Cannot tranfer items with origin and destination stores being the same.')
END;
END;


/*
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!!!!!!!!!! TEST CASES START HERE !!!!!!!!!!!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/
-- Insert Statements (sample data)
-- Note all inserts should pass unless stated otherwise

/*
 Test cases by trigger:
    TRIGGER 1: Run RentalContract, ContractUnit
    TRIGGER 2: Run RentalContract, Update statement (see below)
    TRIGGER 3: Run RetailProduct, Customer (all tables), Membership, CustomerMembership, RetailSale
    TRIGGER 4: Run RentalContract, Update statement (see below)
    TRIGGER 5: Run Ticket, Part, UnitPart, TicketPart, and Update statement (see below)
 */


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
    VALUES(601, '2026-04-01', '2026-04-05', 50, 10, 1, 1001, 1, 1),
          (602, '2026-04-10', '2026-04-15', 40, 10, 1, 1002, 1, 1),
          (603, '2026-04-12', '2026-04-20', 40, 10, 1, 1003, 1, 1);

-- This insert is set up to cause a FAIL later on for trigger 2 (should still pass, see update statement below)
INSERT INTO RentalContract(contractId, startDate, expectedReturnDate, depositAmount, lateFee, isActive, customerId, employeeId, storeId)
VALUES (604, '2026-05-01', '2026-05-05', 50, 10, 0, 1001, 1, 1);


INSERT INTO ContractUnit(contractId, unitId)
    VALUES(601, 301),
          (602, 302);

-- This insert is supposed to FAIL per trigger 1
INSERT INTO ContractUnit(contractId, unitId)
    VALUES (603, 302);


INSERT INTO Membership(membershipId, membershipName)
    VALUES(1, 'Basic'),
          (2, 'Premium');

INSERT INTO CustomerMembership(membershipId, customerId, isActive)
    VALUES(1, 1001, 1),
          (2, 1002, 1);

-- This insert is supposed to FAIL per trigger 3
INSERT INTO CustomerMembership
    VALUES (1, 1002, 1);

-- This insert is set up to cause a FAIL later on for trigger 3 (should still pass, see update statement below)
INSERT INTO CustomerMembership
    VALUES (1, 1003, 0);


INSERT INTO RetailSale(saleId, saleDate, taxAmount, subtotalAmount, customerId, storefrontId, employeeId)
    VALUES(7002, '2026-03-01 11:00:00', 3.50, 0, 1002, 1, 1);

-- This insert is supposed to FAIL per trigger 3
INSERT INTO RetailSale(saleId, saleDate, taxAmount, subtotalAmount, customerId, storefrontId, employeeId)
    VALUES (7003, '2026-03-02 09:00:00', 1.50, 10.00, 1003, 1, 1);


INSERT INTO ProductSale(saleId, productSKU, quantity)
    VALUES (7002, 10000001, 1),
           (7002, 10000004, 3),
           (7002, 10000005, 2),
           (7002, 10000007, 1);


INSERT INTO Discount(discountId, discountName, discountType)
    VALUES(301, 'Winter Sale', 'Percentage');

INSERT INTO SaleDiscount(saleId, discountId)
    VALUES(7002, 301);

INSERT INTO Ticket(ticketId, priority, status, labor, billAmount, unitId)
    VALUES (901, 'Medium', 'In Progress', 'Replace belt', 75, 301),
           (902, 'High', 'Open', 'Replace wheel bearings', 150, 303);


INSERT INTO Part(partId, partName, quantity, unitId)
    VALUES(903, 'Wheel Bearing', 4, 303),
          (904, 'Lubricant', 2, 303);


INSERT INTO TicketPart(partId, ticketId, quantity)
    VALUES(903, 902, 2),
          (904, 902, 1);


INSERT INTO UnitPart(partId, unitId)
    VALUES(903, 303),
          (904, 303);

-- This insert is supposed to FAIL (constraint testing, non-trigger)
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


 -- UPDATE Statements

 -- This update will FAIL via trigger 2
 UPDATE RentalContract
    SET isActive = 1
    WHERE contractId = 604;

-- Used to test trigger 4 (should PASS)
 UPDATE RentalContract
    SET isActive = 0
    WHERE contractId = 601;

-- Used to test trigger 5 (should PASS)
UPDATE Ticket
    SET status = 'Complete'
    WHERE ticketId = 902;



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
