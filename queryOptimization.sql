/*
 Customers with active memberships but no purchase in 60 days

 BEFORE OPTIMIZATION
 */
EXPLAIN QUERY PLAN
SELECT
    c.customerId,
    c.creationDate
FROM Customer c
JOIN CustomerMembership cm
    ON c.customerId = cm.customerId
WHERE cm.isActive = 1
AND NOT EXISTS (
    SELECT 1
    FROM RetailSale rs
    WHERE rs.customerId = c.customerId
    AND rs.saleDate >= DATE('now', '-60 days')
);

/*
 PLAN RETURNS:
         SCAN c
         CORRELATED SCALAR SUBQUERY 1
         SEARCH rs USING INDEX idx_retailsale_customer (customerId=?)
         SEARCH cm USING INDEX sqlite_autoindex_CustomerMembership_1 (customerId=?)

 AFTER OPTIMIZATION
 */
CREATE INDEX idx_customermembership_isactive_customerid ON CustomerMembership(isActive, customerId);
CREATE INDEX idx_retailsale_customer_date ON RetailSale(customerId, saleDate);

EXPLAIN QUERY PLAN
SELECT -- COUNT(*) for evaluation
    c.customerId,
    c.creationDate
FROM Customer c
JOIN CustomerMembership cm
    ON c.customerId = cm.customerId
WHERE cm.isActive = 1
AND NOT EXISTS (
    SELECT 1
    FROM RetailSale rs
    WHERE rs.customerId = c.customerId
    AND rs.saleDate >= DATE('now', '-60 days')
);
/*
 PLAN RETURNS:
         SEARCH cm USING COVERING INDEX idx_customermembership_isactive_customerid (isActive=?)
         SEARCH c USING INTEGER PRIMARY KEY (rowid=?)
         CORRELATED SCALAR SUBQUERY 1
         SEARCH rs USING COVERING INDEX idx_retailsale_customer_date (customerId=? AND saleDate>?)

 USES NEW INDEX idx_customermembership_isactive_customerid AND idx_retailsale_customer_date TO SEARCH MORE EFFICIENTLY
 */

 /*
Active rentals by store with expected return date

 BEFORE OPTIMIZATION
 */
EXPLAIN QUERY PLAN
SELECT
    r.name AS unitName,
    rc.storeId,
    rc.expectedReturnDate
FROM RentalContract rc
JOIN ContractUnit cu ON rc.contractId = cu.contractId
JOIN RentalUnit r ON r.unitId = cu.unitId
WHERE rc.isActive = 1
ORDER BY rc.storeId;

/*
PLAN RETURNS:
    SCAN cu
    SEARCH rc USING INTEGER PRIMARY KEY (rowid=?)
    SEARCH r USING INTEGER PRIMARY KEY (rowid=?)
    USE TEMP B-TREE FOR ORDER BY


 AFTER OPTIMIZATION
 */

DROP INDEX IF EXISTS idx_rentalcontract_isactive_storeid;
CREATE INDEX idx_rentalcontract_isactive_storeid ON RentalContract(isActive, storeId);

EXPLAIN QUERY PLAN
SELECT COUNT(*),
    r.name AS unitName,
    rc.storeId,
    rc.expectedReturnDate
FROM RentalContract rc
JOIN ContractUnit cu ON rc.contractId = cu.contractId
JOIN RentalUnit r ON r.unitId = cu.unitId
WHERE rc.isActive = 1
ORDER BY rc.storeId;

/*
 PLAN RETURNS:
    SEARCH rc USING INDEX idx_rentalcontract_isactive_storeid (isActive=?)
    SEARCH cu USING COVERING INDEX sqlite_autoindex_ContractUnit_1 (contractId=?)
    SEARCH r USING INTEGER PRIMARY KEY (rowid=?)

USING COMPOSITE INDEX, idx_rentalcontract_isactive_storeid, IT IS MORE EFFECTIVE VIA NO TEMP DATA

 */


/*
 Top customers by total spending in the last 90 days

 BEFORE OPTIMIZATION
*/

EXPLAIN QUERY PLAN
SELECT
    c.customerId,
    cn.firstName,
    cn.lastName,
    SUM(rs.subtotalAmount + rs.taxAmount) AS totalSpending
FROM Customer c
JOIN CustomerName cn ON c.customerId = cn.customerId
JOIN RetailSale rs ON c.customerId = rs.customerId
WHERE rs.saleDate >= DATE('now', '-90 days')
GROUP BY c.customerId, cn.firstName, cn.lastName
ORDER BY totalSpending DESC
LIMIT 10;

/*
 PLAN RETURNS:
      SCAN c
      SEARCH cn USING COVERING INDEX sqlite_autoindex_CustomerName_1 (customerId=?)
      SEARCH rs USING INDEX idx_retailsale_customer_date (customerId=? AND saleDate>?)
      USE TEMP B-TREE FOR ORDER BY
 AFTER OPTIMIZATION
 */

DROP INDEX IF EXISTS idx_retailsale_covering_opt;
CREATE INDEX idx_retailsale_covering_opt ON RetailSale(saleDate, customerId, subtotalAmount, taxAmount);

