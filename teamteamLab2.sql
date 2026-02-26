/*
    GROUP ONE - NOAH:
    Storefront          X
    Employee            X
    Role                X
    Store_Shift         X
    Training            ?       -- Unknown table -OS
    Training_Course     X
    Course_Session      X
    Instructor          X
    Session_Instructor  X
    Session_Enroll      X

    GROUP TWO - OLIVIA
    Customer            X
    Customer_Name       X
    Customer_Phone      X
    Customer_Email      X
    Customer_Address    X
    Membership          X
    Customer_Membership X
    Retail_Product      X
    Product_Store       X
    Variant             X
    Vendor              X
    Product_Vendor      X
    Retail_Sale         X
    Product_Sale        X
    Product_Return      X
    Discount            X
    Product_Discount    X
    Sale_Discount       X


    GROUP THREE - VANAY
    Rental_Unit         X
    Rental_Model        X
    Transfer_History    X
    Rental_Contract     X
    Contract_Unit       X
    Contract_Extension  X
    Ticket              X
    Part                X
    Unit_Part           X
    Ticket_Part         X
 */
PRAGMA foreign_keys = ON;

-- Storefront table
DROP TABLE IF EXISTS Storefront;
CREATE TABLE Storefront (
    storefrontId INTEGER PRIMARY KEY,
    managerId INTEGER, -- REQUIRES TRIGGER TO CHECK FOR MANAGER ROLE ON EMPLOYEE
    storeAddress UNIQUE NOT NULL,
    phoneNumber UNIQUE NOT NULL,
    FOREIGN KEY (managerId) REFERENCES Employee(employeeId)
);
-- Index(es) for Storefront
    CREATE INDEX idx_storefront_employee ON Storefront(managerId);


-- Employee table
DROP TABLE IF EXISTS Employee;
CREATE TABLE Employee (
    employeeId INTEGER PRIMARY KEY,
    storeId INTEGER,
    roleId INTEGER,
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    hireDate TEXT NOT NULL,
    hourlyRate REAL NOT NULL,
    isActive INTEGER NOT NULL DEFAULT 1 CHECK (isActive IN (0, 1)),
    FOREIGN KEY (storeId) REFERENCES Storefront(storefrontId),
    FOREIGN KEY (roleId) REFERENCES Role(roleId)
);
-- Index(es) for Employee
    CREATE INDEX idx_employee_store ON Employee(storeId);
    CREATE INDEX idx_employee_role ON Employee(roleId);
    CREATE INDEX idx_employee_hiredate ON Employee(hireDate);
    CREATE INDEX idx_employee_hourlyrate ON Employee(hourlyRate);


-- Role table
DROP TABLE IF EXISTS Role;
CREATE TABLE Role (
    roleId INTEGER PRIMARY KEY,
    roleTitle TEXT NOT NULL UNIQUE,
    permissionLevel INTEGER NOT NULL
);


-- Storeshift table
DROP TABLE IF EXISTS Storeshift;
CREATE TABLE Storeshift (
    shiftId INTEGER PRIMARY KEY,
    employeeId INTEGER NOT NULL,
    storeId INTEGER NOT NULL,
    shiftStart TEXT NULL NULL,
    shiftEnd TEXT NOT NULL,
    FOREIGN KEY (employeeId) REFERENCES Employee(employeeId),
    FOREIGN KEY (storeId) REFERENCES Storefront(storefrontId)
);
-- Index(es) for Storeshift
    CREATE INDEX idx_storeshift_employee ON Storeshift(employeeId);
    CREATE INDEX idx_storeshift_store ON Storeshift(storeId);


-- TrainingCourse table
CREATE TABLE TrainingCourse (
    courseId INTEGER PRIMARY KEY,
    courseName TEXT, NOT NULL,
    description TEXT
);


-- CourseSession table
CREATE TABLE CourseSession (
    sessionId INTEGER PRIMARY KEY,
    capacity INTEGER NOT NULL,
    courseId INTEGER NOT NULL,
    FOREIGN KEY(courseId)
        REFERENCES TrainingCourse(courseId)
);
-- Index(es) for CourseSession
    CREATE INDEX idx_coursesession_course ON CourseSession(courseId);


