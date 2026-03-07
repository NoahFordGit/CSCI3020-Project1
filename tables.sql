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
    Customer_Membership X TX
    Retail_Product      X
    Product_Store       X
    Variant             X
    Vendor              X
    Product_Vendor      X
    Retail_Sale         X TX
    Product_Sale        X
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
    managerID INTEGER NOT NULL,
    storeId INTEGER NOT NULL,
    shiftStart DATETIME NOT NULL,
    shiftEnd DATETIME NOT NULL,
    FOREIGN KEY (employeeId)
        REFERENCES Employee(employeeId)
        ON DELETE CASCADE,
    FOREIGN KEY (managerID)
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
    FOREIGN KEY(saleId)
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
    completionDate DATETIME,        -- Added by OS for trigger 4
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


-- AuditLog table (used for trigger 4)
DROP TABLE IF EXISTS AuditLog;
CREATE TABLE AuditLog (
    valueId INTEGER PRIMARY KEY,
    tableName TEXT NOT NULL,
    oldValue TEXT NOT NULL,
    newValue TEXT NOT NULL,
    time DATETIME
);
