/*
 REQUIRED TRIGGERS
 1. DONE + update protection
 2. DONE
 3. DONE
 4. DONE + update protection
 5. DONE

 NOT REQUIRED TRIGGERS
 1. Storefront_Manager_Trigger -- Storefront must ALWAYS have a manager -- DONE + update
 2. Storeshift_Manager_Trigger -- StoreShifts must ALWAYS have a manager -- DONE + update
 3. Session_Instructor_Trigger -- Session instructors must be an employee of INSTRUCTOR role -- DONE + update
 4. Transfer_History_Trigger -- FromStoreId and ToStoreId CANNOT be the same storefrontID -- solved through updating table
 */
DROP TRIGGER IF EXISTS prevent_rental_overlap;
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

DROP TRIGGER IF EXISTS prevent_activation_overlap;
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

DROP TRIGGER IF EXISTS membership_validation_check;
CREATE TRIGGER membership_validation_check -- insert check membership // MODIFIED FROM LAB DOC, MEMBERS CANNOT ASSOCIATE IN A SALE WITHOUT A MEMBERSHIP
BEFORE INSERT ON RetailSale
FOR EACH ROW
WHEN NEW.customerId IS NOT NULL -- check if a customer is assigned
AND NOT EXISTS ( -- prevents a situation where a customer might have two active memberships
    SELECT 1
    FROM CustomerMembership cm
    WHERE cm.customerId = NEW.customerId
    AND isActive = 1
)
BEGIN
    SELECT RAISE(ABORT, 'No active membership could be found for this customer');
END;

DROP TRIGGER IF EXISTS sale_total_maintainance;
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

DROP TRIGGER IF EXISTS auto_logging_security;
CREATE TRIGGER auto_logging_security
BEFORE UPDATE ON AuditLog
BEGIN
    SELECT RAISE(ABORT, 'Audit logs cannot be updated');
END;

-- Trigger 5
-- NOTE: The ticket table as of starting this trigger does NOT have a completionDate value, so I will be adding one
DROP TRIGGER IF EXISTS repair_status_automation;
CREATE TRIGGER repair_status_automation
AFTER UPDATE ON Ticket      -- Where our repairs are tracked
FOR EACH ROW
WHEN NEW.status = 'Complete' and OLD.status != 'Complete'
BEGIN
    UPDATE Ticket
    SET completionDate = datetime('now')
        WHERE ticketId = NEW.ticketId;
END;

-- NOT REQUIRED TRIGGERS
DROP TRIGGER IF EXISTS ensure_storefront_manager;
CREATE TRIGGER ensure_storefront_manager -- ensures storefront manager is an employee that has manager role
BEFORE INSERT ON Storefront
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

DROP TRIGGER IF EXISTS maintain_storefront_manager;
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

DROP TRIGGER IF EXISTS session_instructor_validation;
CREATE TRIGGER session_instructor_validation -- checks that a session instructor is an employee with role of instructor
BEFORE INSERT ON SessionInstructor
FOR EACH ROW
BEGIN
    SELECT RAISE(ABORT, 'Cannot insert instructor, employee must have the role of "Instructor"')
    WHERE NOT EXISTS (
        SELECT 1
        FROM Employee e
        JOIN role r
            ON e.roleId = r.roleId
        WHERE e.employeeId = NEW.instructorId
        AND r.roleTitle = 'Instructor'
    );
END;

DROP TRIGGER IF EXISTS maintain_session_instructor_validation;
CREATE TRIGGER maintain_session_instructor_validation -- checks updates to a given instructor
BEFORE UPDATE OF instructorId ON SessionInstructor
FOR EACH ROW
BEGIN
    SELECT RAISE(ABORT, 'Cannot update instructor, employee must have the role of "Instructor"')
    WHERE NOT EXISTS (
        SELECT 1
        FROM Employee e
        JOIN role r
            ON e.roleId = r.roleId
        WHERE e.employeeId = NEW.instructorId
        AND r.roleTitle = 'Instructor'
    );
END;

DROP TRIGGER IF EXISTS same_transfer_locations_prevention;
CREATE TRIGGER same_transfer_locations_prevention -- Prevents tranfers where the origin and destination storefronts are the same
BEFORE INSERT ON TransferHistory
FOR EACH ROW
BEGIN
    SELECT RAISE(ABORT, 'Cannot insert transfer, to and from stores cannot be the same')
    WHERE NEW.toStoreId = NEW.fromStoreId;
END;

DROP TRIGGER IF EXISTS same_transfer_locations_security;
CREATE TRIGGER same_transfer_locations_security
BEFORE UPDATE ON TransferHistory
FOR EACH ROW
BEGIN
    SELECT RAISE(ABORT, 'Transfer History cannot be updated');
END;
