/*
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!!!!!!!!!!! THIS IS NO LONGER IN ORDER ( USE CTRL + F TO LOCATE TABLES) !!!!!!!!!!!!!
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    GROUP ONE - NOAH:
    Storefront          X T
    Employee            X
    Role                X
    Store_Shift         X T
    Training_Course     X
    Course_Session      X
    Session_Instructor  X T
    Session_Enroll      X

    GROUP TWO - OLIVIA
    Customer            X
    Customer_Name       X
    Customer_Phone      X
    Customer_Email      X
    Customer_Address    X
    Membership          X
    Customer_Membership X T
    Retail_Product      X
    Product_Store       X
    Variant             X
    Vendor              X
    Product_Vendor      X
    Retail_Sale         X T
    Product_Sale        X T
    Product_Return      X
    Discount            X
    Product_Discount    X
    Sale_Discount       X


    GROUP THREE - VANAY
    Rental_Unit         X
    Rental_Model        X
    Transfer_History    X T
    Rental_Contract     X
    Contract_Unit       X
    Contract_Extension  X
    Ticket              X
    Part                X
    Unit_Part           X
    Ticket_Part         X
 */
PRAGMA foreign_keys = ON;

-- Role table
DROP TABLE IF EXISTS Role;
CREATE TABLE Role (
    roleId INTEGER PRIMARY KEY,
    roleTitle TEXT NOT NULL UNIQUE CHECK (roleTitle IN ('Sales', 'Repair Tech', 'Trainer', 'Instructor', 'Manager')),
    permissionLevel INTEGER NOT NULL
);

-- Storefront table
DROP TABLE IF EXISTS Storefront;
CREATE TABLE Storefront (
    storefrontId INTEGER PRIMARY KEY,
    managerId INTEGER NOT NULL, -- REQUIRES TRIGGER TO CHECK FOR MANAGER ROLE ON EMPLOYEE
    storeAddress UNIQUE NOT NULL,
    phoneNumber UNIQUE NOT NULL,
    FOREIGN KEY (managerId)
        REFERENCES Employee(employeeId)
        DEFERRABLE INITIALLY DEFERRED -- avoids circular dependency and makes it not break
);
CREATE INDEX idx_storefront_employee ON Storefront(managerId);

-- Employee table
DROP TABLE IF EXISTS Employee;
CREATE TABLE Employee (
    employeeId INTEGER PRIMARY KEY,
    storeId INTEGER,
    roleId INTEGER,
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    hireDate DATETIME NOT NULL,
    hourlyRate REAL NOT NULL,
    isActive INTEGER NOT NULL DEFAULT 1 CHECK (isActive IN (0, 1)),
    FOREIGN KEY (roleId) REFERENCES Role(roleId),
    FOREIGN KEY (storeId)
        REFERENCES Storefront(storefrontId)
        DEFERRABLE INITIALLY DEFERRED -- avoids circular dependency and makes it not break
);
CREATE INDEX idx_employee_store ON Employee(storeId);
CREATE INDEX idx_employee_role ON Employee(roleId);
CREATE INDEX idx_employee_hiredate ON Employee(hireDate);
CREATE INDEX idx_employee_hourlyrate ON Employee(hourlyRate);

-- Storeshift table
DROP TABLE IF EXISTS Storeshift;
CREATE TABLE Storeshift (
    shiftId INTEGER PRIMARY KEY, -- TRIGGER TO MAKE SURE THERE IS A MANAGER A IS WORKING AT ALL TIMES
    employeeId INTEGER NOT NULL,
    storeId INTEGER NOT NULL,
    shiftStart DATETIME NOT NULL,
    shiftEnd DATETIME NOT NULL,
    FOREIGN KEY (employeeId)
        REFERENCES Employee(employeeId)
        ON DELETE CASCADE,
    FOREIGN KEY (storeId)
        REFERENCES Storefront(storefrontId)
        ON DELETE CASCADE
);
CREATE INDEX idx_storeshift_employee ON Storeshift(employeeId);
CREATE INDEX idx_storeshift_store ON Storeshift(storeId);