-- SessionInstructor table (associative)
CREATE TABLE SessionInstructor (
    sessionId INTEGER NOT NULL,
    instructorId INTEGER NOT NULL,
    PRIMARY KEY(sessionId, instructorId),
    FOREIGN KEY(sessionId)
        REFERENCES CourseSession(sessionId),
    FOREIGN KEY(instructorId)
        REFERENCES Employee(employeeId)
);
-- Index(es) for SessionInstructor
    CREATE INDEX idx_sessioninstructor_session ON SessionInstructor(sessionId);
    CREATE INDEX idx_sessioninstructor_instructor ON SessionInstructor(instructorId);




-- SECTION TWO - OS
-- Customer table
DROP TABLE IF EXISTS Customer;
CREATE TABLE Customer (
    customerId INTEGER PRIMARY KEY,
    creationDate DATETIME NOT NULL
);

-- Section One table that had to be moved here due to customer table placement
CREATE TABLE SessionEnroll (
    sessionId INTEGER NOT NULL,
    customerId INTEGER NOT NULL,
    PRIMARY KEY(sessionId, customerId),
    FOREIGN KEY(sessionId)
        REFERENCES CourseSession(sessionId),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
);
-- Index(es) for SessionEnroll
    CREATE INDEX idx_sessionenroll_session ON SessionEnroll(sessionId);
    CREATE INDEX idx_sessionenroll_customer ON SessionEnroll(customerId);



-- CustomerName Table (weak)
DROP TABLE IF EXISTS CustomerName;
CREATE TABLE CustomerName (
    customerId INTEGER,
    firstName TEXT,
    lastName TEXT,
      FOREIGN KEY(customerId)
        REFERENCES Customer(customerId),
    PRIMARY KEY(customerId,firstName, lastName)

);
-- Index(es) for CustomerName
    CREATE INDEX idx_customername_customer ON CustomerName(customerId);
    CREATE INDEX idx_customername_lastname ON CustomerName(lastName);


-- CustomerPhone table (weak)
DROP TABLE IF EXISTS CustomerPhone;
CREATE TABLE CustomerPhone(
    customerId INTEGER,
    phoneNumber INTEGER,
    PRIMARY KEY(customerId, phoneNumber),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
);
-- Index(es) for CustomerPhone
    CREATE INDEX idx_customerphone_customer ON CustomerPhone(customerId);


-- CustomerEmail table (weak)
DROP TABLE IF EXISTS CustomerEmail;
CREATE TABLE CustomerEmail (
    customerId INTEGER,
    emailAddress TEXT,
    PRIMARY KEY(customerId, emailAddress),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
);
-- Index(es) for CustomerEmail
    CREATE INDEX idx_customeremail_customer ON CustomerEmail(customerId);
    CREATE INDEX idx_customeremail_email ON CustomerEmail(emailAddress);


-- CustomerAddress table (weak)
DROP TABLE IF EXISTS CustomerAddress;
CREATE TABLE CustomerAddress (
    customerId INTEGER,
    zipCode INTEGER,
    addressLine1 TEXT,
    addressLine2 TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    isPreferred INTEGER NOT NULL DEFAULT 1 CHECK (isPreferred IN (0, 1)),
    PRIMARY KEY(customerId, zipCode, addressLine1, addressLine2, city, state, country),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
);
-- Index(es) for CustomerAddress
    CREATE INDEX idx_customeraddress_customer ON CustomerAddress(customerId);
    CREATE INDEX idx_customeraddress_zipcode ON CustomerAddress(zipCode);
    CREATE INDEX idx_customeraddress_city ON CustomerAddress(city);
    CREATE INDEX idx_customeraddress_state ON CustomerAddress(state);

-- Membership table
DROP TABLE IF EXISTS Membership;
CREATE TABLE Membership (
    membershipId INTEGER PRIMARY KEY,
    membershipName TEXT NOT NULL
);


