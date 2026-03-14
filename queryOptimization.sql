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
 ** NEXT QUERY ** (please use this format for all our queries)

 BEFORE OPTIMIZATION
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
SELECT e.firstName,
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
Top 10 courses by enrollment numbers

 BEFORE OPTIMIZATION
*/

EXPLAIN QUERY PLAN
SELECT
    tc.courseName,
    tc.description,
    (
        SELECT COUNT(*)
        FROM SessionEnroll se
        JOIN CourseSession css ON css.sessionId = se.sessionId
        WHERE css.courseId = tc.courseId
        ) AS [Number of Enrolled]
FROM TrainingCourse tc
JOIN CourseSession cs ON cs.courseId = tc.courseId
JOIN SessionEnroll se ON se.sessionId = cs.sessionId
GROUP BY tc.courseId
ORDER BY "Number of Enrolled" DESC
LIMIT 10;

/*
PLAN RETURNS:
    SCAN se
    SEARCH cs USING INTEGER PRIMARY KEY (rowid=?)
    SEARCH tc USING INTEGER PRIMARY KEY (rowid=?)
    USE TEMP B-TREE FOR GROUP BY
    CORRELATED SCALAR SUBQUERY 1
    SCAN se
    SEARCH css USING COVERING INDEX idx_coursesession_course (courseId=? AND rowid=?)
    USE TEMP B-TREE FOR ORDER BY


 AFTER OPTIMIZATION
*/


EXPLAIN QUERY PLAN
SELECT
    tc.courseName,
    tc.description,
    COUNT(se.customerId) AS [Number of Enrolled]
FROM TrainingCourse tc
JOIN CourseSession cs ON cs.courseId = tc.courseId
JOIN SessionEnroll se ON se.sessionId = cs.sessionId
WHERE EXISTS (
    SELECT 1
    FROM CourseSession css
    WHERE css.sessionId = se.sessionId
        AND css.courseId = tc.courseId
)
GROUP BY tc.courseId
ORDER BY "Number of Enrolled" DESC
LIMIT 10;


/*
 PLAN RETURNS:
    SCAN se
    SEARCH cs USING INTEGER PRIMARY KEY (rowid=?)
    SEARCH tc USING INTEGER PRIMARY KEY (rowid=?)
    SEARCH css EXISTS USING COVERING INDEX idx_coursesession_course (courseId=? AND rowid=?)
    USE TEMP B-TREE FOR GROUP BY
    USE TEMP B-TREE FOR ORDER BY

BY REWORKING SUBQUERY, SCANS ARE REDUCED AND SEARCHES ARE FASTER

*/



/*
 Rental units with highest rental frequency

 BEFORE OPTIMIZATION
*/
EXPLAIN QUERY PLAN
SELECT
    ru.unitId,
    ru.name,
    ru.conditionStatus,
    ru.modelId,
    ru.storefrontId,
    COUNT(cu.unitId) AS rental_frequency
FROM RentalUnit ru
JOIN ContractUnit cu ON cu.unitId = ru.unitId
GROUP BY
    ru.unitId
ORDER BY rental_frequency DESC
LIMIT 10;

/*
 SCAN ru
 SEARCH cu USING COVERING INDEX idx_contractunit_unit (unitId=?)
 USE TEMP B-TREE FOR ORDER BY

 AFTER OPTIMIZATION
*/
EXPLAIN QUERY PLAN
WITH frequency AS (
    SELECT unitId, COUNT(unitId) AS rental_frequency
    FROM ContractUnit
    GROUP BY unitId
)
SELECT
    ru.unitId,
    ru.name,
    ru.conditionStatus,
    ru.modelId,
    ru.storefrontId,
    f.rental_frequency
FROM RentalUnit ru
JOIN frequency f ON f.unitId = ru.unitId
ORDER BY f.rental_frequency DESC
LIMIT 10;

/*
Employees who have brought more than $10,000 in total sales revenue

 BEFORE OPTIMIZATION
*/

EXPLAIN QUERY PLAN
SELECT
    e.firstName,
    e.lastName,
    SUM(rs.subtotalAmount) AS totalRevenueBrought
FROM Employee e
JOIN RetailSale rs ON e.employeeId = rs.employeeId
GROUP BY e.employeeId, e.firstName, e.lastName
HAVING SUM(rs.subtotalAmount) > 10000;

/*
 PLAN RETURNS:
        SCAN e
        SEARCH rs USING INDEX idx_retailsale_employee (employeeId=?)

  AFTER OPTIMIZATION
*/

DROP INDEX IF EXISTS idx_retailsale_employee_cover;
CREATE INDEX idx_retailsale_employee_cover ON RetailSale(employeeId, subtotalAmount);

