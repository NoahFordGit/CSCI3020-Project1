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
    SCAN rc USING INDEX idx_rentalcontract_store
    SEARCH cu USING COVERING INDEX sqlite_autoindex_ContractUnit_1 (contractId=?)
    SEARCH r USING INTEGER PRIMARY KEY (rowid=?)

 AFTER OPTIMIZATION
 */
-- Work in progress *NOT FINAL*
CREATE INDEX idx_rentalcontract_storeid_isactive ON RentalContract(storeId, isActive);

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
Instructors ranked by total enrollments

 BEFORE OPTIMIZATION
 */