-- CustomerMembership table (associative)
DROP TABLE IF EXISTS CustomerMembership;
CREATE TABLE CustomerMembership (
    membershipId INTEGER,
    customerId INTEGER,
    isActive INTEGER NOT NULL DEFAULT 1 CHECK (isActive IN (0, 1)),
    PRIMARY KEY(membershipId, customerId),
    FOREIGN KEY(membershipId)
        REFERENCES Membership(membershipId),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
);
-- Index(es) for CustomerMembership
    CREATE INDEX idx_customermembership_customer ON CustomerMembership(customerId);
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
    activeStatus TEXT NOT NULL CHECK(activeStatus IN ('Active', 'Inactive')),
    baseProductSKU INTEGER,     -- This value is NULLABLE
    FOREIGN KEY(baseProductSKU)
        REFERENCES Variant(baseProductSKU)
);
-- Index(es) for RetailProduct
    CREATE INDEX idx_retailproduct_baseproduct ON RetailProduct(baseProductSKU);
    CREATE INDEX idx_retailproduct_brand ON RetailProduct(brand);
    CREATE INDEX idx_retailproduct_category ON RetailProduct(category);

-- ProductStore table (associative)
DROP TABLE IF EXISTS ProductStore;
CREATE TABLE ProductStore (
    productSKU INTEGER,
    storefrontId INTEGER,
    PRIMARY KEY(productSKU, storefrontId),
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU),
    FOREIGN KEY(storefrontId)
        REFERENCES Storefront(storefrontId)
);
-- Index(es) for ProductStore
    CREATE INDEX idx_productstore_product ON ProductStore(productSKU);
    CREATE INDEX idx_productstore_store ON ProductStore(storefrontId);


-- Variant table (self-referencing to RetailProduct)
DROP TABLE IF EXISTS Variant;
CREATE TABLE Variant (
    productSKU INTEGER,
    baseProductSKU INTEGER,
    size TEXT,
    color TEXT,
    PRIMARY KEY(productSKU, baseProductSKU),
    FOREIGN KEY(productSKU)
         REFERENCES RetailProduct(productSKU)
);
-- Index(es) for Variant
    CREATE INDEX idx_variant_product ON Variant(productSKU);


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
        REFERENCES Vendor(vendorID),
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU)
);
-- Index(es) for ProductVendor
    CREATE INDEX idx_retailsale_vendor ON ProductVendor(vendorID);
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
        REFERENCES Customer(customerId),
    FOREIGN KEY(storefrontId)
        REFERENCES Storefront(storefrontId),
    FOREIGN KEY(employeeId)
        REFERENCES Employee(employeeId)
);
-- Index(es) for RetailSale
    CREATE INDEX idx_retailsale_customer ON RetailSale(customerId);
    CREATE INDEX idx_retailsale_store ON RetailSale(storefrontId);
    CREATE INDEX idx_retailsale_employee ON RetailSale(employeeId);
    CREATE INDEX idx_retailsale_saledate ON RetailSale(saleDate);


-- ProductSale table (associative)
DROP TABLE IF EXISTS ProductSale;
CREATE TABLE ProductSale (
    saleId INTEGER,
    productSKU INTEGER,
    quantity INTEGER NOT NULL CHECK(quantity > 0),  -- Quantity cannot be zero here
    PRIMARY KEY(saleId, productSKU),
    FOREIGN KEY(saleId)                             -- Will need a trigger here to update inventory
        REFERENCES RetailSale(saleId),
    FOREIGN KEY(productSKU)
         REFERENCES RetailProduct(productSKU)
);
-- Index(es) for ProductSale
    CREATE INDEX idx_productsale_sale ON ProductSale(saleId);
    CREATE INDEX idx_productsale_product ON ProductSale(productSKU);