-- SECTION TWO - OS
-- Customer table
DROP TABLE IF EXISTS Customer;
CREATE TABLE Customer (
    customerId INTEGER PRIMARY KEY,
    creationDate DATETIME NOT NULL
);
CREATE INDEX idx_customer_creationdate ON Customer(creationDate);

-- CustomerName Table (weak)
DROP TABLE IF EXISTS CustomerName;
CREATE TABLE CustomerName (
    customerId INTEGER NOT NULL,
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    PRIMARY KEY(customerId, firstName, lastName),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
        ON DELETE CASCADE
);
CREATE INDEX idx_customername_firstname ON CustomerName(firstName);
CREATE INDEX idx_customername_lastname ON CustomerName(lastName);

-- CustomerPhone table (weak)
DROP TABLE IF EXISTS CustomerPhone;
CREATE TABLE CustomerPhone(
    customerId INTEGER NOT NULL,
    phoneNumber TEXT NOT NULL,
    PRIMARY KEY(customerId, phoneNumber),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
        ON DELETE CASCADE
);

-- CustomerEmail table (weak)
DROP TABLE IF EXISTS CustomerEmail;
CREATE TABLE CustomerEmail (
    customerId INTEGER NOT NULL,
    emailAddress TEXT NOT NULL,
    PRIMARY KEY(customerId, emailAddress),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
        ON DELETE CASCADE
);
CREATE INDEX idx_customeremail_email ON CustomerEmail(emailAddress);

-- CustomerAddress table (weak)
DROP TABLE IF EXISTS CustomerAddress;
CREATE TABLE CustomerAddress (
    addressId INTEGER PRIMARY KEY,
    customerId INTEGER NOT NULL,
    zipCode TEXT NOT NULL,
    addressLine1 TEXT NOT NULL,
    addressLine2 TEXT DEFAULT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    country TEXT NOT NULL,
    isPreferred INTEGER NOT NULL DEFAULT 0 CHECK (isPreferred IN (0, 1)),

    UNIQUE(customerId, zipCode, addressLine1, addressLine2, city, state, country),

    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
        ON DELETE CASCADE
);
CREATE INDEX idx_customeraddress_zipcode ON CustomerAddress(zipCode);
CREATE UNIQUE INDEX idx_preferred_address ON CustomerAddress(customerId)
    WHERE isPreferred = 1; -- a customer may have ONE preferred address

-- TrainingCourse table
DROP TABLE IF EXISTS TrainingCourse;
CREATE TABLE TrainingCourse (
    courseId INTEGER PRIMARY KEY,
    courseName TEXT NOT NULL,
    description TEXT
);

-- CourseSession table
DROP TABLE IF EXISTS CourseSession;
CREATE TABLE CourseSession (
    sessionId INTEGER PRIMARY KEY,
    capacity INTEGER NOT NULL,
    courseId INTEGER NOT NULL,
    FOREIGN KEY(courseId)
        REFERENCES TrainingCourse(courseId)
        ON DELETE CASCADE
);
CREATE INDEX idx_coursesession_course ON CourseSession(courseId);

-- SessionInstructor table (associative)
DROP TABLE IF EXISTS SessionInstructor;
CREATE TABLE SessionInstructor (
    sessionId INTEGER NOT NULL,
    instructorId INTEGER NOT NULL, -- TRIGGER THAT EMPLOYEE MUST HAVE INSTRUCTOR ROLE
    PRIMARY KEY(sessionId, instructorId),
    FOREIGN KEY(sessionId)
        REFERENCES CourseSession(sessionId)
        ON DELETE CASCADE,
    FOREIGN KEY(instructorId)
        REFERENCES Employee(employeeId)
        ON DELETE CASCADE
);

