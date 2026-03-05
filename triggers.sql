/*
 REQUIRED TRIGGERS
 1. DONE + update protection
 2. DONE
 3.
 4.
 5.

 NOT REQUIRED TRIGGERS
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

CREATE TRIGGER membership_validation_check
BEFORE INSERT ON ProductSale
FOR EACH ROW
WHEN New.customerId IS NOT NULL -- check if a customer is assigned
    BEGIN
         SELECT
         CASE 
         WHEN NOT EXISTS( --prevents a situation where a customer might have two active memberships
         SELECT 1
         FROM CustomerMembership
         WHERE customerId = NEW.customerId
         AND isActive = 1
         )
    THEN RAISE(ABORT, "No active membership could be found for this customer");
    END;
END;




 