-- ProductReturn table
DROP TABLE IF EXISTS ProductReturn;
CREATE TABLE ProductReturn (        -- Will need a trigger somewhere here to "reverse" the sale made
    returnId INTEGER PRIMARY KEY,
    returnDate DATETIME NOT NULL,
    saleId INTEGER NOT NULL,
    productSKU INTEGER NOT NULL,
    FOREIGN KEY(saleId)
        REFERENCES RetailSale(saleId),
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU)
);
-- Index(es) for ProductReturn
    CREATE INDEX idx_productreturn_sale ON ProductReturn(saleId);
    CREATE INDEX idx_productreturn_product ON ProductReturn(productSKU);


-- Discount table
DROP TABLE IF EXISTS Discount;
CREATE TABLE Discount (
    discountId INTEGER PRIMARY KEY,
    discountName TEXT NOT NULl,
    discountType TEXT NOT NULL
);

-- ProductDiscount table (associative)
DROP TABLE  IF EXISTS ProductDiscount;
CREATE TABLE ProductDiscount (
    discountId INTEGER,
    productSKU INTEGER,
    PRIMARY KEY(discountId, productSKU),
    FOREIGN KEY(discountId)
        REFERENCES Discount(discountId),
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU)
);
-- Index(es) for ProductDiscount
    CREATE INDEX idx_productdiscount_discount ON ProductDiscount(discountId);
    CREATE INDEX idx_productdiscount_product  ON ProductDiscount(productSKU);


-- SaleDiscount table (associative)
DROP TABLE IF EXISTS SaleDiscount;
CREATE TABLE SaleDiscount (
    saleId INTEGER,
    discountId INTEGER,
    PRIMARY KEY(saleId, discountId),
    FOREIGN KEY(saleId)
        REFERENCES RetailSale(saleId),
    FOREIGN KEY(discountId)
        REFERENCES Discount(discountId)
);
-- Index(es) for SaleDiscount
    CREATE INDEX idx_salediscount_sale ON SaleDiscount(saleId);
    CREATE INDEX idx_salediscount_discount ON SaleDiscount(discountId);

-- End Section 2 --


--Section 3 VR
--TASK: Create Indexes and label tables

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
        REFERENCES RentalModel(modelId),
    FOREIGN KEY(storefrontId)
        REFERENCES Storefront(storefrontId)
);
-- Index(es) for for RentalUnit
    CREATE INDEX idx_rentalunit_model ON RentalModel(modelId);
    CREATE INDEX idx_rentalunit_store ON RentalUnit(storefrontId);
    CREATE INDEX idx_rentalunit_conditionStatus ON RentalUnit(conditionStatus);

-- TransferHistory table
DROP TABLE IF EXISTS TransferHistory;
CREATE TABLE TransferHistory (
    transferId INTEGER PRIMARY KEY,
    transferDate DATETIME NOT NULL,    --Changed TransferTime in ERD to TransferDate for clarity
    unitId INTEGER NOT NULL,
    fromStoreId INTEGER NOT NULL, --How to tackle this? Just reference storefront again? 
    toStoreId INTEGER NOT NULL,
    FOREIGN KEY(toStoreId)
        REFERENCES Storefront(storefrontId),    -- Added this, just a minor oversight - OS
    FOREIGN KEY(unitId)
        REFERENCES RentalUnit(unitId),
    FOREIGN KEY(fromStoreId)
        REFERENCES Storefront(storefrontId)     -- Changed this to storefrontId, might work? -OS
);
-- Index(es) for for TransferHistory
    CREATE INDEX idx_transferhistory_unit ON TransferHistory(unitId);
    CREATE INDEX idx_transferhistory_fromstore ON TransferHistory(fromStoreId);
    CREATE INDEX idx_transferhistory_tostore ON TransferHistory(toStoreId);