-- Session Enroll Table
DROP TABLE IF EXISTS SessionEnroll;
CREATE TABLE SessionEnroll (
    sessionId INTEGER NOT NULL,
    customerId INTEGER NOT NULL,
    PRIMARY KEY(customerId, sessionId),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
        ON DELETE CASCADE,
    FOREIGN KEY(sessionId)
        REFERENCES CourseSession(sessionId)
        ON DELETE CASCADE
);

CREATE INDEX idx_sessioninstructor_instructor ON SessionInstructor(instructorId);

-- Membership table
DROP TABLE IF EXISTS Membership;
CREATE TABLE Membership (
    membershipId INTEGER PRIMARY KEY,
    membershipName TEXT NOT NULL
);
CREATE INDEX idx_membership_name ON Membership(membershipName);

-- CustomerMembership table (associative)
DROP TABLE IF EXISTS CustomerMembership;
CREATE TABLE CustomerMembership (
    membershipId INTEGER,
    customerId INTEGER,
    isActive INTEGER NOT NULL DEFAULT 0 CHECK (isActive IN (0, 1)), -- TRIGGER THAT ONE AND ONLY ONE MEMBERSHIP CAN BE ACTIVE
    PRIMARY KEY(customerId, membershipId),
    FOREIGN KEY(membershipId)
        REFERENCES Membership(membershipId)
        ON DELETE CASCADE,
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
        ON DELETE CASCADE
);
CREATE INDEX idx_customermembership_membership ON CustomerMembership(membershipId);

-- RetailProduct table
DROP TABLE IF EXISTS RetailProduct;
CREATE TABLE RetailProduct (
    productSKU INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    brand TEXT NOT NULL,
    category TEXT NOT NULL,
    standardPrice NUMERIC NOT NULL CHECK(standardPrice > 0),
    taxStatus TEXT NOT NULL CHECK(taxStatus IN ('Exempt', 'Non-exempt')),
    activeStatus TEXT NOT NULL CHECK(activeStatus IN ('Active', 'Inactive'))
);
-- Index(es) for RetailProduct
    CREATE INDEX idx_retailproduct_brand ON RetailProduct(brand);
    CREATE INDEX idx_retailproduct_category ON RetailProduct(category);

-- Variant table (self-referencing to RetailProduct)
DROP TABLE IF EXISTS Variant;
CREATE TABLE Variant (
    variantSKU INTEGER PRIMARY KEY,
    baseProductSKU INTEGER NOT NULL,
    size TEXT,
    color TEXT,
    FOREIGN KEY(baseProductSKU)
        REFERENCES RetailProduct(productSKU)
        ON DELETE CASCADE
);
CREATE INDEX idx_variant_baseproduct ON Variant(baseProductSKU);

-- ProductStore table (associative)
DROP TABLE IF EXISTS ProductStore;
CREATE TABLE ProductStore (
    productSKU INTEGER NOT NULL,
    storefrontId INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    PRIMARY KEY(productSKU, storefrontId),
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU)
        ON DELETE CASCADE,
    FOREIGN KEY(storefrontId)
        REFERENCES Storefront(storefrontId)
        ON DELETE CASCADE
);
CREATE INDEX idx_productstore_store ON ProductStore(storefrontId);
CREATE INDEX idx_productstore_quantity ON ProductStore(quantity);

-- Vendor table
DROP TABLE IF EXISTS Vendor;
CREATE TABLE Vendor (
    vendorID INTEGER PRIMARY KEY,
    vendorName TEXT NOT NULL
);

-- ProductVendor table (associative)
DROP TABLE IF EXISTS ProductVendor;
CREATE TABLE ProductVendor (
    vendorID INTEGER,
    productSKU INTEGER,
    details TEXT,
    PRIMARY KEY(vendorID, productSKU),
    FOREIGN KEY(vendorID)
        REFERENCES Vendor(vendorID)
        ON DELETE CASCADE,
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU)
        ON DELETE CASCADE
);
CREATE INDEX idx_productvendor_product ON ProductVendor(productSKU);