EXPLAIN QUERY PLAN
SELECT
    e.firstName,
    e.lastName,
    SUM(rs.subtotalAmount) AS totalRevenueBrought
FROM Employee e
JOIN RetailSale rs ON e.employeeId = rs.employeeId
GROUP BY e.employeeId, e.firstName, e.lastName
HAVING SUM(rs.subtotalAmount) > 10000;

/*
PLAN RETURNS:
       SCAN e
       SEARCH rs USING COVERING INDEX idx_retailsale_employee_cover (employeeId=?)

By storing a copy of the subtotal directly alongside the employeeId inside the covering index, the query can efficiently sum the revenue and evaluate the having clause entirely in memory.  
*/

/*
 Commonly purchased product pairs

 BEFORE OPTIMIZATION
*/

EXPLAIN QUERY PLAN
SELECT
    rp1.name AS Prodoct1,
    rp2.name AS Product2,
    COUNT(*) AS pairCount
FROM ProductSale ps1
JOIN ProductSale ps2 ON ps1.saleId = ps2.saleId
    AND ps1. productSKU < ps2.productSKU
JOIN RetailProduct rp1 ON ps1.productSKU = rp1.productSKU
JOIN RetailProduct rp2 ON ps2.productSKU = rp2.productSKU
GROUP BY rp1.name, rp2.name
ORDER BY pairCount DESC
LIMIT 25;

/*
 PLAN RETURNS:
        SCAN rp1
        SEARCH ps1 USING INDEX idx_productsale_product (productSKU=?)
        SEARCH ps2 USING COVERING INDEX sqlite_autoindex_ProductSale_1 (saleId=? AND productSKU>?)
        SEARCH rp2 USING INTEGER PRIMARY KEY (rowid=?)
        USE TEMP B-TREE FOR GROUP BY
        USE TEMP B-TREE FOR ORDER BY

  AFTER OPTIMIZATION
*/
DROP INDEX IF EXISTS idx_reverse_productsale_covering;
CREATE INDEX idx_reverse_productsale_covering ON ProductSale(productSKU, saleId);

EXPLAIN QUERY PLAN
WITH TopPairs AS (
    SELECT
         ps1.productSKU AS sku1,
         ps2.productSKU AS sku2,
         COUNT(*) AS pairCount
    FROM ProductSale ps1
           JOIN ProductSale ps2 ON ps1.saleId = ps2.saleId
    AND ps1.productSKU < ps2.productSKU
    GROUP BY ps1.productSKU, ps2.productSKU
    ORDER BY pairCount DESC
    LIMIT 25
)
SELECT
    rp1.name AS Product1,
    rp2.name AS Product2,
    tp.pairCount
FROM TopPairs tp
JOIN RetailProduct rp1 ON tp.sku1 = rp1.productSKU
JOIN RetailProduct rp2 ON tp.sku2 = rp2.productSKU
ORDER BY tp.pairCount DESC;

SELECT COUNT(*)
FROM (
WITH TopPairs AS (
    SELECT
         ps1.productSKU AS sku1,
         ps2.productSKU AS sku2,
         COUNT(*) AS pairCount
    FROM ProductSale ps1
           JOIN ProductSale ps2 ON ps1.saleId = ps2.saleId
    AND ps1.productSKU < ps2.productSKU
    GROUP BY ps1.productSKU, ps2.productSKU
    ORDER BY pairCount DESC
    LIMIT 25
)
SELECT
    rp1.name AS Product1,
    rp2.name AS Product2,
    tp.pairCount
FROM TopPairs tp
JOIN RetailProduct rp1 ON tp.sku1 = rp1.productSKU
JOIN RetailProduct rp2 ON tp.sku2 = rp2.productSKU
ORDER BY tp.pairCount DESC
);

/*
PLAN RETURNS:
       CO-ROUTINE TopPairs
       SCAN ps1 USING COVERING INDEX idx_reverse_productsale_covering
       SEARCH ps2 USING COVERING INDEX sqlite_autoindex_ProductSale_1 (saleId=? AND productSKU>?)
       USE TEMP B-TREE FOR GROUP BY
       USE TEMP B-TREE FOR ORDER BY
       SCAN tp
       SEARCH rp1 USING INTEGER PRIMARY KEY (rowid=?)
       SEARCH rp2 USING INTEGER PRIMARY KEY (rowid=?)

With a CTE late row lookup. This will isolate the self-join inside the CTE, group them by only integer SKU, count them, sort them, and apply the limit clause. 
which saves the database from processing names for thousands of those unpopular and only sold together once pairs.  
*/
