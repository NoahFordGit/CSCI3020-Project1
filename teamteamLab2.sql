/*
    GROUP ONE - NOAH:
    Storefront          X
    Employee            X
    Role                X
    Store_Shift
    Training
    Training_Course
    Course_Session
    Instructor
    Session_Instructor
    Session_Enroll

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
    Rental_Unit x
    Rental_Model x
    Transfer_History x
    Rental_Contract x
    Contract_Unit 
    Contract_Extension x
    Ticket
    Part
    Unit_Part
    Ticket_Part
 */
PRAGMA  foreign_keys = ON;

DROP TABLE IF EXISTS Storefront;
CREATE TABLE Storefront (
    storefrontId INTEGER PRIMARY KEY,
    managerId INTEGER, -- REQUIRES TRIGGER TO CHECK FOR MANAGER ROLE ON EMPLOYEE
    storeAddress UNIQUE NOT NULL,
    phoneNumber UNIQUE NOT NULL,
    FOREIGN KEY (managerId) REFERENCES Employee(employeeId)
);

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
    FOREIGN KEY (roleId) REFERENCES Role (roleId)
);

DROP TABLE IF EXISTS Role;
CREATE TABLE Role (
    roleId INTEGER PRIMARY KEY,
    roleTitle TEXT NOT NULL UNIQUE,
    permissionLevel INTEGER NOT NULL
);






-- SECTION TWO - OS

-- Customer table
DROP TABLE IF EXISTS Customer;
CREATE TABLE Customer (
    customerId INTEGER PRIMARY KEY,
    creationDate DATETIME NOT NULL
);


-- CustomerName Table (weak)
DROP TABLE IF EXISTS CustomerName;
CREATE TABLE CustomerName (
    customerId INTEGER PRIMARY KEY,
    firstName TEXT PRIMARY KEY,
    lastName TEXT PRIMARY KEY,
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
);
-- Indexes for CustomerName
    CREATE INDEX idx_customer_name
        ON CustomerName(customerId);


-- CustomerPhone table (weak)
DROP TABLE IF EXISTS CustomerPhone;
CREATE TABLE CustomerPhone(
    customerId INTEGER PRIMARY KEY,
    phoneNumber INTEGER PRIMARY KEY,
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
);
-- Indexes for CustomerPhone
    CREATE INDEX idx_customer_phone
        ON CustomerPhone(customerId);


-- CustomerEmail table (weak)
DROP TABLE IF EXISTS CustomerEmail;
CREATE TABLE CustomerEmail (
    customerId INTEGER PRIMARY KEY,
    emailAddress TEXT PRIMARY KEY,
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
);
-- Indexes for CustomerEmail
    CREATE INDEX idx_customer_email
        ON CustomerEmail(customerId);


-- CustomerAddress table (weak)
DROP TABLE IF EXISTS CustomerAddress;
CREATE TABLE CustomerAddress (
    customerId INTEGER PRIMARY KEY,
    zipCode INTEGER PRIMARY KEY,
    addressLine1 TEXT PRIMARY KEY,
    addressLine2 TEXT PRIMARY KEY,
    city TEXT PRIMARY KEY,
    state TEXT PRIMARY KEY,
    country TEXT PRIMARY KEY,
    isPreferred INTEGER NOT NULL DEFAULT 1 CHECK (isPreferred IN (0, 1)),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
);
-- Indexes for CustomerAddress
    CREATE INDEX idx_customer_address
        ON CustomerAddress(customerId);


-- Membership table
DROP TABLE IF EXISTS Membership;
CREATE TABLE Membership (
    membershipId INTEGER PRIMARY KEY,
    membershipName TEXT NOT NULL
);


-- CustomerMembership table (associative)
DROP TABLE IF EXISTS CustomerMembership;
CREATE TABLE CustomerMembership (
    membershipId INTEGER PRIMAR0Y KEY,
    customerId INTEGER PRIMARY KEY,
    isActive INTEGER NOT NULL DEFAULT 1 CHECK (isActive IN (0, 1)),
    FOREIGN KEY(membershipId)
        REFERENCES Membership(membershipId),
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
);
-- Indexes for CustomerMembership
    CREATE INDEX idx_customer_membership
        ON CustomerMembership(customerId);

    CREATE INDEX idx_membership_customer
        ON CustomerMembership(membershipId);


-- RetailProduct table
DROP TABLE IF EXISTS RetailProduct;
CREATE TABLE RetailProduct (
    productSKU INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    brand TEXT NOT NULL,
    category TEXT NOT NULL,
    standardPrice NUMERIC NOT NULL CHECK(standardPrice > 0),
    taxStatus TEXT NOT NULL, -- Add a check here when status options are known
    activeStatus TEXT NOT NULL CHECK(activeStatus IN ('Active', 'Inactive')),
    baseProductSKU INTEGER,
    FOREIGN KEY(baseProductSKU)
        REFERENCES Variant(baseProductSKU)
);
-- Indexes for RetailProduct
    CREATE INDEX idx_product_variant
        ON RetailProduct(baseProductSKU);


-- ProductStore table (associative)
DROP TABLE IF EXISTS ProductStore;
CREATE TABLE ProductStore (
    productSKU INTEGER PRIMARY KEY,
    storefrontId INTEGER PRIMARY KEY,
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU),
    FOREIGN KEY(storefrontId)
        REFERENCES Storefront(storefrontId)
);
-- Indexes for ProductStore
    CREATE INDEX idx_product_store
        ON ProductStore(productSKU);

    CREATE INDEX idx_store_product
        ON ProductStore(storefrontId);