EXPLAIN QUERY PLAN
SELECT
    c.customerId,
    cn.firstName,
    cn.lastName,
    SUM(rs.subtotalAmount + rs.taxAmount) AS totalSpending
FROM RetailSale rs INDEXED BY idx_retailsale_covering_opt
JOIN Customer c ON rs.customerId = c.customerId
JOIN CustomerName cn ON c.customerId = cn.customerId
WHERE rs.saleDate >= DATE('now', '-90 days')
GROUP BY c.customerId, cn.firstName, cn.lastName
ORDER BY totalSpending DESC
LIMIT 10;

/*
 PLAN RETURNS:
    SEARCH rs USING COVERING INDEX idx_retailsale_covering_opt (saleDate>?)
    SEARCH c USING INTEGER PRIMARY KEY (rowid=?)
    SEARCH cn USING COVERING INDEX sqlite_autoindex_CustomerName_1 (customerId=?)
    USE TEMP B-TREE FOR GROUP BY
    USE TEMP B-TREE FOR ORDER BY


USING COMPOSITE INDEX, idx_retailsale_covering_opt, it is more effective as it eliminates a full scan on customer table

 */



 /*
Instructors ranked by total enrollments

 BEFORE OPTIMIZATION
 */

EXPLAIN QUERY PLAN
SELECT
    e.firstName,
    e.lastName,
    COUNT(se.customerId) AS Enrollment
FROM Employee e
JOIN SessionInstructor si ON e.employeeId = si.instructorId
JOIN SessionEnroll se ON se.sessionId = si.sessionId
GROUP BY si.instructorId
HAVING COUNT(se.customerId) > 0
ORDER BY Enrollment DESC;

/*
PLAN RETURNS:
    SCAN si USING INDEX idx_sessioninstructor_instructor
    SEARCH e USING INTEGER PRIMARY KEY (rowid=?)
    BLOOM FILTER ON se (sessionId=?)
    SEARCH se USING AUTOMATIC COVERING INDEX (sessionId=?)
    USE TEMP B-TREE FOR ORDER BY


 AFTER OPTIMIZATION
 */

DROP INDEX IF EXISTS idx_sessionenroll_session;
CREATE INDEX idx_sessionenroll_session ON SessionEnroll(sessionId);

EXPLAIN QUERY PLAN
SELECT
    e.firstName,
    e.lastName,
    COUNT(se.customerId) AS Enrollment
FROM Employee e
JOIN SessionInstructor si ON e.employeeId = si.instructorId
JOIN SessionEnroll se ON se.sessionId = si.sessionId
GROUP BY si.instructorId
HAVING COUNT(se.customerId) > 0
ORDER BY Enrollment DESC;


/*
 PLAN RETURNS:
    SCAN si USING INDEX idx_sessioninstructor_instructor
    SEARCH e USING INTEGER PRIMARY KEY (rowid=?)
    SEARCH se USING INDEX idx_sessionenroll_session (sessionId=?)
    USE TEMP B-TREE FOR ORDER BY

USING INDEX idx_sessionenroll_session AND HAVING IN GROUP BY, BLOOM FILTER IS REMOVED AND OVERALL MORE EFFECTIVE

 */

/*
 !! CUSTOM PROMPT !! Top Customers by store with more than 5 items purchased

 BEFORE OPTIMIZATION
 */
EXPLAIN QUERY PLAN
SELECT
    rs.storefrontId,
    cn.customerId,
    cn.firstName,
    cn.lastName,
    SUM(ps.quantity) AS ItemsPurchased
FROM CustomerName cn
JOIN RetailSale rs ON rs.customerId = cn.customerId
JOIN ProductSale ps ON ps.saleId = rs.saleId
GROUP BY storefrontId, cn.customerId
HAVING ItemsPurchased > 5
ORDER BY rs.storefrontId, ItemsPurchased DESC;

/*
 PLAN RETURNS:
    SCAN ps
    SEARCH rs USING INTEGER PRIMARY KEY (rowid=?)
    SEARCH cn USING COVERING INDEX sqlite_autoindex_CustomerName_1 (customerId=?)
    USE TEMP B-TREE FOR GROUP BY
    USE TEMP B-TREE FOR ORDER BY

 By adding indexes we should be able to remove the scan and reduce B-tree usage

AFTER OPTIMIZATION
 */

CREATE INDEX idx_productsale_saleid ON ProductSale(saleId);
CREATE INDEX idx_retailsale_store_customer_sale ON RetailSale(storefrontId, customerId, saleId);

EXPLAIN QUERY PLAN
WITH ps_sum AS (
    SELECT saleId, SUM(quantity) as totalQuantity
    FROM ProductSale
    GROUP BY saleId
)

SELECT
    rs.storefrontId,
    cn.customerId,
    cn.firstName,
    cn.lastName,
    SUM(ps_sum.totalQuantity) AS ItemsPurchased
FROM CustomerName cn
JOIN RetailSale rs ON rs.customerId = cn.customerId
JOIN ps_sum ON ps_sum.saleId = rs.saleId
GROUP BY rs.storefrontId, cn.customerId
HAVING SUM(ps_sum.totalQuantity) > 5
ORDER BY rs.storefrontId, ItemsPurchased DESC;