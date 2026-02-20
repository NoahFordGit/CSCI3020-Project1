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
    Customer
    Customer_Name
    Customer_Phone
    Customer_Email
    Customer_Address
    Membership
    Customer_Membership
    Retail_Product
    Product_Store
    Variant
    Vendor
    Product_Vendor
    Retail_Sale
    Product_Sale
    Product_Return
    Discount
    Product_Discount
    Sale_Discount


    GROUP THREE - VANAY
    Rental_Unit
    Rental_Model
    Transfer_History
    Rental_Contract
    Contract_Unit
    Contract_Extension
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