-- RetailSale table
DROP TABLE IF EXISTS RetailSale;
CREATE TABLE RetailSale (
    saleId INTEGER PRIMARY KEY,
    saleDate DATETIME NOT NULL,
    taxAmount NUMERIC NOT NULL CHECK(taxAmount > 0), -- Money values cannot be zero here
    subtotalAmount NUMERIC NOT NULL CHECK(subtotalAmount > 0),
    customerId INTEGER NOT NULL,
    storefrontId INTEGER NOT NULL,
    employeeId INTEGER NOT NULL,
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
        ON DELETE CASCADE,
    FOREIGN KEY(storefrontId)
        REFERENCES Storefront(storefrontId)
        ON DELETE CASCADE,
    FOREIGN KEY(employeeId)
        REFERENCES Employee(employeeId)
        ON DELETE CASCADE
);
CREATE INDEX idx_retailsale_customer ON RetailSale(customerId);
CREATE INDEX idx_retailsale_store ON RetailSale(storefrontId);
CREATE INDEX idx_retailsale_employee ON RetailSale(employeeId);
CREATE INDEX idx_retailsale_saledate ON RetailSale(saleDate);

-- ProductSale table (associative)
DROP TABLE IF EXISTS ProductSale;
CREATE TABLE ProductSale (
    saleId INTEGER NOT NULL,
    productSKU INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK(quantity > 0),  -- Quantity cannot be zero here
    PRIMARY KEY(saleId, productSKU),
    FOREIGN KEY(saleId)                             -- Will need a trigger here to update inventory
        REFERENCES RetailSale(saleId)
        ON DELETE CASCADE,
    FOREIGN KEY(productSKU)
         REFERENCES RetailProduct(productSKU)
         ON DELETE CASCADE
);
CREATE INDEX idx_productsale_product ON ProductSale(productSKU);

-- ProductReturn table
DROP TABLE IF EXISTS ProductReturn;
CREATE TABLE ProductReturn (        -- Will need a trigger somewhere here to "reverse" the sale made
    returnId INTEGER PRIMARY KEY,
    returnDate DATETIME NOT NULL,
    saleId INTEGER NOT NULL,
    productSKU INTEGER NOT NULL,
    FOREIGN KEY(saleId)
        REFERENCES RetailSale(saleId)
        ON DELETE CASCADE,
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU)
        ON DELETE CASCADE
);
CREATE INDEX idx_productreturn_sale ON ProductReturn(saleId);
CREATE INDEX idx_productreturn_product ON ProductReturn(productSKU);

-- Discount table
DROP TABLE IF EXISTS Discount;
CREATE TABLE Discount (
    discountId INTEGER PRIMARY KEY,
    discountName TEXT NOT NULL,
    discountType TEXT NOT NULL CHECK (discountType IN ('Percentage', 'Fixed'))
);

-- ProductDiscount table (associative)
DROP TABLE  IF EXISTS ProductDiscount;
CREATE TABLE ProductDiscount (
    discountId INTEGER,
    productSKU INTEGER,
    PRIMARY KEY(discountId, productSKU),
    FOREIGN KEY(discountId)
        REFERENCES Discount(discountId)
        ON DELETE CASCADE,
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU)
        ON DELETE CASCADE
);
CREATE INDEX idx_productdiscount_product  ON ProductDiscount(productSKU);

-- SaleDiscount table (associative)
DROP TABLE IF EXISTS SaleDiscount;
CREATE TABLE SaleDiscount (
    saleId INTEGER,
    discountId INTEGER,
    PRIMARY KEY(saleId, discountId),
    FOREIGN KEY(saleId)
        REFERENCES RetailSale(saleId)
        ON DELETE CASCADE,
    FOREIGN KEY(discountId)
        REFERENCES Discount(discountId)
        ON DELETE CASCADE
);
CREATE INDEX idx_salediscount_discount ON SaleDiscount(discountId);

