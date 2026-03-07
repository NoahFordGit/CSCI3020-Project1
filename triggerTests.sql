/* =========================================================
TRIGGER DEMONSTRATION SCRIPT
Each section demonstrates a trigger firing or succeeding
========================================================= */


/* =========================================================
SETUP DATA REQUIRED FOR MULTIPLE TESTS
========================================================= */

INSERT INTO Role VALUES (1,'Sales',1);
INSERT INTO Role VALUES (2,'Manager',5);
INSERT INTO Role VALUES (3,'Instructor',4);

INSERT INTO Employee VALUES (100,NULL,2,'Alice','Manager',datetime('now'),30,1);
INSERT INTO Storefront VALUES (1,100,'123 Main St','5551111');

UPDATE Employee SET storeId = 1 WHERE employeeId = 100;

INSERT INTO Employee VALUES (101,1,1,'Bob','Sales',datetime('now'),15,1);
INSERT INTO Employee VALUES (102,1,3,'Carol','Instructor',datetime('now'),20,1);

INSERT INTO RentalModel VALUES (1,'Bike');
INSERT INTO RentalUnit VALUES (1,'UnitA','Good',datetime('now'),1,1);

/* =========================================================
 1. ensure_storefront_manager (VALID + INVALID)
========================================================= */

-- VALID (employee 100 is manager)
INSERT INTO Storefront VALUES (2,100,'456 Center St','5552222');

-- INVALID (employee 101 is not manager)
INSERT INTO Storefront VALUES (3,101,'789 Fail St','5553333');


/* =========================================================
 2. maintain_storefront_manager
========================================================= */

-- INVALID update (sales employee cannot become manager)
UPDATE Storefront
SET managerId = 101
WHERE storefrontId = 2;


/* =========================================================
 3. session_instructor_validation
========================================================= */

INSERT INTO TrainingCourse VALUES (1,'Bike Safety','Basic training');
INSERT INTO CourseSession VALUES (1,10,1);

-- VALID instructor
INSERT INTO SessionInstructor VALUES (1,102);

-- INVALID instructor (employee 101 is not instructor)
INSERT INTO SessionInstructor VALUES (1,101);


/* =========================================================
 4. maintain_session_instructor_validation
========================================================= */

-- INVALID update (changing instructor to non-instructor)
UPDATE SessionInstructor
SET instructorId = 101
WHERE sessionId = 1 AND instructorId = 102;


/* =========================================================
 5. membership_validation_check
========================================================= */

INSERT INTO Customer VALUES (1,datetime('now'));
INSERT INTO Membership VALUES (1,'Gold');

-- Active membership
INSERT INTO CustomerMembership VALUES (1,1,1);

-- VALID SALE
INSERT INTO RetailSale
VALUES (1,datetime('now'),2,10,1,1,101);

-- INVALID SALE (customer without membership)
INSERT INTO Customer VALUES (2,datetime('now'));

INSERT INTO RetailSale
VALUES (2,datetime('now'),2,10,2,1,101);


/* =========================================================
 6. sale_total_maintainance
========================================================= */

INSERT INTO RetailProduct VALUES (1,'Helmet','BrandX','Safety',50,'Non-exempt','Active');

-- Add line item (trigger updates subtotal)
INSERT INTO ProductSale VALUES (1,1,2);

-- Evidence subtotal updated
SELECT saleId, subtotalAmount FROM RetailSale;


/* =========================================================
 7. prevent_rental_overlap
========================================================= */

-- Existing ACTIVE contract
INSERT INTO RentalContract VALUES (1, datetime('now'), datetime('now','+7 day'), 100, 10, 1, 1, 101, 1);
INSERT INTO ContractUnit VALUES (1, 1); -- matches RentalContract 1

-- Attempt INVALID: second ACTIVE contract for same unit
INSERT INTO RentalContract VALUES (2, datetime('now'), datetime('now','+7 day'), 100, 10, 1, 1, 101, 1);
-- This line will ABORT due to prevent_rental_overlap
INSERT INTO ContractUnit VALUES (2, 1);


/* =========================================================
 8. prevent_activation_overlap
========================================================= */

-- Existing active contract (already inserted above: contractId 1)

-- Create NEW inactive contract
INSERT INTO RentalContract VALUES (3, datetime('now'), datetime('now','+7 day'), 100, 10, 0, 1, 101, 1);
INSERT INTO ContractUnit VALUES (3, 1);

-- INVALID activation (unit already active elsewhere)
UPDATE RentalContract
SET isActive = 1
WHERE contractId = 3; -- Should ABORT via prevent_activation_overlap


/* =========================================================
 9. same_transfer_locations_prevention
========================================================= */

-- INVALID transfer (same store)
INSERT INTO TransferHistory
VALUES (1,datetime('now'),1,1,1);


/* =========================================================
 10. same_transfer_locations_security
========================================================= */

INSERT INTO TransferHistory
VALUES (2,datetime('now'),1,1,2);

-- INVALID update attempt
UPDATE TransferHistory
SET toStoreId = 1
WHERE transferId = 2;


/* =========================================================
 11. repair_status_automation
========================================================= */

INSERT INTO Ticket
VALUES (1,'High','Open','Repair',100,1,NULL);

-- Update status → trigger fills completionDate
UPDATE Ticket
SET status = 'Complete'
WHERE ticketId = 1;

SELECT ticketId,status,completionDate FROM Ticket;


/* =========================================================
 12. auto_logging
========================================================= */

UPDATE RentalContract
SET isActive = 0
WHERE contractId = 1;

-- Evidence log entry
SELECT * FROM AuditLog;


/* =========================================================
 13. auto_logging_security
========================================================= */

-- INVALID modification of log
UPDATE AuditLog
SET newValue = '999'
WHERE oldValue = 1;

/* =========================================================
   TRIGGER PERFORMANCE ANALYSIS
   PREVENT_RENTAL_OVERLAP -- Required Trigger #1
========================================================= */
EXPLAIN QUERY PLAN
SELECT 1 -- find all instances
    FROM ContractUnit cu
    JOIN RentalContract rc
        ON cu.contractId = rc.contractId
    JOIN RentalContract new_rc
        ON new_rc.contractId = 1 -- equals ONE in place of NEW.contractId
    WHERE cu.unitId = 1          -- equals ONE in place of NEW.unitId
    AND rc.isActive = 1
    AND new_rc.isActive = 1;


-- Optional: disable foreign key enforcement temporarily (SQLite)
PRAGMA foreign_keys = OFF;

DELETE FROM AuditLog;
DELETE FROM ProductSale;
DELETE FROM ContractUnit;
DELETE FROM TransferHistory;
DELETE FROM Ticket;
DELETE FROM SessionInstructor;
DELETE FROM CourseSession;
DELETE FROM TrainingCourse;
DELETE FROM CustomerMembership;
DELETE FROM Membership;
DELETE FROM RetailSale;
DELETE FROM RentalContract;
DELETE FROM RentalUnit;
DELETE FROM RentalModel;
DELETE FROM RetailProduct;
DELETE FROM Customer;
DELETE FROM Employee;
DELETE FROM Storefront;
DELETE FROM Role;

PRAGMA foreign_keys = ON;
