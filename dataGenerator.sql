PRAGMA foreign_keys = OFF;

------------------------------------------------
-- ROLES
------------------------------------------------
INSERT OR IGNORE INTO Role(roleId, roleTitle, permissionLevel) VALUES
(1,'Sales',1),
(2,'Repair Tech',1),
(3,'Trainer',1),
(4,'Instructor',1),
(5,'Manager',2);

------------------------------------------------
-- EMPLOYEES
------------------------------------------------
-- First insert one guaranteed Manager for triggers
INSERT OR IGNORE INTO Employee(employeeId, storeId, roleId, firstName, lastName, hireDate, hourlyRate, isActive)
VALUES (1, NULL, 5, 'Alice', 'Manager', datetime('now'), 25.0, 1);

-- Insert 20 more employees (roles randomly assigned)
WITH RECURSIVE counter(x) AS (
    SELECT 2
    UNION ALL
    SELECT x+1 FROM counter WHERE x < 21
)
INSERT INTO Employee(employeeId, storeId, roleId, firstName, lastName, hireDate, hourlyRate, isActive)
SELECT
x,
(ABS(RANDOM())%2)+1,        -- storeId (placeholder, will fix later)
(ABS(RANDOM())%5)+1,        -- roleId 1-5
'EmpFirst'||x,
'EmpLast'||x,
DATE('now','-'||(ABS(RANDOM())%1000)||' days'),
15 + (ABS(RANDOM())%20),
1
FROM counter;

------------------------------------------------
-- STOREFRONTS
------------------------------------------------
-- Assign the guaranteed Manager (employeeId=1) to both storefronts
INSERT OR IGNORE INTO Storefront(storefrontId, managerId, storeAddress, phoneNumber) VALUES
(1,1,'123 Main St','5551111111'),
(2,1,'456 Market St','5552222222');

------------------------------------------------
-- Update Employee.storeId for non-manager employees to match storefronts
UPDATE Employee
SET storeId = (ABS(RANDOM())%2)+1
WHERE employeeId != 1;

------------------------------------------------
-- CUSTOMERS (200)
------------------------------------------------
WITH RECURSIVE counter(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM counter WHERE x < 200
)
INSERT INTO Customer(customerId, creationDate)
SELECT x, DATE('now','-'||(ABS(RANDOM())%1000)||' days')
FROM counter;

------------------------------------------------
-- CUSTOMER NAMES & EMAILS
------------------------------------------------
INSERT INTO CustomerName(customerId, firstName, lastName)
SELECT customerId, 'First'||customerId, 'Last'||customerId FROM Customer;

INSERT INTO CustomerEmail(customerId, emailAddress)
SELECT customerId, 'customer'||customerId||'@email.com' FROM Customer;

------------------------------------------------
-- MEMBERSHIPS (3)
------------------------------------------------
INSERT OR IGNORE INTO Membership(membershipId, membershipName) VALUES
(1,'Basic'),(2,'Premium'),(3,'VIP');

-- CUSTOMER MEMBERSHIPS (ensure at least one active per customer)
INSERT INTO CustomerMembership(membershipId, customerId, isActive)
SELECT ((ABS(RANDOM())%3)+1), customerId, 1
FROM Customer;

------------------------------------------------
-- PRODUCTS (50)
------------------------------------------------
WITH RECURSIVE counter(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM counter WHERE x < 50
)
INSERT INTO RetailProduct(productSKU,name,brand,category,standardPrice,taxStatus,activeStatus)
SELECT
x,
'Product'||x,
'Brand'||(x%5),
'Category'||(x%4),
10 + (ABS(RANDOM())%90),
'Non-exempt',
'Active'
FROM counter;

------------------------------------------------
-- RETAIL SALES (1000)
------------------------------------------------
WITH RECURSIVE counter(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM counter WHERE x < 1000
)
INSERT INTO RetailSale(saleId, saleDate, taxAmount, subtotalAmount, customerId, storefrontId, employeeId)
SELECT
x,
DATE('now','-'||(ABS(RANDOM())%365)||' days'),
1,
10,
(ABS(RANDOM())%200)+1,      -- must match a valid customerId
(ABS(RANDOM())%2)+1,        -- must match a valid storefrontId
(ABS(RANDOM())%21)+1        -- must match a valid employeeId
FROM counter;

------------------------------------------------
-- PRODUCT SALES (1000)
------------------------------------------------
-- generate combos and limit to 1000
WITH RECURSIVE
  sale_counter(saleId) AS (
    SELECT 1
    UNION ALL
    SELECT saleId+1 FROM sale_counter WHERE saleId < 1000
  ),
  product_counter(productSKU) AS (
    SELECT 1
    UNION ALL
    SELECT productSKU+1 FROM product_counter WHERE productSKU < 50
  ),
  combos AS (
    SELECT saleId, productSKU
    FROM sale_counter
    CROSS JOIN product_counter
  )
INSERT INTO ProductSale (saleId, productSKU, quantity)
SELECT saleId, productSKU, (ABS(RANDOM())%3)+1
FROM combos
LIMIT 1000;