-- Variant table (self-referencing to RetailProduct)
DROP TABLE IF EXISTS Variant;
CREATE TABLE Variant (
    productSKU INTEGER PRIMARY KEY,
    baseProductSKU INTEGER PRIMARY KEY,
    size TEXT,
    color TEXT,
    FOREIGN KEY(productSKU)
         REFERENCES RetailProduct(productSKU)
);
-- Indexes for Variant
    CREATE INDEX idx_variant_product
        ON Variant(productSKU);


-- Vendor table
DROP TABLE IF EXISTS Vendor;
CREATE TABLE Vendor (
    vendorID INTEGER PRIMARY KEY,
    vendorName TEXT NOT NULL
);


-- ProductVendor table (associative)
DROP TABLE IF EXISTS ProductVendor;
CREATE TABLE ProductVendor (
    vendorID INTEGER PRIMARY KEY,
    productSKU INTEGER PRIMARY KEY,
    details TEXT,
    FOREIGN KEY(vendorID)
        REFERENCES Vendor(vendorID),
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU)
);
-- Indexes for ProductVendor
     CREATE INDEX idx_vendor_product
        ON ProductVendor(vendorID);

    CREATE INDEX idx_product_vendor
        ON ProductVendor(productSKU);


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
-- Indexes for RetailSale
    CREATE INDEX idx_sale_customer
        ON RetailSale(customerId);

    CREATE INDEX idx_sale_store
        ON RetailSale(storefrontId);

    CREATE INDEX idx_sale_employee
        ON RetailSale(employeeId);


-- ProductSale table (associative)
DROP TABLE IF EXISTS ProductSale;
CREATE TABLE ProductSale (
    saleId INTEGER PRIMARY KEY,
    productSKU INTEGER PRIMARY KEY,
    quantity INTEGER NOT NULL CHECK(quantity > 0),  -- Quantity cannot be zero here
    FOREIGN KEY(saleId)                             -- Will need a trigger here to update inventory
        REFERENCES RetailSale(saleId),
    FOREIGN KEY(productSKU)
         REFERENCES RetailProduct(productSKU)
);
-- Indexes for ProductSale
    CREATE INDEX idx_sale_product
        ON ProductSale(saleId);

    CREATE INDEX idx_product_sale
        ON ProductSale(productSKU);


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
-- Indexes for ProductReturn
    CREATE INDEX idx_return_sale
        ON ProductReturn(saleId);

    CREATE INDEX idx_return_product
        ON ProductReturn(productSKU);


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
    discountId INTEGER PRIMARY KEY,
    productSKU INTEGER PRIMARY KEY,
    FOREIGN KEY(discountId)
        REFERENCES Discount(discountId),
    FOREIGN KEY(productSKU)
        REFERENCES RetailProduct(productSKU)
);
-- Indexes for ProductDiscount
    CREATE INDEX idx_discount_product
        ON ProductDiscount(discountId);

    CREATE INDEX idx_product_discount
        ON ProductDiscount(productSKU);


-- SaleDiscount table (associative)
DROP TABLE IF EXISTS SaleDiscount;
CREATE TABLE SaleDiscount (
    saleId INTEGER PRIMARY KEY,
    discountId INTEGER PRIMARY KEY,
    FOREIGN KEY(saleId)
        REFERENCES RetailSale(saleId),
    FOREIGN KEY(discountId)
        REFERENCES Discount(discountId)
);
-- Indexes for SaleDiscount
    CREATE INDEX idx_sale_discount
        ON SaleDiscount(saleId);

    CREATE INDEX idx_discount_sale
        ON SaleDiscount(discountId);

-- End Section 2 --


--Section 3 VR

DROP TABLE IF EXISTS RentalModel;
CREATE TABLE RentalModel (
    modelId INTEGER PRIMARY KEY,
    rentalType TEXT NOT NULL
);

DROP TABLE IF EXISTS RentalUnit;
CREATE TABLE RentalUnit (
    unitId INTEGER PRIMARY KEY,
    conditionStatus TEXT NOT NULL,
    purchaseDate DATETIME NOT NULL,
    modelId INTEGER NOT NULL,
    storefrontId INTEGER NOT NULL,
    FOREIGN KEY(modelId)
        REFERENCES RentalModel(modelId),
    FOREIGN KEY(storefrontId)
        REFERENCES Storefront(storefrontId)
);

DROP TABLE IF EXISTS TransferHistory;
CREATE TABLE TransferHistory (
    transferId INTEGER PRIMARY KEY,
    transferDate DATETIME NOT NULL,    --Changed TransferTime in ERD to TransferDate for clarity
    unitId INTEGER NOT NULL,
    fromStoreId INTEGER NOT NULL, --How to tackle this? Just reference storefront again? 
    toStoreId INTEGER NOT NULL,
    FOREIGN KEY(unitId)
        REFERENCES RentalUnit(unitId),
    FOREIGN KEY(fromStoreId)
        REFERENCES Storefront(fromStoreId)
);

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
    storeId INTERGER NOT NUll,
    FOREIGN KEY(customerId)
        REFERENCES Customer(customerId)
    FOREIGN KEY(employeeId)
        REFERENCES Employee(employeeId)
    FOREIGN KEY(storeId)
        REFERENCES Storefront(storefrontId)
);

DROP TABLE IF EXISTS ContractExtension;
CREATE TABLE ContractExtension (
    extensionId INTEGER PRIMARY KEY,
    oldReturnDate DATETIME NOT NULL,
    newReturnDate DATETIME NOT NULL,
    contractId INTEGER NOT NULL,
    FOREIGN KEY(contractId)
        REFERENCES RentalContract(contractId)
);