--Section 3 VR
-- RentalModel table
DROP TABLE IF EXISTS RentalModel;
CREATE TABLE RentalModel (
    modelId INTEGER PRIMARY KEY,
    rentalType TEXT NOT NULL
);

-- RentalUnit table
DROP TABLE IF EXISTS RentalUnit;
CREATE TABLE RentalUnit (
    unitId INTEGER PRIMARY KEY,
    name TEXT NOT NULL,         -- Added by OS (oversight from the ERD/Lab 1)
    conditionStatus TEXT NOT NULL,
    purchaseDate DATETIME NOT NULL,
    modelId INTEGER NOT NULL,
    storefrontId INTEGER NOT NULL,
    FOREIGN KEY(modelId)
        REFERENCES RentalModel(modelId)
        ON DELETE CASCADE,
    FOREIGN KEY(storefrontId)
        REFERENCES Storefront(storefrontId)
        ON DELETE CASCADE
);
CREATE INDEX idx_rentalunit_model ON RentalModel(modelId);
CREATE INDEX idx_rentalunit_store ON RentalUnit(storefrontId);
CREATE INDEX idx_rentalunit_conditionStatus ON RentalUnit(conditionStatus);

-- TransferHistory table
DROP TABLE IF EXISTS TransferHistory;
CREATE TABLE TransferHistory (
    transferId INTEGER PRIMARY KEY,
    transferDate DATETIME NOT NULL,    --Changed TransferTime in ERD to TransferDate for clarity
    unitId INTEGER NOT NULL,
    fromStoreId INTEGER NOT NULL,
    toStoreId INTEGER NOT NULL,
    FOREIGN KEY(toStoreId)
        REFERENCES Storefront(storefrontId)    -- Added this, just a minor oversight - OS
        ON DELETE CASCADE,
    FOREIGN KEY(unitId)
        REFERENCES RentalUnit(unitId)
        ON DELETE CASCADE,
    FOREIGN KEY(fromStoreId)
        REFERENCES Storefront(storefrontId)     -- TRIGGER THAT THESE CANNOT BE THE SAME STOREFRONT
        ON DELETE CASCADE
);
CREATE INDEX idx_transferhistory_unit ON TransferHistory(unitId);
CREATE INDEX idx_transferhistory_fromstore ON TransferHistory(fromStoreId);
CREATE INDEX idx_transferhistory_tostore ON TransferHistory(toStoreId);

-- RentalContract table
DROP TABLE IF EXISTS RentalContract;
CREATE TABLE RentalContract (
    contractId INTEGER PRIMARY KEY,
    startDate DATETIME NOT NULL,
    expectedReturnDate DATETIME NOT NULL,
    depositAmount NUMERIC NOT NULL,
    lateFee INTEGER NOT NULL,
    isActive INTEGER NOT NULL DEFAULT 1 CHECK (isActive IN (0, 1)), --Verify this
    customerId INTEGER NOT NULL,
    employeeId INTEGER NOT NULL,
    storeId INTEGER NOT NULL,
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
        ON DELETE CASCADE,
    FOREIGN KEY(employeeId)
        REFERENCES Employee(employeeId)
        ON DELETE CASCADE,
    FOREIGN KEY(storeId)
        REFERENCES Storefront(storefrontId)
        ON DELETE CASCADE
);
CREATE INDEX idx_rentalcontract_customer ON RentalContract(customerId);
CREATE INDEX idx_rentalcontract_employee ON RentalContract(employeeId);
CREATE INDEX idx_rentalcontract_store ON RentalContract(storeId);
CREATE INDEX idx_rentalcontract_startdate ON RentalContract(startDate);
CREATE INDEX idx_rentalcontract_expectedreturn ON RentalContract(expectedReturnDate);
CREATE INDEX idx_rentalcontract_isactive ON RentalContract(isActive);

