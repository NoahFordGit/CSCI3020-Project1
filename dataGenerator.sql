PRAGMA foreign_keys = OFF;

------------------------------------------------
-- ROLES
------------------------------------------------
INSERT INTO Role VALUES
(1,'Sales',1),
(2,'Repair Tech',1),
(3,'Trainer',1),
(4,'Instructor',1),
(5,'Manager',2);

------------------------------------------------
-- STOREFRONTS
------------------------------------------------
INSERT INTO Storefront VALUES
(1,1,'123 Main St','5551111111'),
(2,1,'456 Market St','5552222222');

------------------------------------------------
-- EMPLOYEES
------------------------------------------------
WITH RECURSIVE counter(x) AS (
SELECT 1
UNION ALL
SELECT x+1 FROM counter LIMIT 20
)
INSERT INTO Employee
(employeeId,storeId,roleId,firstName,lastName,hireDate,hourlyRate,isActive)
SELECT
x,
(ABS(RANDOM())%2)+1,
(ABS(RANDOM())%5)+1,
'EmpFirst'||x,
'EmpLast'||x,
DATE('now','-'||(ABS(RANDOM())%1000)||' days'),
15 + (ABS(RANDOM())%20),
1
FROM counter;

------------------------------------------------
-- CUSTOMERS (200)
------------------------------------------------
WITH RECURSIVE counter(x) AS (
SELECT 1
UNION ALL
SELECT x+1 FROM counter LIMIT 200
)
INSERT INTO Customer(customerId,creationDate)
SELECT x, DATE('now','-'||(ABS(RANDOM())%1000)||' days')
FROM counter;

------------------------------------------------
-- CUSTOMER NAMES
------------------------------------------------
INSERT INTO CustomerName
SELECT
customerId,
'First'||customerId,
'Last'||customerId
FROM Customer;

------------------------------------------------
-- CUSTOMER EMAIL
------------------------------------------------
INSERT INTO CustomerEmail
SELECT
customerId,
'customer'||customerId||'@email.com'
FROM Customer;

------------------------------------------------
-- MEMBERSHIPS
------------------------------------------------
INSERT INTO Membership VALUES
(1,'Basic'),
(2,'Premium'),
(3,'VIP');

------------------------------------------------
-- CUSTOMER MEMBERSHIPS (200)
------------------------------------------------
INSERT INTO CustomerMembership
SELECT
(ABS(RANDOM())%3)+1,
customerId,
1
FROM Customer;

------------------------------------------------
-- PRODUCTS
------------------------------------------------
WITH RECURSIVE counter(x) AS (
SELECT 1
UNION ALL
SELECT x+1 FROM counter LIMIT 50
)
INSERT INTO RetailProduct
(productSKU,name,brand,category,standardPrice,taxStatus,activeStatus)
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
SELECT x+1 FROM counter LIMIT 1000
)
INSERT INTO RetailSale
(saleId,saleDate,taxAmount,subtotalAmount,customerId,storefrontId,employeeId)
SELECT
x,
DATE('now','-'||(ABS(RANDOM())%365)||' days'),
1,
10,
(ABS(RANDOM())%200)+1,
(ABS(RANDOM())%2)+1,
(ABS(RANDOM())%20)+1
FROM counter;

------------------------------------------------
-- PRODUCT SALES (1000)
------------------------------------------------
-- Generate 1000 unique ProductSale entries
WITH RECURSIVE
  sale_counter(saleId) AS (
    SELECT 1
    UNION ALL
    SELECT saleId + 1 FROM sale_counter WHERE saleId < 1000
  ),
  product_counter(productSKU) AS (
    SELECT 1
    UNION ALL
    SELECT productSKU + 1 FROM product_counter WHERE productSKU < 50
  ),
  combos AS (
    SELECT saleId, productSKU
    FROM sale_counter
    JOIN product_counter
  )
INSERT INTO ProductSale (saleId, productSKU, quantity)
SELECT
  saleId,
  productSKU,
  (ABS(RANDOM()) % 3) + 1
FROM combos
LIMIT 1000; -- now LIMIT works here

------------------------------------------------
-- RENTAL MODELS
------------------------------------------------
INSERT INTO RentalModel VALUES
(1,'Bike'),
(2,'Scooter'),
(3,'Kayak');

------------------------------------------------
-- RENTAL UNITS
------------------------------------------------
WITH RECURSIVE counter(x) AS (
SELECT 1
UNION ALL
SELECT x+1 FROM counter LIMIT 100
)
INSERT INTO RentalUnit
(unitId,name,conditionStatus,purchaseDate,modelId,storefrontId)
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
SELECT x+1 FROM counter LIMIT 200
)
INSERT INTO RentalContract
(contractId,startDate,expectedReturnDate,depositAmount,lateFee,isActive,customerId,employeeId,storeId)
SELECT
x,
DATE('now','-'||(ABS(RANDOM())%100)||' days'),
DATE('now','+'||(ABS(RANDOM())%10)||' days'),
50,
10,
0,
(ABS(RANDOM())%200)+1,
(ABS(RANDOM())%20)+1,
(ABS(RANDOM())%2)+1
FROM counter;

------------------------------------------------
-- CONTRACT UNITS (200)
------------------------------------------------
INSERT INTO ContractUnit
SELECT
contractId,
(ABS(RANDOM())%100)+1
FROM RentalContract;

------------------------------------------------
-- TICKETS (200)
------------------------------------------------
WITH RECURSIVE counter(x) AS (
SELECT 1
UNION ALL
SELECT x+1 FROM counter LIMIT 200
)
INSERT INTO Ticket
(ticketId,priority,status,labor,billAmount,unitId)
SELECT
x,
'Medium',
'Open',
'Repair',
50,
(ABS(RANDOM())%100)+1
FROM counter;

------------------------------------------------
-- COURSE SESSIONS (20)
------------------------------------------------
INSERT INTO TrainingCourse VALUES
(1,'Safety', 'desc'),
(2,'Maintenance', 'desc');

WITH RECURSIVE counter(x) AS (
SELECT 1
UNION ALL
SELECT x+1 FROM counter LIMIT 20
)
INSERT INTO CourseSession
(sessionId,capacity,courseId)
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
INSERT INTO SessionEnroll (sessionId, customerId)
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