-- RentalContract table
DROP TABLE IF EXISTS RentalContract;
CREATE TABLE RentalContract (
    contractId INTEGER PRIMARY KEY,
    startDate DATETIME NOT NULL,
    expectedReturnDate DATETIME NOT NULL,
    depositAmount INTEGER NOT NULL,
    lateFee INTEGER NOT NULL,
    isActive INTEGER NOT NULL DEFAULT 1 CHECK (isActive IN (0, 1)), --Verify this
    customerId INTEGER NOT NULL,
    employeeId INTEGER NOT NULL,
    storeId INTEGER NOT NUll,
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId),
    FOREIGN KEY(employeeId)
        REFERENCES Employee(employeeId),
    FOREIGN KEY(storeId)
        REFERENCES Storefront(storefrontId)
);
-- Index(es) for for RentalContract
    CREATE INDEX idx_rentalcontract_customer ON RentalContract(customerId);
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
);
-- Index(es) for ContractExtension
    CREATE INDEX idx_contractextension_contract ON ContractExtension(contractId);

-- ContractUnit table
DROP TABLE IF EXISTS ContractUnit;
CREATE TABLE ContractUnit (
    contractId INTEGER,
    unitId INTEGER,
    PRIMARY KEY(contractId, unitId),
    FOREIGN KEY(contractId)
        REFERENCES RentalContract(contractId),
    FOREIGN KEY(unitId)
        REFERENCES RentalUnit(unitId)
);
-- Index(es) for ContractUnit
    CREATE INDEX idx_contractunit_unit ON ContractUnit(unitId);
    CREATE INDEX idx_contractunit_contract ON ContractUnit(contractId);

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
);
-- Index(es) for Ticket
    CREATE INDEX idx_ticket_unit ON Ticket(unitId);
    CREATE INDEX idx_ticket_priority ON Ticket(priority);
    CREATE INDEX idx_ticket_status ON Ticket(status);

-- TicketPart table
DROP TABLE IF EXISTS TicketPart;
CREATE TABLE TicketPart (
    partId INTEGER,
    ticketId INTEGER,
    quantity INTEGER NOT NULL,
    PRIMARY KEY(partId, ticketId),
    FOREIGN KEY(partId)
        REFERENCES Part(partId),
    FOREIGN KEY(ticketId)
        REFERENCES Ticket(ticketId)
);
-- Index(es) for TicketPart
    CREATE INDEX idx_ticketpart_part ON TicketPart(partId);
    CREATE INDEX idx_ticketpart_ticket ON TicketPart(ticketId);

-- Part table
DROP TABLE IF EXISTS Part;
CREATE TABLE Part (
    partId INTEGER PRIMARY KEY,
    partName TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    unitId INTEGER NOT NULL,
    FOREIGN KEY(unitId)
        REFERENCES RentalUnit(unitId)
);
-- Index(es) for Part
    CREATE INDEX idx_part_unit ON Part(unitId);

-- UnitPart table
DROP TABLE IF EXISTS UnitPart;
CREATE TABLE UnitPart (
    partId INTEGER,
    unitId INTEGER,
    PRIMARY KEY(partId, unitId),
    FOREIGN KEY(partId)
        REFERENCES Part(partId),
    FOREIGN KEY(unitId)
        REFERENCES RentalUnit(unitId)
);
-- Index(es) for UnitPart
    CREATE INDEX idx_unitpart_part ON UnitPart(partId);
    CREATE INDEX idx_unitpart_unit ON UnitPart(unitId);


-- Insert Statements (sample data)

INSERT INTO RetailProduct(productSKU, name, brand, category, standardPrice, taxStatus, activeStatus, baseProductSKU)
    VALUES(10000001, 'Toolbox', 'Craftsman', 'Hardware', 19.99, 'Exempt', 'Active', NULL),
            (10000002, 'Toolbox Red', 'Craftsman', 'Hardware', 19.99, 'Exempt', 'Active', 10000001),
            (10000003, 'Toolbox White', 'Craftsman', 'Hardware', 19.99, 'Exempt', 'Active', 10000001);


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
    VALUES(1,'Cashier', 2),
          (2, 'Lead Cashier', 4),
          (3, 'Cashier manager', 6);

INSERT INTO Vendor(vendorID, vendorName)
    VALUES(900, 'Craftsman'),
          (901, 'Dewalt');


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

-- Delete Statements (please run these after testing insert statements or they will not work)
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