-- ContractExtension table
DROP TABLE IF EXISTS ContractExtension;
CREATE TABLE ContractExtension (
    extensionId INTEGER PRIMARY KEY,
    oldReturnDate DATETIME NOT NULL,
    newReturnDate DATETIME NOT NULL,
    contractId INTEGER NOT NULL,
    FOREIGN KEY(contractId)
        REFERENCES RentalContract(contractId)
        ON DELETE CASCADE
);
CREATE INDEX idx_contractextension_contract ON ContractExtension(contractId);

-- ContractUnit table
DROP TABLE IF EXISTS ContractUnit;
CREATE TABLE ContractUnit (
    contractId INTEGER,
    unitId INTEGER,
    PRIMARY KEY(contractId, unitId),
    FOREIGN KEY(contractId)
        REFERENCES RentalContract(contractId)
        ON DELETE CASCADE,
    FOREIGN KEY(unitId)
        REFERENCES RentalUnit(unitId)
        ON DELETE CASCADE
);
CREATE INDEX idx_contractunit_unit ON ContractUnit(unitId);

-- Ticket table
DROP TABLE IF EXISTS Ticket;
CREATE TABLE Ticket (
    ticketId INTEGER PRIMARY KEY,
    priority TEXT NOT NULL,
    status TEXT NOT NULL,
    labor TEXT NOT NULL,
    billAmount INTEGER NOT NULL,
    unitId INTEGER NOT NULL,
    FOREIGN KEY(unitId)
        REFERENCES RentalUnit(unitId)
        ON DELETE CASCADE
);
CREATE INDEX idx_ticket_unit ON Ticket(unitId);
CREATE INDEX idx_ticket_priority ON Ticket(priority);
CREATE INDEX idx_ticket_status ON Ticket(status);

-- Part table
DROP TABLE IF EXISTS Part;
CREATE TABLE Part (
    partId INTEGER PRIMARY KEY,
    partName TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    unitId INTEGER NOT NULL
);

-- TicketPart table
DROP TABLE IF EXISTS TicketPart;
CREATE TABLE TicketPart (
    partId INTEGER,
    ticketId INTEGER,
    quantity INTEGER NOT NULL,
    PRIMARY KEY(partId, ticketId),
    FOREIGN KEY(partId)
        REFERENCES Part(partId)
        ON DELETE CASCADE,
    FOREIGN KEY(ticketId)
        REFERENCES Ticket(ticketId)
        ON DELETE CASCADE
);
CREATE INDEX idx_ticketpart_ticket ON TicketPart(ticketId);

-- UnitPart table
DROP TABLE IF EXISTS UnitPart;
CREATE TABLE UnitPart (
    partId INTEGER,
    unitId INTEGER,
    PRIMARY KEY(partId, unitId),
    FOREIGN KEY(partId)
        REFERENCES Part(partId)
        ON DELETE CASCADE,
    FOREIGN KEY(unitId)
        REFERENCES RentalUnit(unitId)
        ON DELETE CASCADE
);
CREATE INDEX idx_unitpart_unit ON UnitPart(unitId);


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


INSERT INTO RentalContract(contractId, startDate, expectedReturnDate, depositAmount, lateFee, customerId, employeeId, storeId)
VALUES
    (501, '2026-03-01', '2026-03-05', 50, 10, 1001, 1, 1);

-- This insert should FAIL if trigger works
INSERT INTO RentalContract(contractId, startDate, expectedReturnDate, depositAmount, lateFee, customerId, employeeId, storeId)
    VALUES (502, '2026-03-03', '2026-03-07', 50, 10, 1002, 1, 1);

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
    VALUES(801, 'High', 'Open', 'Replace hydraulic line', 120, 301);

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