------------------------------------------------
-- RENTAL MODELS
------------------------------------------------
INSERT OR IGNORE INTO RentalModel(modelId, rentalType) VALUES
(1,'Bike'),(2,'Scooter'),(3,'Kayak');

------------------------------------------------
-- RENTAL UNITS (100)
------------------------------------------------
WITH RECURSIVE counter(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM counter WHERE x < 100
)
INSERT INTO RentalUnit(unitId,name,conditionStatus,purchaseDate,modelId,storefrontId)
SELECT
x,
'Unit'||x,
'Good',
DATE('now','-'||(ABS(RANDOM())%1000)||' days'),
(ABS(RANDOM())%3)+1,
(ABS(RANDOM())%2)+1
FROM counter;

------------------------------------------------
-- RENTAL CONTRACTS (200)
------------------------------------------------
WITH RECURSIVE counter(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM counter WHERE x < 200
)
INSERT INTO RentalContract(contractId,startDate,expectedReturnDate,depositAmount,lateFee,isActive,customerId,employeeId,storeId)
SELECT
x,
DATE('now','-'||(ABS(RANDOM())%100)||' days'),
DATE('now','+'||(ABS(RANDOM())%10)||' days'),
50,
10,
1,                       -- active contract must be 1 for trigger checks
(ABS(RANDOM())%200)+1,
(ABS(RANDOM())%21)+1,
(ABS(RANDOM())%2)+1
FROM counter;

------------------------------------------------
-- CONTRACT UNITS (200)
------------------------------------------------
-- Loop-safe approach using a CTE
WITH active_contracts AS (
    SELECT rc.contractId, ru.unitId
    FROM RentalContract rc
    JOIN RentalUnit ru
        ON ru.storefrontId = rc.storeId
    WHERE rc.isActive = 1
    ORDER BY RANDOM()
)
SELECT contractId, unitId
FROM active_contracts
LIMIT 200;

------------------------------------------------
-- TICKETS (200)
------------------------------------------------
WITH RECURSIVE counter(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM counter WHERE x < 200
)
INSERT INTO Ticket(ticketId,priority,status,labor,billAmount,unitId)
SELECT
x,
'Medium',
'Open',
'Repair',
50,
(ABS(RANDOM())%100)+1
FROM counter;

------------------------------------------------
-- TRAINING COURSES (2)
------------------------------------------------
INSERT OR IGNORE INTO TrainingCourse(courseId, courseName, description) VALUES
(1,'Safety','desc'),
(2,'Maintenance','desc');

------------------------------------------------
-- COURSE SESSIONS (20)
------------------------------------------------
WITH RECURSIVE counter(x) AS (
    SELECT 1
    UNION ALL
    SELECT x+1 FROM counter WHERE x < 20
)
INSERT INTO CourseSession(sessionId, capacity, courseId)
SELECT
x,
20,
(ABS(RANDOM())%2)+1
FROM counter;

------------------------------------------------
-- SESSION ENROLLMENTS (200)
------------------------------------------------
WITH RECURSIVE
  session_ids(sessionId) AS (
    SELECT 1
    UNION ALL
    SELECT sessionId+1 FROM session_ids WHERE sessionId < 20
  ),
  customer_ids(customerId) AS (
    SELECT 1
    UNION ALL
    SELECT customerId+1 FROM customer_ids WHERE customerId < 200
  ),
  combos AS (
    SELECT sessionId, customerId
    FROM session_ids
    CROSS JOIN customer_ids
  )
INSERT INTO SessionEnroll(sessionId, customerId)
SELECT sessionId, customerId
FROM combos
ORDER BY RANDOM()
LIMIT 200;

ANALYZE;

PRAGMA foreign_keys = ON;

-- delete shit in case of problem
PRAGMA foreign_keys = OFF;

-- Section 1: Delete associative & dependent tables first
DELETE FROM ProductSale;
DELETE FROM SaleDiscount;
DELETE FROM ProductDiscount;
DELETE FROM ProductVendor;
DELETE FROM ProductStore;
DELETE FROM CustomerMembership;
DELETE FROM SessionEnroll;
DELETE FROM SessionInstructor;
DELETE FROM ContractUnit;
DELETE FROM TicketPart;
DELETE FROM UnitPart;
DELETE FROM RentalModel;

-- Section 2: Delete main entity tables
DELETE FROM RetailSale;
DELETE FROM Ticket;
DELETE FROM ContractExtension;
DELETE FROM RentalContract;
DELETE FROM RentalUnit;
DELETE FROM CustomerEmail;
DELETE FROM CustomerPhone;
DELETE FROM CustomerAddress;
DELETE FROM CustomerName;
DELETE FROM Customer;
DELETE FROM CourseSession;
DELETE FROM TrainingCourse;
DELETE FROM RetailProduct;
DELETE FROM Variant;
DELETE FROM Vendor;
DELETE FROM Membership;
DELETE FROM Employee;
DELETE FROM Storeshift;
DELETE FROM Storefront;
DELETE FROM Role;
DELETE FROM TransferHistory;
DELETE FROM Part;
DELETE FROM AuditLog;

PRAGMA foreign_keys = ON;