create database IMT577_DW_NIKHITHA_ANCHAN_STAGING use database IMT577_DW_NIKHITHA_ANCHAN_STAGING --DROP TABLE IF EXISTS TargetDataChannel
-- Channel table
CREATE TABLE Staging_Channel (
    ChannelID Integer PRIMARY KEY,
    ChannelCategoryID Integer,
    Channel VARCHAR(255),
    CreatedDate VARCHAR(255),
    CreatedBy VARCHAR(255),
    ModifiedDate VARCHAR(255),
    ModifiedBy VARCHAR(255)
);
-- ChannelCategory table
CREATE TABLE Staging_ChannelCategory (
    ChannelCategoryID INTEGER PRIMARY KEY,
    ChannelCategory VARCHAR(255),
    CreatedDate VARCHAR(255),
    CreatedBy VARCHAR(255),
    ModifiedDate VARCHAR(255),
    ModifiedBy VARCHAR(255)
);
-- Customer table
CREATE TABLE Staging_Customer (
    CustomerID VARCHAR(255) PRIMARY KEY,
    SubSegmentID Integer,
    FirstName VARCHAR(255),
    LastName VARCHAR(255),
    Gender VARCHAR(255),
    EmailAddress VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(255),
    StateProvince VARCHAR(255),
    Country VARCHAR(255),
    PostalCode VARCHAR(255),
    PhoneNumber VARCHAR(255),
    CreatedDate DATETIME,
    CreatedBy VARCHAR(255),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(255)
);
-- Product table
CREATE TABLE Staging_Product (
    ProductID INTEGER PRIMARY KEY,
    ProductTypeID INTEGER,
    Product VARCHAR(255),
    Color VARCHAR(255),
    Style VARCHAR(255),
    UnitOfMeasureID INTEGER,
    Weight FLOAT,
    Price FLOAT,
    Cost FLOAT,
    CreatedDate DATETIME,
    CreatedBy VARCHAR(255),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(255),
    WholesalePrice FLOAT
);
-- ProductCategory table
CREATE TABLE Staging_ProductCategory (
    ProductCategoryID INTEGER PRIMARY KEY,
    ProductCategory VARCHAR(255),
    CreatedDate DATETIME,
    CreatedBy VARCHAR(255),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(255)
);
-- ProductType table
CREATE TABLE Staging_ProductType (
    ProductTypeID INTEGER PRIMARY KEY,
    ProductCategoryID INTEGER,
    ProductType VARCHAR(255),
    CreatedDate DATETIME,
    CreatedBy VARCHAR(255),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(255)
);
-- Reseller table
CREATE TABLE Staging_Reseller (
    ResellerID VARCHAR(255) PRIMARY KEY,
    Contact VARCHAR(255),
    EmailAddress VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(255),
    StateProvince VARCHAR(255),
    Country VARCHAR(255),
    PostalCode VARCHAR(255),
    PhoneNumber VARCHAR(255),
    CreatedDate DATETIME,
    CreatedBy VARCHAR(255),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(255),
    ResellerName VARCHAR(255)
);
-- SalesDetail table
CREATE TABLE Staging_SalesDetail (
    SalesDetailID INTEGER PRIMARY KEY,
    SalesHeaderID INTEGER,
    ProductID INTEGER,
    SalesQuantity INTEGER,
    SalesAmount FLOAT,
    CreatedDate VARCHAR(255),
    CreatedBy VARCHAR(255),
    ModifiedDate VARCHAR(255),
    ModifiedBy VARCHAR(255)
);
-- SalesHeader table
CREATE TABLE Staging_SalesHeader (
    SalesHeaderID INTEGER PRIMARY KEY,
    Date DATE,
    ChannelID INTEGER,
    StoreID INTEGER,
    CustomerID VARCHAR(255),
    ResellerID VARCHAR(255),
    CreatedDate VARCHAR(255),
    CreatedBy VARCHAR(255),
    ModifiedDate VARCHAR(255),
    ModifiedBy VARCHAR(255)
);
-- Store table
CREATE TABLE Staging_Store (
    StoreID INTEGER PRIMARY KEY,
    SubSegmentID INTEGER,
    StoreNumber INTEGER,
    StoreManager VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(255),
    StateProvince VARCHAR(255),
    Country VARCHAR(255),
    PostalCode VARCHAR(255),
    PhoneNumber VARCHAR(255),
    CreatedDate VARCHAR(255),
    CreatedBy VARCHAR(255),
    ModifiedDate VARCHAR(255),
    ModifiedBy VARCHAR(255)
);
-- Target Data Channel Reseller and Store table
CREATE TABLE Staging_TargetDataChannel (
    Year INTEGER,
    ChannelName VARCHAR(255),
    TargetName VARCHAR(255),
    TargetSalesAmount INTEGER
);
-- Target Data Product table
CREATE TABLE Staging_TargetDataProduct (
    ProductID INTEGER,
    Product VARCHAR(255),
    Year INTEGER,
    SalesQuantityTarget INTEGER
);
- == == == == == == == == == == == == == == = new
update
    == == == == == == = - == == == == == == == == == == == == == == = new
update
    == == == == == == = - == == == == == == == == == == == == == == = new
update
    == == == == == == = - == == == == == == == == == == == == == == = new
update
    == == == == == == = CREATE
    OR REPLACE TABLE DIM_PRODUCT(
        DimProductID INT IDENTITY(1, 1) CONSTRAINT PK_DimProductID PRIMARY KEY NOT NULL,
        -- Surrogate Key(Identity key autoincremets it by one step size)
        --Surrogate keys are artificial keys created for database tables, typically used as primary keys. They are unique identifiers that do not carry any business meaning but serve as a means to uniquely identify each record in a table.
        ProductID INT,
        ProductTypeID INT,
        ProductCategoryID INT,
        ProductName VARCHAR(255),
        ProductType VARCHAR(255),
        ProductCategory VARCHAR(255),
        ProductRetailPrice FLOAT(10),
        ProductWholesalePrice FLOAT(10),
        ProductCost FLOAT(10),
        ProductRetailProfit FLOAT(10),
        ProductWholesaleUnitProfit FLOAT(10),
        ProductProfitMarginUnitPercentage FLOAT(10)
    );
INSERT INTO
    DIM_PRODUCT(
        ProductID,
        ProductTypeID,
        ProductCategoryID,
        ProductName,
        ProductType,
        ProductCategory,
        ProductRetailPrice,
        ProductWholesalePrice,
        ProductCost,
        ProductRetailProfit,
        ProductWholesaleUnitProfit,
        ProductProfitMarginUnitPercentage
    )
SELECT
    CAST(pro.ProductID AS INT) AS ProductID,
    -- the inital data had these as character dataype hence typecasting to integer
    CAST(protyp.PRODUCTTYPEID AS INT) AS ProductTypeID,
    CAST(procat.PRODUCTCATEGORYID AS INT) AS ProductCategoryID,
    pro.Product,
    protyp.PRODUCTTYPE,
    procat.PRODUCTCATEGORY,
    Price,
    WholesalePrice,
    Cost,
    Price - Cost AS ProductRetailProfit,
    WholesalePrice - Cost AS ProductWholesaleProfit,
    ROUND(
        COALESCE(
            (
                (
                    (
                        COALESCE(pro.Price - pro.Cost, 0) / COALESCE(pro.Price, 1)
                    ) * 100
                ) + (
                    (
                        COALESCE(pro.WholesalePrice - pro.Cost, 0) / COALESCE(pro.WholesalePrice, 1)
                    ) * 100
                )
            ) / 2,
            -1
        ),
        2
    ) AS ProductProfitMarginUnitPercentage
FROM
    STAGING_PRODUCT pro
    LEFT JOIN STAGING_PRODUCTTYPE protyp ON pro.ProductTypeID = protyp.PRODUCTTYPEID
    LEFT JOIN STAGING_PRODUCTCATEGORY procat ON protyp.PRODUCTCATEGORYID = procat.PRODUCTCATEGORYID;
-- inserting unknowns
INSERT INTO
    DIM_PRODUCT (
        DimProductID,
        ProductID,
        ProductTypeID,
        ProductCategoryID,
        ProductName,
        ProductType,
        ProductCategory,
        ProductRetailPrice,
        ProductWholesalePrice,
        ProductCost,
        ProductRetailProfit,
        ProductWholesaleUnitProfit,
        ProductProfitMarginUnitPercentage
    )
VALUES
    (
        -1,
        --int
        -1,
        -1,
        -1,
        'Unknown',
        --varchar
        'Unknown',
        'Unknown',
        -1.0,
        --float
        -1.0,
        -1.0,
        -1.0,
        -1.0,
        -1.0
    );
    /*we are creating the unknows in all these tables because we will be referring to these tables in our fact table and fact tables cannot have unknowns, hence if there is any value that is unknown in our initial excel files, we will replace it with these unknown values.
    When designing a data warehouse, particularly in a star schema that includes dimension tables and fact tables, it is common practice to insert a row of "unknowns" into dimension tables. This row typically has default or placeholder values and serves several important purposes, especially when dealing with referential integrity and handling missing or unknown data in fact tables.
    There might be cases where the data for a particular dimension is not available at the time of data loading. For instance, if a fact record is received but the associated dimension data is missing, inserting a row of unknowns ensures that the fact record can still be loaded.
    Fact tables often have foreign keys that reference primary keys in dimension tables. If a dimension key is not available when a fact record is being inserted, having an "unknown" row ensures that the foreign key constraint is not violated.
    */
SELECT
    *
FROM
    DIM_PRODUCT;
--CHANNEL DIMENSION:
    CREATE
    OR REPLACE TABLE DIM_CHANNEL(
        DimChannelID INT IDENTITY(1, 1) CONSTRAINT PK_DimPChannelID PRIMARY KEY NOT NULL,
        -- Surrogate Key(Identity key autoincremets it by one step size)
        ChannelID INT,
        ChannelCategoryID INT,
        ChannelName VARCHAR(255),
        ChannelCategory VARCHAR(255)
    );
INSERT INTO
    DIM_CHANNEL(
        ChannelID,
        ChannelCategoryID,
        ChannelName,
        ChannelCategory
    )
SELECT
    CAST(c.ChannelID AS INT) AS ChannelID,
    -- the inital data had these as character dataype hence typecasting to integer
    CAST(c.ChannelCategoryID AS INT) AS ChannelCategoryID,
    c.Channel,
    ccat.ChannelCategory,
FROM
    STAGING_CHANNEL c
    LEFT JOIN STAGING_CHANNELCATEGORY ccat ON c.CHANNELCATEGORYID = ccat.CHANNELCATEGORYID;
INSERT INTO
    DIM_CHANNEL (
        DimChannelID,
        ChannelID,
        ChannelCategoryID,
        ChannelName,
        ChannelCategory
    )
VALUES
    (
        -1,
        -1,
        -1,
        'Unknown',
        'Unknown'
    );
SELECT
    *
FROM
    DIM_CHANNEL;
--creating location table: Here we are trying to dump all the location-related data from all the that have location feild into this one location table which we will use to further join  with other tables based on the location match found.
    CREATE
    OR REPLACE TABLE DIM_LOCATION(
        DimLocationID INT AUTOINCREMENT PRIMARY KEY,
        Address VARCHAR(255),
        City VARCHAR(255),
        State_Province VARCHAR(255),
        PostalCode VARCHAR(255),
        Country VARCHAR(255)
    );
INSERT INTO
    DIM_LOCATION(
        Address,
        City,
        State_Province,
        PostalCode,
        Country
    )
SELECT
    r.Address AS Address,
    r.City AS City,
    r.StateProvince AS State_Province,
    r.PostalCode AS PostalCode,
    r.Country AS Country
FROM
    STAGING_RESELLER r
UNION
SELECT
    c.Address AS Address,
    c.City AS City,
    c.StateProvince AS State_Province,
    c.PostalCode AS PostalCode,
    c.Country AS Country
FROM
    STAGING_CUSTOMER c
UNION
SELECT
    s.Address AS Address,
    s.City AS City,
    s.StateProvince AS State_Province,
    s.PostalCode AS PostalCode,
    s.Country AS Country
FROM
    STAGING_STORE s;
SELECT
    *
FROM
    DIM_LOCATION;
-- Creating the store table
    CREATE
    OR REPLACE TABLE DIM_STORE(
        DimStoreID INT IDENTITY(1, 1) CONSTRAINT PK_DimStoreID PRIMARY KEY NOT NULL,
        DimLocationID INT,
        SourceStoreID INT,
        StoreNumber INT,
        StoreManager VARCHAR(255),
        CONSTRAINT FK_Store_Location FOREIGN KEY (DimLocationID) REFERENCES DIM_LOCATION(DimLocationID)
    );
INSERT INTO
    Dim_Store (
        DimLocationID,
        SourceStoreID,
        StoreNumber,
        StoreManager
    )
SELECT
    l.DimLocationID,
    CAST(s.STOREID AS INT) AS SourceStoreID,
    CAST(s.STORENUMBER AS INT),
    s.STOREMANAGER
FROM
    STAGING_STORE s
    JOIN Dim_Location l ON s.ADDRESS = l.Address
    AND s.CITY = l.City
    AND s.POSTALCODE = l.PostalCode
    AND s.STATEPROVINCE = l.State_Province
    AND s.COUNTRY = l.Country;
SELECT
    *
FROM
    DIM_STORE;
INSERT INTO
    DIM_STORE (
        DimStoreID,
        DimLocationID,
        SourceStoreID,
        StoreNumber,
        StoreManager
    )
VALUES
    (
        -1,
        -1,
        -1,
        -1,
        'Unknown'
    );
SELECT
    *
FROM
    DIM_STORE;
-- CREATING THE RESELLER TABLE;
    CREATE
    OR REPLACE TABLE Dim_Reseller(
        DimResellerID INT IDENTITY(1, 1) CONSTRAINT PK_DimResellerID PRIMARY KEY NOT NULL,
        DimLocationID INT,
        ResellerID VARCHAR(255),
        ResellerName VARCHAR(255),
        ContactName VARCHAR(255),
        PhoneNumber VARCHAR(255),
        Email VARCHAR(255),
        CONSTRAINT FK_Reseler_Location FOREIGN KEY (DimLocationID) REFERENCES DIM_LOCATION(DimLocationID)
    );
INSERT INTO
    Dim_Reseller (
        DimLocationID,
        ResellerID,
        ResellerName,
        ContactName,
        PhoneNumber,
        Email
    )
SELECT
    l.DimLocationID,
    r.RESELLERID,
    r.RESELLERNAME,
    r.CONTACT AS ContactName,
    r.PHONENUMBER AS PhoneNumber,
    r.EMAILADDRESS AS Email
FROM
    STAGING_RESELLER r
    JOIN Dim_Location l ON r.ADDRESS = l.Address
    AND r.CITY = l.City
    AND r.POSTALCODE = l.PostalCode
    AND r.STATEPROVINCE = l.State_Province
    AND r.COUNTRY = l.Country;
SELECT
    *
FROM
    DIM_RESELLER;
INSERT INTO
    DIM_RESELLER (
        DimResellerID,
        DimLocationID,
        ResellerID,
        ResellerName,
        ContactName,
        PhoneNumber,
        Email
    )
VALUES
    (
        -1,
        -1,
        'Unknown',
        'Unknown',
        'Unknown',
        'Unknown',
        'Unknown'
    );
--CREATING CUSTOMER TABLE;
    CREATE
    OR REPLACE TABLE DIM_CUSTOMER(
        DimCustomerID INT IDENTITY(1, 1) CONSTRAINT PK_DimCustomerID PRIMARY KEY NOT NULL,
        DimLocationID INT,
        CUSTOMERID VARCHAR(255),
        CustomerFullName VARCHAR(255),
        CustomerFirstName VARCHAR(255),
        CustomerLastName VARCHAR(255),
        CustomerGender VARCHAR(255),
        CONSTRAINT FK_Customer_Location FOREIGN KEY (DimLocationID) REFERENCES DIM_LOCATION(DimLocationID)
    );
INSERT INTO
    DIM_CUSTOMER (
        DimLocationID,
        CUSTOMERID,
        CustomerFullName,
        CustomerFirstName,
        CustomerLastName,
        CustomerGender
    )
SELECT
    COALESCE(CAST(L.DimLocationID AS INT), -1) AS DimLocationID,
    -- Use -1 if DimLocationID is missing
    C.CUSTOMERID,
    CONCAT(C.FIRSTNAME, ' ', C.LASTNAME) AS CustomerFullName,
    C.FIRSTNAME AS CustomerFirstName,
    C.LASTNAME AS CustomerLastName,
    C.GENDER AS CustomerGender,
FROM
    STAGING_CUSTOMER C
    LEFT JOIN DIM_LOCATION L ON C.ADDRESS = L.Address
    AND C.CITY = L.City
    AND C.POSTALCODE = L.PostalCode
    AND C.STATEPROVINCE = L.State_Province
    AND C.COUNTRY = L.Country;
SELECT
    *
FROM
    DIM_CUSTOMER;
INSERT INTO
    DIM_CUSTOMER (
        DimCustomerID,
        DimLocationID,
        CUSTOMERID,
        CustomerFullName,
        CustomerFirstName,
        CustomerLastName,
        CustomerGender
    )
VALUES
    (
        -1,
        -1,
        'Unknown',
        'Unknown',
        'Unknown',
        'Unknown',
        'Unknown'
    );
--CREATING THE DATE TABLE
    /*****************************************
    Course: IMT 577
    Assignment: Module 6
    Notes: Create Dim Date and load with
    two years of dates. Loads 20 years of 
    dates.
    
    *****************************************/
    --===================================================
    -------------DIM_DATE
    --==================================================
    -- Create table script for Dimension DIM_DATE
    create
    or replace table DIM_DATE (
        DATE_PKEY number(9) PRIMARY KEY,
        DATE date not null,
        FULL_DATE_DESC varchar(64) not null,
        DAY_NUM_IN_WEEK number(1) not null,
        DAY_NUM_IN_MONTH number(2) not null,
        DAY_NUM_IN_YEAR number(3) not null,
        DAY_NAME varchar(10) not null,
        DAY_ABBREV varchar(3) not null,
        WEEKDAY_IND varchar(64) not null,
        US_HOLIDAY_IND varchar(64) not null,
        /*<COMPANYNAME>*/
        _HOLIDAY_IND varchar(64) not null,
        MONTH_END_IND varchar(64) not null,
        WEEK_BEGIN_DATE_NKEY number(9) not null,
        WEEK_BEGIN_DATE date not null,
        WEEK_END_DATE_NKEY number(9) not null,
        WEEK_END_DATE date not null,
        WEEK_NUM_IN_YEAR number(9) not null,
        MONTH_NAME varchar(10) not null,
        MONTH_ABBREV varchar(3) not null,
        MONTH_NUM_IN_YEAR number(2) not null,
        YEARMONTH varchar(10) not null,
        QUARTER number(1) not null,
        YEARQUARTER varchar(10) not null,
        YEAR number(5) not null,
        FISCAL_WEEK_NUM number(2) not null,
        FISCAL_MONTH_NUM number(2) not null,
        FISCAL_YEARMONTH varchar(10) not null,
        FISCAL_QUARTER number(1) not null,
        FISCAL_YEARQUARTER varchar(10) not null,
        FISCAL_HALFYEAR number(1) not null,
        FISCAL_YEAR number(5) not null,
        SQL_TIMESTAMP timestamp_ntz,
        CURRENT_ROW_IND char(1) default 'Y',
        EFFECTIVE_DATE date default to_date(current_timestamp),
        EXPIRATION_DATE date default To_date('9999-12-31')
    ) comment = 'Type 0 Dimension Table Housing Calendar and Fiscal Year Date Attributes';
-- Populate data into DIM_DATE
insert into
    DIM_DATE
select
    DATE_PKEY,
    DATE_COLUMN,
    FULL_DATE_DESC,
    DAY_NUM_IN_WEEK,
    DAY_NUM_IN_MONTH,
    DAY_NUM_IN_YEAR,
    DAY_NAME,
    DAY_ABBREV,
    WEEKDAY_IND,
    US_HOLIDAY_IND,
    COMPANY_HOLIDAY_IND,
    MONTH_END_IND,
    WEEK_BEGIN_DATE_NKEY,
    WEEK_BEGIN_DATE,
    WEEK_END_DATE_NKEY,
    WEEK_END_DATE,
    WEEK_NUM_IN_YEAR,
    MONTH_NAME,
    MONTH_ABBREV,
    MONTH_NUM_IN_YEAR,
    YEARMONTH,
    CURRENT_QUARTER,
    YEARQUARTER,
    CURRENT_YEAR,
    FISCAL_WEEK_NUM,
    FISCAL_MONTH_NUM,
    FISCAL_YEARMONTH,
    FISCAL_QUARTER,
    FISCAL_YEARQUARTER,
    FISCAL_HALFYEAR,
    FISCAL_YEAR,
    SQL_TIMESTAMP,
    CURRENT_ROW_IND,
    EFFECTIVE_DATE,
    EXPIRA_DATE
from
    --( select to_date('01-25-2019 23:25:11.120','MM-DD-YYYY HH24:MI:SS.FF') as DD, /*<<Modify date for preferred table start date*/
    --( select to_date('2013-01-01 00:00:01','YYYY-MM-DD HH24:MI:SS') as DD, /*<<Modify date for preferred table start date*/
    (
        select
            to_date('2012-12-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS') as DD,
            /*<<Modify date for preferred table start date*/
            seq1() as Sl,
            row_number() over (
                order by
                    Sl
            ) as row_numbers,
            dateadd(day, row_numbers, DD) as V_DATE,
            case
                when date_part(dd, V_DATE) < 10
                and date_part(mm, V_DATE) > 9 then date_part(year, V_DATE) || date_part(mm, V_DATE) || '0' || date_part(dd, V_DATE)
                when date_part(dd, V_DATE) < 10
                and date_part(mm, V_DATE) < 10 then date_part(year, V_DATE) || '0' || date_part(mm, V_DATE) || '0' || date_part(dd, V_DATE)
                when date_part(dd, V_DATE) > 9
                and date_part(mm, V_DATE) < 10 then date_part(year, V_DATE) || '0' || date_part(mm, V_DATE) || date_part(dd, V_DATE)
                when date_part(dd, V_DATE) > 9
                and date_part(mm, V_DATE) > 9 then date_part(year, V_DATE) || date_part(mm, V_DATE) || date_part(dd, V_DATE)
            end as DATE_PKEY,
            V_DATE as DATE_COLUMN,
            dayname(dateadd(day, row_numbers, DD)) as DAY_NAME_1,
            case
                when dayname(dateadd(day, row_numbers, DD)) = 'Mon' then 'Monday'
                when dayname(dateadd(day, row_numbers, DD)) = 'Tue' then 'Tuesday'
                when dayname(dateadd(day, row_numbers, DD)) = 'Wed' then 'Wednesday'
                when dayname(dateadd(day, row_numbers, DD)) = 'Thu' then 'Thursday'
                when dayname(dateadd(day, row_numbers, DD)) = 'Fri' then 'Friday'
                when dayname(dateadd(day, row_numbers, DD)) = 'Sat' then 'Saturday'
                when dayname(dateadd(day, row_numbers, DD)) = 'Sun' then 'Sunday'
            end || ', ' || case
                when monthname(dateadd(day, row_numbers, DD)) = 'Jan' then 'January'
                when monthname(dateadd(day, row_numbers, DD)) = 'Feb' then 'February'
                when monthname(dateadd(day, row_numbers, DD)) = 'Mar' then 'March'
                when monthname(dateadd(day, row_numbers, DD)) = 'Apr' then 'April'
                when monthname(dateadd(day, row_numbers, DD)) = 'May' then 'May'
                when monthname(dateadd(day, row_numbers, DD)) = 'Jun' then 'June'
                when monthname(dateadd(day, row_numbers, DD)) = 'Jul' then 'July'
                when monthname(dateadd(day, row_numbers, DD)) = 'Aug' then 'August'
                when monthname(dateadd(day, row_numbers, DD)) = 'Sep' then 'September'
                when monthname(dateadd(day, row_numbers, DD)) = 'Oct' then 'October'
                when monthname(dateadd(day, row_numbers, DD)) = 'Nov' then 'November'
                when monthname(dateadd(day, row_numbers, DD)) = 'Dec' then 'December'
            end || ' ' || to_varchar(dateadd(day, row_numbers, DD), ' dd, yyyy') as FULL_DATE_DESC,
            dateadd(day, row_numbers, DD) as V_DATE_1,
            dayofweek(V_DATE_1) + 1 as DAY_NUM_IN_WEEK,
            Date_part(dd, V_DATE_1) as DAY_NUM_IN_MONTH,
            dayofyear(V_DATE_1) as DAY_NUM_IN_YEAR,
            case
                when dayname(V_DATE_1) = 'Mon' then 'Monday'
                when dayname(V_DATE_1) = 'Tue' then 'Tuesday'
                when dayname(V_DATE_1) = 'Wed' then 'Wednesday'
                when dayname(V_DATE_1) = 'Thu' then 'Thursday'
                when dayname(V_DATE_1) = 'Fri' then 'Friday'
                when dayname(V_DATE_1) = 'Sat' then 'Saturday'
                when dayname(V_DATE_1) = 'Sun' then 'Sunday'
            end as DAY_NAME,
            dayname(dateadd(day, row_numbers, DD)) as DAY_ABBREV,
            case
                when dayname(V_DATE_1) = 'Sun'
                and dayname(V_DATE_1) = 'Sat' then 'Not-Weekday'
                else 'Weekday'
            end as WEEKDAY_IND,
            case
                when (
                    DATE_PKEY = date_part(year, V_DATE) || '0101'
                    or DATE_PKEY = date_part(year, V_DATE) || '0704'
                    or DATE_PKEY = date_part(year, V_DATE) || '1225'
                    or DATE_PKEY = date_part(year, V_DATE) || '1226'
                ) then 'Holiday'
                when monthname(V_DATE_1) = 'May'
                and dayname(last_day(V_DATE_1)) = 'Wed'
                and dateadd(day, -2, last_day(V_DATE_1)) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'May'
                and dayname(last_day(V_DATE_1)) = 'Thu'
                and dateadd(day, -3, last_day(V_DATE_1)) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'May'
                and dayname(last_day(V_DATE_1)) = 'Fri'
                and dateadd(day, -4, last_day(V_DATE_1)) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'May'
                and dayname(last_day(V_DATE_1)) = 'Sat'
                and dateadd(day, -5, last_day(V_DATE_1)) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'May'
                and dayname(last_day(V_DATE_1)) = 'Sun'
                and dateadd(day, -6, last_day(V_DATE_1)) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'May'
                and dayname(last_day(V_DATE_1)) = 'Mon'
                and last_day(V_DATE_1) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'May'
                and dayname(last_day(V_DATE_1)) = 'Tue'
                and dateadd(day, -1, last_day(V_DATE_1)) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Wed'
                and dateadd(day, 5,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Thu'
                and dateadd(day, 4,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Fri'
                and dateadd(day, 3,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Sat'
                and dateadd(day, 2,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Sun'
                and dateadd(day, 1,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Mon'
                and date_part(year, V_DATE_1) || '-09-01' = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Tue'
                and dateadd(day, 6,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Wed'
                and (
                    dateadd(day, 23,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                    or dateadd(day, 22,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                ) then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Thu'
                and (
                    dateadd(day, 22,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                    or dateadd(day, 21,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                ) then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Fri'
                and (
                    dateadd(day, 21,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                    or dateadd(day, 20,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                ) then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Sat'
                and (
                    dateadd(day, 27,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                    or dateadd(day, 26,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                ) then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Sun'
                and (
                    dateadd(day, 26,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                    or dateadd(day, 25,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                ) then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Mon'
                and (
                    dateadd(day, 25,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                    or dateadd(day, 24,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                ) then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Tue'
                and (
                    dateadd(day, 24,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                    or dateadd(day, 23,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1
                ) then 'Holiday'
                else 'Not-Holiday'
            end as US_HOLIDAY_IND,
            /*Modify the following for Company Specific Holidays*/
            case
                when (
                    DATE_PKEY = date_part(year, V_DATE) || '0101'
                    or DATE_PKEY = date_part(year, V_DATE) || '0219'
                    or DATE_PKEY = date_part(year, V_DATE) || '0528'
                    or DATE_PKEY = date_part(year, V_DATE) || '0704'
                    or DATE_PKEY = date_part(year, V_DATE) || '1225'
                ) then 'Holiday'
                when monthname(V_DATE_1) = 'Mar'
                and dayname(last_day(V_DATE_1)) = 'Fri'
                and last_day(V_DATE_1) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Mar'
                and dayname(last_day(V_DATE_1)) = 'Sat'
                and dateadd(day, -1, last_day(V_DATE_1)) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Mar'
                and dayname(last_day(V_DATE_1)) = 'Sun'
                and dateadd(day, -2, last_day(V_DATE_1)) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Tue'
                and dateadd(day, 3,(date_part(year, V_DATE_1) || '-04-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Wed'
                and dateadd(day, 2,(date_part(year, V_DATE_1) || '-04-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Thu'
                and dateadd(day, 1,(date_part(year, V_DATE_1) || '-04-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Fri'
                and date_part(year, V_DATE_1) || '-04-01' = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Wed'
                and dateadd(day, 5,(date_part(year, V_DATE_1) || '-04-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Thu'
                and dateadd(day, 4,(date_part(year, V_DATE_1) || '-04-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Fri'
                and dateadd(day, 3,(date_part(year, V_DATE_1) || '-04-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Sat'
                and dateadd(day, 2,(date_part(year, V_DATE_1) || '-04-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Sun'
                and dateadd(day, 1,(date_part(year, V_DATE_1) || '-04-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Mon'
                and date_part(year, V_DATE_1) || '-04-01' = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Apr'
                and dayname(date_part(year, V_DATE_1) || '-04-01') = 'Tue'
                and dateadd(day, 6,(date_part(year, V_DATE_1) || '-04-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Wed'
                and dateadd(day, 5,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Thu'
                and dateadd(day, 4,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Fri'
                and dateadd(day, 3,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Sat'
                and dateadd(day, 2,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Sun'
                and dateadd(day, 1,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Mon'
                and date_part(year, V_DATE_1) || '-09-01' = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Sep'
                and dayname(date_part(year, V_DATE_1) || '-09-01') = 'Tue'
                and dateadd(day, 6,(date_part(year, V_DATE_1) || '-09-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Wed'
                and dateadd(day, 23,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Thu'
                and dateadd(day, 22,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Fri'
                and dateadd(day, 21,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Sat'
                and dateadd(day, 27,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Sun'
                and dateadd(day, 26,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Mon'
                and dateadd(day, 25,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1 then 'Holiday'
                when monthname(V_DATE_1) = 'Nov'
                and dayname(date_part(year, V_DATE_1) || '-11-01') = 'Tue'
                and dateadd(day, 24,(date_part(year, V_DATE_1) || '-11-01')) = V_DATE_1 then 'Holiday'
                else 'Not-Holiday'
            end as COMPANY_HOLIDAY_IND,
            case
                when last_day(V_DATE_1) = V_DATE_1 then 'Month-end'
                else 'Not-Month-end'
            end as MONTH_END_IND,
            case
                when date_part(mm, date_trunc('week', V_DATE_1)) < 10
                and date_part(dd, date_trunc('week', V_DATE_1)) < 10 then date_part(yyyy, date_trunc('week', V_DATE_1)) || '0' || date_part(mm, date_trunc('week', V_DATE_1)) || '0' || date_part(dd, date_trunc('week', V_DATE_1))
                when date_part(mm, date_trunc('week', V_DATE_1)) < 10
                and date_part(dd, date_trunc('week', V_DATE_1)) > 9 then date_part(yyyy, date_trunc('week', V_DATE_1)) || '0' || date_part(mm, date_trunc('week', V_DATE_1)) || date_part(dd, date_trunc('week', V_DATE_1))
                when date_part(mm, date_trunc('week', V_DATE_1)) > 9
                and date_part(dd, date_trunc('week', V_DATE_1)) < 10 then date_part(yyyy, date_trunc('week', V_DATE_1)) || date_part(mm, date_trunc('week', V_DATE_1)) || '0' || date_part(dd, date_trunc('week', V_DATE_1))
                when date_part(mm, date_trunc('week', V_DATE_1)) > 9
                and date_part(dd, date_trunc('week', V_DATE_1)) > 9 then date_part(yyyy, date_trunc('week', V_DATE_1)) || date_part(mm, date_trunc('week', V_DATE_1)) || date_part(dd, date_trunc('week', V_DATE_1))
            end as WEEK_BEGIN_DATE_NKEY,
            date_trunc('week', V_DATE_1) as WEEK_BEGIN_DATE,
            case
                when date_part(mm, last_day(V_DATE_1, 'week')) < 10
                and date_part(dd, last_day(V_DATE_1, 'week')) < 10 then date_part(yyyy, last_day(V_DATE_1, 'week')) || '0' || date_part(mm, last_day(V_DATE_1, 'week')) || '0' || date_part(dd, last_day(V_DATE_1, 'week'))
                when date_part(mm, last_day(V_DATE_1, 'week')) < 10
                and date_part(dd, last_day(V_DATE_1, 'week')) > 9 then date_part(yyyy, last_day(V_DATE_1, 'week')) || '0' || date_part(mm, last_day(V_DATE_1, 'week')) || date_part(dd, last_day(V_DATE_1, 'week'))
                when date_part(mm, last_day(V_DATE_1, 'week')) > 9
                and date_part(dd, last_day(V_DATE_1, 'week')) < 10 then date_part(yyyy, last_day(V_DATE_1, 'week')) || date_part(mm, last_day(V_DATE_1, 'week')) || '0' || date_part(dd, last_day(V_DATE_1, 'week'))
                when date_part(mm, last_day(V_DATE_1, 'week')) > 9
                and date_part(dd, last_day(V_DATE_1, 'week')) > 9 then date_part(yyyy, last_day(V_DATE_1, 'week')) || date_part(mm, last_day(V_DATE_1, 'week')) || date_part(dd, last_day(V_DATE_1, 'week'))
            end as WEEK_END_DATE_NKEY,
            last_day(V_DATE_1, 'week') as WEEK_END_DATE,
            week(V_DATE_1) as WEEK_NUM_IN_YEAR,
            case
                when monthname(V_DATE_1) = 'Jan' then 'January'
                when monthname(V_DATE_1) = 'Feb' then 'February'
                when monthname(V_DATE_1) = 'Mar' then 'March'
                when monthname(V_DATE_1) = 'Apr' then 'April'
                when monthname(V_DATE_1) = 'May' then 'May'
                when monthname(V_DATE_1) = 'Jun' then 'June'
                when monthname(V_DATE_1) = 'Jul' then 'July'
                when monthname(V_DATE_1) = 'Aug' then 'August'
                when monthname(V_DATE_1) = 'Sep' then 'September'
                when monthname(V_DATE_1) = 'Oct' then 'October'
                when monthname(V_DATE_1) = 'Nov' then 'November'
                when monthname(V_DATE_1) = 'Dec' then 'December'
            end as MONTH_NAME,
            monthname(V_DATE_1) as MONTH_ABBREV,
            month(V_DATE_1) as MONTH_NUM_IN_YEAR,
            case
                when month(V_DATE_1) < 10 then year(V_DATE_1) || '-0' || month(V_DATE_1)
                else year(V_DATE_1) || '-' || month(V_DATE_1)
            end as YEARMONTH,
            quarter(V_DATE_1) as CURRENT_QUARTER,
            year(V_DATE_1) || '-0' || quarter(V_DATE_1) as YEARQUARTER,
            year(V_DATE_1) as CURRENT_YEAR,
            /*Modify the following based on company fiscal year - assumes Jan 01*/
            to_date(year(V_DATE_1) || '-01-01', 'YYYY-MM-DD') as FISCAL_CUR_YEAR,
            to_date(year(V_DATE_1) -1 || '-01-01', 'YYYY-MM-DD') as FISCAL_PREV_YEAR,
            case
                when V_DATE_1 < FISCAL_CUR_YEAR then datediff('week', FISCAL_PREV_YEAR, V_DATE_1)
                else datediff('week', FISCAL_CUR_YEAR, V_DATE_1)
            end as FISCAL_WEEK_NUM,
            decode(
                datediff('MONTH', FISCAL_CUR_YEAR, V_DATE_1) + 1,
                -2,
                10,
                -1,
                11,
                0,
                12,
                datediff('MONTH', FISCAL_CUR_YEAR, V_DATE_1) + 1
            ) as FISCAL_MONTH_NUM,
            concat(
                year(FISCAL_CUR_YEAR),case
                    when to_number(FISCAL_MONTH_NUM) = 10
                    or to_number(FISCAL_MONTH_NUM) = 11
                    or to_number(FISCAL_MONTH_NUM) = 12 then '-' || FISCAL_MONTH_NUM
                    else concat('-0', FISCAL_MONTH_NUM)
                end
            ) as FISCAL_YEARMONTH,
            case
                when quarter(V_DATE_1) = 4 then 4
                when quarter(V_DATE_1) = 3 then 3
                when quarter(V_DATE_1) = 2 then 2
                when quarter(V_DATE_1) = 1 then 1
            end as FISCAL_QUARTER,
            case
                when V_DATE_1 < FISCAL_CUR_YEAR then year(FISCAL_CUR_YEAR)
                else year(FISCAL_CUR_YEAR) + 1
            end || '-0' ||case
                when quarter(V_DATE_1) = 4 then 4
                when quarter(V_DATE_1) = 3 then 3
                when quarter(V_DATE_1) = 2 then 2
                when quarter(V_DATE_1) = 1 then 1
            end as FISCAL_YEARQUARTER,
            case
                when quarter(V_DATE_1) = 4 then 2
                when quarter(V_DATE_1) = 3 then 2
                when quarter(V_DATE_1) = 1 then 1
                when quarter(V_DATE_1) = 2 then 1
            end as FISCAL_HALFYEAR,
            year(FISCAL_CUR_YEAR) as FISCAL_YEAR,
            to_timestamp_ntz(V_DATE) as SQL_TIMESTAMP,
            'Y' as CURRENT_ROW_IND,
            to_date(current_timestamp) as EFFECTIVE_DATE,
            to_date('9999-12-31') as EXPIRA_DATE --from table(generator(rowcount => 8401)) /*<< Set to generate 20 years. Modify rowcount to increase or decrease size*/
        from
            table(generator(rowcount => 730))
            /*<< Set to generate 20 years. Modify rowcount to increase or decrease size*/
    ) v;
--Miscellaneous queries
    --select * from  DIM_DATE
    --ORDER BY DATE;
    --delete from DIM_DATE;
    --drop table DIM_DATE;
    ------------FACT TABLES---------------
    -- Create the Fact_ProductSalesTarget table
    -- This fact table stores annual product-level sales quantity targets
    CREATE
    OR REPLACE TABLE Fact_ProductSalesTarget (
        DimProductID INT NOT NULL,
        -- Foreign key to Dim_Product table (Product dimension)
        DimTargetDateID NUMBER(9) NOT NULL,
        -- Foreign key to DIM_DATE; uses surrogate key for January 1 of the target year
        ProductTargetSalesQuantity INT NOT NULL,
        -- Target quantity for product sales in that year
        CONSTRAINT FK_Product FOREIGN KEY (DimProductID) REFERENCES Dim_Product(DimProductID),
        CONSTRAINT FK_TargetDate FOREIGN KEY (DimTargetDateID) REFERENCES DIM_DATE(DATE_PKEY)
    );
-- Load data into Fact_ProductSalesTarget from the staging table
    -- Uses COALESCE to default target quantity to 0 when missing
    -- Joins with DIM_DATE on year, choosing January 1st as representative for annual target
INSERT INTO
    Fact_ProductSalesTarget (
        DimProductID,
        DimTargetDateID,
        ProductTargetSalesQuantity
    )
SELECT
    p.DimProductID,
    -- Look up product surrogate key
    d.DATE_PKEY AS DimTargetDateID,
    -- Use Jan 1st of the year as target date key
    COALESCE(tp.SalesQuantityTarget, 0) AS ProductTargetSalesQuantity -- Ensure null targets are loaded as 0
FROM
    Staging_TargetDataProduct tp
    JOIN Dim_Product p ON tp.ProductID = p.ProductID
    JOIN DIM_DATE d ON tp.Year = d.YEAR
    AND d.MONTH_NUM_IN_YEAR = 1 -- Use January
    AND d.DAY_NUM_IN_MONTH = 1;
-- Use first day of the month
    -- Verify loaded data
SELECT
    *
FROM
    Fact_ProductSalesTarget;
-- Create Fact_SRCSalesTarget table
    -- This fact table stores annual sales amount targets for Store, Reseller, or Channel
    CREATE
    OR REPLACE TABLE Fact_SRCSalesTarget (
        DimStoreID INT,
        -- Optional foreign key to Dim_Store; will be -1 for non-store targets
        DimResellerID INT,
        -- Optional foreign key to Dim_Reseller; will be -1 for non-reseller targets
        DimChannelID INT,
        -- Foreign key to Dim_Channel; required for all records
        DimTargetDateID NUMBER(9) NOT NULL,
        -- Foreign key to DIM_DATE; always January 1 of target year
        SalesTargetAmount FLOAT NOT NULL,
        -- Annual target amount for the store/reseller/channel
        CONSTRAINT FK_SRC_Store FOREIGN KEY (DimStoreID) REFERENCES Dim_Store(DimStoreID),
        CONSTRAINT FK_SRC_Reseller FOREIGN KEY (DimResellerID) REFERENCES Dim_Reseller(DimResellerID),
        CONSTRAINT FK_SRC_Channel FOREIGN KEY (DimChannelID) REFERENCES Dim_Channel(DimChannelID),
        CONSTRAINT FK_SRC_TargetDate FOREIGN KEY (DimTargetDateID) REFERENCES DIM_DATE(DATE_PKEY)
    );
-- Load data into Fact_SRCSalesTarget
    -- Applies COALESCE to handle missing sales target values
    -- Uses conditional joins based on target type (Store or Reseller)
    -- All records use January 1 as target date surrogate
INSERT INTO
    Fact_SRCSalesTarget (
        DimStoreID,
        DimResellerID,
        DimChannelID,
        DimTargetDateID,
        SalesTargetAmount
    )
SELECT
    CASE
        WHEN tdc.TargetName = 'Store' THEN s.DimStoreID
        ELSE -1
    END AS DimStoreID,
    -- Assign -1 if not Store
    CASE
        WHEN tdc.TargetName = 'Reseller' THEN r.DimResellerID
        ELSE -1
    END AS DimResellerID,
    -- Assign -1 if not Reseller
    COALESCE(c.DimChannelID, -1) AS DimChannelID,
    -- Lookup channel ID or assign -1
    d.DATE_PKEY AS DimTargetDateID,
    -- January 1 date key for the target year
    COALESCE(tdc.TargetSalesAmount, 0) AS SalesTargetAmount -- Default missing values to 0
FROM
    Staging_TargetDataChannel tdc
    LEFT JOIN Dim_Channel c ON tdc.ChannelName = c.ChannelName
    LEFT JOIN Dim_Store s ON tdc.TargetName = 'Store' -- Only join store dimension for 'Store' targets
    LEFT JOIN Dim_Reseller r ON tdc.TargetName = 'Reseller' -- Only join reseller dimension for 'Reseller' targets
    JOIN DIM_DATE d ON tdc.Year = d.YEAR
    AND d.MONTH_NUM_IN_YEAR = 1 -- Use January
    AND d.DAY_NUM_IN_MONTH = 1;
-- Use first day of the month
    -- Verify loaded data
SELECT
    *
FROM
    Fact_SRCSalesTarget;
SELECT
    *
FROM
    Staging_TargetDataChannel;
INSERT INTO
    Fact_SRCSalesTarget (
        DimStoreID,
        DimChannelID,
        DimResellerID,
        DimTargetDateID,
        SalesTargetAmount
    )
SELECT
    COALESCE(ds.DIMSTOREID, -1) AS DimStoreID,
    COALESCE(dc.DIMCHANNELID, -1) AS DimChannelID,
    COALESCE(dr.DIMRESELLERID, -1) AS DimResllerID,
    COALESCE(dd.DATE_PKEY, -1) AS DimTargetDateID,
    stdc.TargetSalesAmount / 365 AS SalesTargetAmount
FROM
    STAGING_TARGETDATACHANNEL stdc
    LEFT JOIN DIM_CHANNEL dc ON stdc.ChannelName = dc.CHANNELNAME
    LEFT JOIN Dim_Store ds ON (
        CASE
            WHEN stdc.TargetName = 'Store Number 5' THEN CAST('5' AS INT)
            WHEN stdc.TargetName = 'Store Number 8' THEN CAST('8' AS INT)
            WHEN stdc.TargetName = 'Store Number 10' THEN CAST('10' AS INT)
            WHEN stdc.TargetName = 'Store Number 21' THEN CAST('21' AS INT)
            WHEN stdc.TargetName = 'Store Number 34' THEN CAST('34' AS INT)
            WHEN stdc.TargetName = 'Store Number 39' THEN CAST('39' AS INT)
            WHEN stdc.TargetName = 'Store Number 39' THEN CAST('39' AS INT)
            ELSE -1
        END
    ) = ds.StoreNumber --the store number in the store table is in the form of 5,8,11, and in the stage target table its store number 34, hence changing names.
    LEFT JOIN Dim_Reseller dr ON dr.ResellerName = stdc.TargetName
    LEFT JOIN DIM_DATE dd ON stdc.Year = dd.FISCAL_YEAR;
-- Create Fact_SalesActual table
    -- This fact table captures all individual sales transactions (actuals)
    CREATE
    OR REPLACE TABLE Fact_SalesActual (
        DimProductID INT NOT NULL,
        -- Foreign key to product dimension
        DimStoreID INT NOT NULL,
        -- Foreign key to store dimension or -1 if unknown
        DimResellerID INT NOT NULL,
        -- Foreign key to reseller dimension or -1 if unknown
        DimCustomerID INT NOT NULL,
        -- Foreign key to customer dimension or -1 if unknown
        DimChannelID INT NOT NULL,
        -- Foreign key to channel dimension
        DimSaleDateID NUMBER(9) NOT NULL,
        -- Surrogate key from DIM_DATE for date of sale
        DimLocationID INT NOT NULL,
        -- Derived from associated store/reseller/customer
        SalesHeaderID INT,
        -- Optional transaction header ID
        SalesDetailID INT,
        -- Optional transaction detail ID
        SaleAmount FLOAT NOT NULL,
        -- Total sale amount
        SaleQuantity INT NOT NULL,
        -- Quantity sold
        SaleUnitPrice FLOAT NOT NULL,
        -- Derived unit price per item
        SaleExtendedCost FLOAT NOT NULL,
        -- Total cost for the quantity sold (ProductCost * Quantity)
        SaleTotalProfit FLOAT NOT NULL,
        -- SaleAmount - ExtendedCost
        CONSTRAINT FK_Sales_Product FOREIGN KEY (DimProductID) REFERENCES Dim_Product(DimProductID),
        CONSTRAINT FK_Sales_Store FOREIGN KEY (DimStoreID) REFERENCES Dim_Store(DimStoreID),
        CONSTRAINT FK_Sales_Reseller FOREIGN KEY (DimResellerID) REFERENCES Dim_Reseller(DimResellerID),
        CONSTRAINT FK_Sales_Customer FOREIGN KEY (DimCustomerID) REFERENCES Dim_Customer(DimCustomerID),
        CONSTRAINT FK_Sales_Channel FOREIGN KEY (DimChannelID) REFERENCES Dim_Channel(DimChannelID),
        CONSTRAINT FK_Sales_Date FOREIGN KEY (DimSaleDateID) REFERENCES DIM_DATE(DATE_PKEY),
        CONSTRAINT FK_Sales_Location FOREIGN KEY (DimLocationID) REFERENCES Dim_Location(DimLocationID)
    );
-- Insert actual sales data with logic to resolve missing/optional dimension relationships
    -- Includes null-safe math and surrogate keys for unknown values (-1)
INSERT INTO
    Fact_SalesActual (
        DimProductID,
        DimStoreID,
        DimResellerID,
        DimCustomerID,
        DimChannelID,
        DimSaleDateID,
        DimLocationID,
        SalesHeaderID,
        SalesDetailID,
        SaleAmount,
        SaleQuantity,
        SaleUnitPrice,
        SaleExtendedCost,
        SaleTotalProfit
    )
SELECT
    COALESCE(p.DimProductID, -1) AS DimProductID,
    -- Default to -1 if product not found
    CASE
        WHEN sh.StoreID IS NOT NULL THEN COALESCE(s.DimStoreID, -1)
        ELSE -1
    END AS DimStoreID,
    -- Assign store ID if present; else -1
    CASE
        WHEN sh.ResellerID IS NOT NULL THEN COALESCE(r.DimResellerID, -1)
        ELSE -1
    END AS DimResellerID,
    -- Assign reseller ID if present; else -1
    CASE
        WHEN sh.CustomerID IS NOT NULL THEN COALESCE(c.DimCustomerID, -1)
        ELSE -1
    END AS DimCustomerID,
    -- Assign customer ID if present; else -1
    COALESCE(ch.DimChannelID, -1) AS DimChannelID,
    -- Assign channel ID or -1 if missing
    COALESCE(d.DATE_PKEY, 20130101) AS DimSaleDateID,
    -- Assign default date key if lookup fails
    COALESCE(
        CASE
            WHEN sh.StoreID IS NOT NULL THEN s.DimLocationID
            WHEN sh.ResellerID IS NOT NULL THEN r.DimLocationID
            WHEN sh.CustomerID IS NOT NULL THEN c.DimLocationID
            ELSE -1
        END,
        -1
    ) AS DimLocationID,
    -- Derive location based on available dimension data
    sh.SalesHeaderID,
    sd.SalesDetailID,
    COALESCE(sd.SalesAmount, 0) AS SaleAmount,
    -- Default null amounts to 0
    COALESCE(sd.SalesQuantity, 0) AS SaleQuantity,
    -- Default null quantity to 0
    CASE
        WHEN COALESCE(sd.SalesQuantity, 0) = 0 THEN 0
        ELSE COALESCE(sd.SalesAmount, 0) / COALESCE(sd.SalesQuantity, 1)
    END AS SaleUnitPrice,
    -- Derive unit price safely; avoid divide-by-zero
    COALESCE(
        COALESCE(p.ProductCost, 0) * COALESCE(sd.SalesQuantity, 0),
        0
    ) AS SaleExtendedCost,
    -- Null-safe multiplication
    COALESCE(sd.SalesAmount, 0) - COALESCE(
        COALESCE(p.ProductCost, 0) * COALESCE(sd.SalesQuantity, 0),
        0
    ) AS SaleTotalProfit -- Profit = Revenue - Cost
FROM
    Staging_SalesDetail sd
    JOIN Staging_SalesHeader sh ON sd.SalesHeaderID = sh.SalesHeaderID -- Join detail and header
    LEFT JOIN Dim_Product p ON sd.ProductID = p.ProductID -- Resolve product key
    LEFT JOIN Dim_Store s ON sh.StoreID = s.SourceStoreID -- Match store
    LEFT JOIN Dim_Reseller r ON sh.ResellerID = r.ResellerID -- Match reseller
    LEFT JOIN Dim_Customer c ON sh.CustomerID = c.CustomerID -- Match customer
    LEFT JOIN Dim_Channel ch ON sh.ChannelID = ch.ChannelID -- Match channel
    LEFT JOIN DIM_DATE d ON sh.Date = d.DATE;
-- Resolve sale date
    -- Final verification step to review loaded sales data
SELECT
    *
FROM
    Fact_SalesActual;
--------------------------------------VIEW VIEW VIEW
    CREATE SECURE VIEW "V_DIM_DATE" AS
SELECT
    DATE_PKEY,
    DATE,
    FULL_DATE_DESC,
    DAY_NUM_IN_WEEK,
    DAY_NUM_IN_MONTH,
    DAY_NUM_IN_YEAR,
    DAY_NAME,
    DAY_ABBREV,
    WEEKDAY_IND,
    US_HOLIDAY_IND,
    /*<COMPANYNAME>*/
    _HOLIDAY_IND,
    -- Use the actual column name from table definition
    MONTH_END_IND,
    WEEK_BEGIN_DATE_NKEY,
    WEEK_BEGIN_DATE,
    WEEK_END_DATE_NKEY,
    WEEK_END_DATE,
    WEEK_NUM_IN_YEAR,
    MONTH_NAME,
    MONTH_ABBREV,
    MONTH_NUM_IN_YEAR,
    YEARMONTH,
    QUARTER,
    YEARQUARTER,
    YEAR,
    FISCAL_WEEK_NUM,
    FISCAL_MONTH_NUM,
    FISCAL_YEARMONTH,
    FISCAL_QUARTER,
    FISCAL_YEARQUARTER,
    FISCAL_HALFYEAR,
    FISCAL_YEAR,
    SQL_TIMESTAMP,
    CURRENT_ROW_IND,
    EFFECTIVE_DATE,
    EXPIRATION_DATE
FROM
    DIM_DATE;
CREATE SECURE VIEW "V_DIM_LOCATION" AS
SELECT
    DimLocationID,
    Country,
    State_Province,
    City,
    PostalCode,
    Address
FROM
    Dim_Location;
CREATE SECURE VIEW "V_DIM_PRODUCT" AS
SELECT
    DimProductID,
    ProductID,
    ProductName,
    ProductTypeID,
    ProductType,
    ProductCategoryID,
    ProductCategory,
    ProductRetailPrice,
    ProductCost,
    ProductWholesalePrice
FROM
    Dim_Product;
CREATE SECURE VIEW "V_DIM_CUSTOMER" AS
SELECT
    DimCustomerID,
    CustomerID,
    CustomerFirstName,
    CustomerLastName,
    CustomerFullName,
    CustomerGender,
    DimLocationID
FROM
    Dim_Customer;
CREATE SECURE VIEW "V_DIM_RESELLER" AS
SELECT
    DimResellerID,
    ResellerID,
    ResellerName,
    PhoneNumber,
    Email,
    DimLocationID
FROM
    Dim_Reseller;
CREATE SECURE VIEW "V_DIM_STORE" AS
SELECT
    DimStoreID,
    SourceStoreID,
    StoreNumber,
    StoreManager,
    DimLocationID
FROM
    Dim_Store;
CREATE SECURE VIEW "V_DIM_CHANNEL" AS
SELECT
    DimChannelID,
    ChannelID,
    ChannelName,
    ChannelCategoryID,
    ChannelCategory
FROM
    Dim_Channel;
CREATE SECURE VIEW "V_FACT_PRODUCTSALESTARGET" AS
SELECT
    DimProductID,
    DimTargetDateID,
    ProductTargetSalesQuantity
FROM
    Fact_ProductSalesTarget;
CREATE SECURE VIEW "V_FACT_SRCSALESTARGET" AS
SELECT
    DimStoreID,
    DimResellerID,
    DimChannelID,
    DimTargetDateID,
    SalesTargetAmount
FROM
    Fact_SRCSalesTarget;
CREATE SECURE VIEW "V_FACT_SALESACTUAL" AS
SELECT
    DimProductID,
    DimStoreID,
    DimResellerID,
    DimCustomerID,
    DimChannelID,
    DimSaleDateID,
    DimLocationID,
    SalesHeaderID,
    SalesDetailID,
    SaleAmount,
    SaleQuantity,
    SaleUnitPrice,
    SaleExtendedCost,
    SaleTotalProfit
FROM
    Fact_SalesActual;
----------------
    DROP VIEW IF EXISTS "V_STORE_PERFORMANCE";
CREATE SECURE VIEW V_STORE_PERFORMANCE AS
SELECT
    s.StoreNumber,
    s.StoreManager,
    l.City,
    l.State_Province,
    d.YEAR,
    d.QUARTER,
    -- Core Sales Metrics
    SUM(f.SaleAmount) AS TotalSales,
    SUM(f.SaleQuantity) AS TotalQuantity,
    SUM(f.SaleTotalProfit) AS TotalProfit,
    COUNT(*) AS TransactionCount,
    AVG(f.SaleAmount) AS AvgTransactionValue,
    -- Profitability % (Avoid division by zero)
    CASE
        WHEN SUM(f.SaleAmount) = 0 THEN 0
        ELSE (SUM(f.SaleTotalProfit) / SUM(f.SaleAmount)) * 100
    END AS ProfitMarginPercent,
    -- Profitability Tier
    CASE
        WHEN SUM(f.SaleTotalProfit) < 0 THEN 'Loss Making'
        WHEN SUM(f.SaleTotalProfit) < 10000 THEN 'Low Profit'
        WHEN SUM(f.SaleTotalProfit) < 50000 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS ProfitabilityTier,
    -- Monthly Projection
    SUM(f.SaleAmount) / COUNT(DISTINCT d.MONTH_NUM_IN_YEAR) AS AvgMonthlySales,
    -- Yearly Rankings
    RANK() OVER (
        PARTITION BY d.YEAR
        ORDER BY
            SUM(f.SaleAmount) DESC
    ) AS SalesRank,
    RANK() OVER (
        PARTITION BY d.YEAR
        ORDER BY
            SUM(f.SaleTotalProfit) DESC
    ) AS ProfitRank
FROM
    Fact_SalesActual f
    JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
    JOIN Dim_Location l ON s.DimLocationID = l.DimLocationID
    JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
WHERE
    s.SourceStoreID != -1
GROUP BY
    s.StoreNumber,
    s.StoreManager,
    l.City,
    l.State_Province,
    d.YEAR,
    d.QUARTER;
SELECT
    *
FROM
    "V_STORE_PERFORMANCE"
WHERE
    StoreNumber IN (10, 21)
ORDER BY
    YEAR,
    StoreNumber;
------------------
    --
    DROP VIEW IF EXISTS "V_DAYOFWEEK_SALES_ANALYSIS_NEW";
CREATE SECURE VIEW V_DAYOFWEEK_SALES_ANALYSIS AS
SELECT
    -- Store & Location Info
    s.StoreNumber,
    s.StoreManager,
    l.City,
    l.State_Province,
    -- Date Info
    d.YEAR,
    d.QUARTER,
    d.MONTH_NAME,
    d.DAY_NAME,
    d.DAY_NUM_IN_WEEK,
    -- Product Info
    p.ProductCategory,
    p.ProductType,
    -- Daily Sales Metrics
    SUM(f.SaleAmount) AS DailySales,
    SUM(f.SaleQuantity) AS DailyQuantity,
    SUM(f.SaleTotalProfit) AS DailyProfit,
    COUNT(*) AS DailyTransactions,
    AVG(f.SaleAmount) AS AvgTransactionValue,
    -- Average Performance Per Calendar Day
    SUM(f.SaleAmount) / COUNT(DISTINCT d.DATE) AS AvgSalesPerDay,
    COUNT(*) / COUNT(DISTINCT d.DATE) AS AvgTransactionsPerDay,
    -- Weekend vs Weekday
    CASE
        WHEN d.DAY_NAME IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType,
    -- Peak Day Performance Indicators (within Store and Year)
    RANK() OVER (
        PARTITION BY s.StoreNumber,
        d.YEAR
        ORDER BY
            SUM(f.SaleAmount) DESC
    ) AS DayRankBySales,
    RANK() OVER (
        PARTITION BY s.StoreNumber,
        d.YEAR
        ORDER BY
            COUNT(*) DESC
    ) AS DayRankByTransactions,
    -- Product Mix Sales Breakdown
    SUM(
        CASE
            WHEN p.ProductCategory = 'Cosmetics' THEN f.SaleAmount
            ELSE 0
        END
    ) AS CosmeticsSales,
    SUM(
        CASE
            WHEN p.ProductCategory = 'Jewelry' THEN f.SaleAmount
            ELSE 0
        END
    ) AS JewelrySales,
    SUM(
        CASE
            WHEN p.ProductCategory = 'Baby' THEN f.SaleAmount
            ELSE 0
        END
    ) AS BabySales,
    SUM(
        CASE
            WHEN p.ProductCategory = 'Kids Apparel' THEN f.SaleAmount
            ELSE 0
        END
    ) AS KidsApparelSales,
    SUM(
        CASE
            WHEN p.ProductCategory = 'Womens Apparel' THEN f.SaleAmount
            ELSE 0
        END
    ) AS WomensApparelSales
FROM
    Fact_SalesActual f
    JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
    JOIN Dim_Location l ON s.DimLocationID = l.DimLocationID
    JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
    JOIN Dim_Product p ON f.DimProductID = p.DimProductID -- Filter out unknowns
WHERE
    s.sourceStoreID != -1
    AND p.ProductID != -1 -- Grouping ensures 1 row per store/day/product type
GROUP BY
    s.StoreNumber,
    s.StoreManager,
    l.City,
    l.State_Province,
    d.YEAR,
    d.QUARTER,
    d.MONTH_NAME,
    d.DAY_NAME,
    d.DAY_NUM_IN_WEEK,
    p.ProductCategory,
    p.ProductType;
SELECT
    StoreNumber,
    YEAR,
    DayType,
    SUM(DailySales) AS TotalSales,
    AVG(DailySales) AS AvgDailySales,
    SUM(DailyTransactions) AS TotalTransactions
FROM
    "V_DAYOFWEEK_SALES_ANALYSIS"
WHERE
    StoreNumber IN (10, 21)
GROUP BY
    StoreNumber,
    YEAR,
    DayType
ORDER BY
    StoreNumber,
    YEAR,
    DayType;
--------------------
    DROP VIEW IF EXISTS "V_MARKET_EXPANSION_ANALYSIS";
CREATE SECURE VIEW V_MARKET_EXPANSION AS
SELECT
    -- Market Location
    l.Country,
    l.State_Province,
    l.City,
    d.YEAR,
    -- Market Size Metrics
    COUNT(DISTINCT s.StoreNumber) AS StoresInMarket,
    COUNT(DISTINCT r.ResellerID) AS ResellersInMarket,
    COUNT(DISTINCT c.CustomerID) AS UniqueCustomers,
    -- Total Market Performance
    SUM(f.SaleAmount) AS TotalMarketSales,
    SUM(f.SaleTotalProfit) AS TotalMarketProfit,
    COUNT(*) AS TotalTransactions,
    -- Store Density Analysis
    SUM(f.SaleAmount) / NULLIF(COUNT(DISTINCT s.StoreNumber), 0) AS SalesPerStore,
    SUM(f.SaleTotalProfit) / NULLIF(COUNT(DISTINCT s.StoreNumber), 0) AS ProfitPerStore,
    COUNT(*) / NULLIF(COUNT(DISTINCT s.StoreNumber), 0) AS TransactionsPerStore,
    -- Market Penetration
    COUNT(DISTINCT c.CustomerID) / NULLIF(COUNT(DISTINCT s.StoreNumber), 0) AS CustomersPerStore,
    -- Profitability
    CASE
        WHEN SUM(f.SaleAmount) = 0 THEN 0
        ELSE (SUM(f.SaleTotalProfit) / SUM(f.SaleAmount)) * 100
    END AS MarketProfitMargin,
    -- Competition Level Based on Resellers
    CASE
        WHEN COUNT(DISTINCT r.ResellerID) = 0 THEN 'No Competition'
        WHEN COUNT(DISTINCT r.ResellerID) <= 2 THEN 'Low Competition'
        WHEN COUNT(DISTINCT r.ResellerID) <= 5 THEN 'Moderate Competition'
        ELSE 'High Competition'
    END AS CompetitionLevel,
    -- Expansion Opportunity Classification
    CASE
        WHEN COUNT(DISTINCT s.StoreNumber) = 0 THEN 'Greenfield Opportunity'
        WHEN SUM(f.SaleAmount) / NULLIF(COUNT(DISTINCT s.StoreNumber), 0) > 100000 THEN 'High Opportunity'
        WHEN SUM(f.SaleAmount) / NULLIF(COUNT(DISTINCT s.StoreNumber), 0) > 50000 THEN 'Moderate Opportunity'
        ELSE 'Low Opportunity'
    END AS ExpansionOpportunity,
    -- Sales Channel Breakdown
    SUM(
        CASE
            WHEN ch.ChannelCategory = 'Online' THEN f.SaleAmount
            ELSE 0
        END
    ) AS OnlineChannelSales,
    SUM(
        CASE
            WHEN ch.ChannelCategory = 'Retail' THEN f.SaleAmount
            ELSE 0
        END
    ) AS RetailChannelSales,
    -- Market Rankings
    RANK() OVER (
        PARTITION BY d.YEAR
        ORDER BY
            SUM(f.SaleAmount) DESC
    ) AS MarketRankBySales,
    RANK() OVER (
        PARTITION BY d.YEAR
        ORDER BY
            SUM(f.SaleAmount) / NULLIF(COUNT(DISTINCT s.StoreNumber), 0) DESC
    ) AS MarketRankByEfficiency,
    -- Year-over-Year Sales Growth
    LAG(SUM(f.SaleAmount)) OVER (
        PARTITION BY l.Country,
        l.State_Province,
        l.City
        ORDER BY
            d.YEAR
    ) AS PriorYearSales,
    CASE
        WHEN LAG(SUM(f.SaleAmount)) OVER (
            PARTITION BY l.Country,
            l.State_Province,
            l.City
            ORDER BY
                d.YEAR
        ) IS NOT NULL THEN (
            (
                SUM(f.SaleAmount) - LAG(SUM(f.SaleAmount)) OVER (
                    PARTITION BY l.Country,
                    l.State_Province,
                    l.City
                    ORDER BY
                        d.YEAR
                )
            ) / LAG(SUM(f.SaleAmount)) OVER (
                PARTITION BY l.Country,
                l.State_Province,
                l.City
                ORDER BY
                    d.YEAR
            )
        ) * 100
        ELSE NULL
    END AS YearOverYearGrowthPercent
FROM
    Fact_SalesActual f
    JOIN Dim_Location l ON f.DimLocationID = l.DimLocationID
    JOIN DIM_DATE d ON f.DimSaleDateID = d.DATE_PKEY
    JOIN Dim_Channel ch ON f.DimChannelID = ch.DimChannelID -- Optional: Include stores, customers, resellers if valid
    LEFT JOIN Dim_Store s ON f.DimStoreID = s.DimStoreID
    AND s.SourceStoreID != -1
    LEFT JOIN Dim_Reseller r ON f.DimResellerID = r.DimResellerID
    AND r.ResellerID != 'Unknown'
    LEFT JOIN Dim_Customer c ON f.DimCustomerID = c.DimCustomerID
    AND c.CustomerID != 'Unknown' -- Exclude Unknown Locations
WHERE
    l.DimLocationID != -1 -- Grouping: Location + Year
GROUP BY
    l.Country,
    l.State_Province,
    l.City,
    d.YEAR;
SELECT
    Country,
    State_Province,
    City,
    YEAR,
    StoresInMarket,
    TotalMarketSales,
    SalesPerStore,
    ExpansionOpportunity,
    CompetitionLevel
FROM
    "V_MARKET_EXPANSION"
WHERE
    ExpansionOpportunity IN (
        'High Opportunity',
        'Moderate Opportunity',
        'Greenfield
Opportunity'
    )
ORDER BY
    SalesPerStore DESC;
------new script
    CREATE
    OR REPLACE VIEW V_FACT_SALESTARGETBYSTORE AS
SELECT
    ps.StoreNumber,
    SUM(st.SalesTarget * p.UnitPrice) AS SalesTarget
FROM
    FACT_SALES_TARGET st
    JOIN DIM_PRODUCT p ON st.ProductID = p.ProductID
    JOIN DIM_PRODUCTSTORE ps ON st.ProductID = ps.ProductID
WHERE
    st.Year = 2013
GROUP BY
    ps.StoreNumber;
SELECT
    *
FROM
    Fact_SRCSalesTarget
WHERE
    DimStoreID IS NOT NULL;
DELETE FROM
    Fact_SRCSalesTarget
WHERE
    DimStoreID = -1;
DELETE FROM
    Fact_SalesActual
WHERE
    DimStoreID = -1;
-- Create the Fact_SalesActual table
    CREATE
    OR REPLACE TABLE Fact_SalesActual (
        DimProductID INT REFERENCES Dim_Product(DimProductID),
        DimStoreID INT REFERENCES Dim_Store(DimStoreID),
        DimResellerID INT REFERENCES Dim_Reseller(DimResellerID),
        DimCustomerID INT REFERENCES Dim_Customer(DimCustomerID),
        DimChannelID INT REFERENCES Dim_Channel(DimChannelID),
        DimSaleDateID number(9) REFERENCES Dim_Date(DATE_PKEY),
        DimLocationID INT REFERENCES Dim_Location(DimLocationID),
        SalesHeaderID INT,
        SalesDetailID INT,
        SaleAmount FLOAT,
        SaleQuantity INT,
        SaleUnitPrice FLOAT,
        SaleExtendedCost FLOAT,
        SaleTotalProfit FLOAT
    );
INSERT INTO
    FACT_SALESACTUAL (
        DimProductID,
        DimStoreID,
        DimResellerID,
        DimCustomerID,
        DimChannelID,
        DimSaleDateID,
        DimLocationID,
        SalesHeaderID,
        SalesDetailID,
        SaleAmount,
        SaleQuantity,
        SaleUnitPrice,
        SaleExtendedCost,
        SaleTotalProfit
    )
SELECT
    COALESCE(dp.DimProductID, -1),
    --all these are foreign keys, if there are null values, then replace it by -1
    COALESCE(ds.DimStoreID, -1),
    COALESCE(dr.DimResellerID, -1),
    COALESCE(dc.DimCustomerID, -1),
    COALESCE(dchannel.DimChannelID, -1),
    COALESCE(dd.DATE_PKEY, -1) AS DimSaleDateID,
    COALESCE(ds.DimLocationID, -1),
    sd.SALESDETAILID,
    sh.SALESHEADERID,
    sd.SALESAMOUNT,
    sd.SALESQUANTITY,
    sd.SALESAMOUNT / sd.SALESQUANTITY AS SaleUnitPrice,
    dp.PRODUCT_COST * sd.SalesQuantity AS SaleExtendedCost,
    round(
        (sd.SALESAMOUNT) -(dp.PRODUCT_COST * sd.SALESQUANTITY),
        2
    ) AS SaleTotalProfit
FROM
    STAGING_SALESHEADER sh
    join STAGING_SALESDETAIL sd on sh.SALESHEADERID = sd.SALESHEADERID
    LEFT JOIN Dim_Product dp ON sd.PRODUCTID = dp.ProductID
    LEFT JOIN Dim_Store ds ON sh.STOREID = ds.STOREID
    LEFT JOIN Dim_Reseller dr ON sh.RESELLERID = dr.ResellerID
    LEFT JOIN Dim_Customer dc ON sh.CUSTOMERID = dc.CustomerID
    LEFT JOIN Dim_Channel dchannel ON sh.CHANNELID = dchannel.ChannelID
    --LEFT JOIN
    --Dim_Location dl ON ds.DimLocationID = dl.DimLocationID
    LEFT JOIN Dim_Date dd ON TO_DATE(
        '20' || SUBSTRING(TO_CHAR(sh.DATE, 'YYYY'), 3, 2) || TO_CHAR(sh.DATE, '-MM-DD'),
        'YYYY-MM-DD'
    ) = dd.DATE;
SELECT
    *
FROM
    STAGING_SALESHEADER;
SELECT
    *
FROM
    STAGING_SALESDETAIL;
--------------experiment
    CREATE
    OR REPLACE SECURE VIEW Q1 AS WITH StoreSalesData AS (
        SELECT
            ds.StoreNumber,
            dd.FISCAL_YEAR,
            SUM(fsa.SaleAmount) / 1000000 AS TotalSalesAmount
        FROM
            Fact_SalesActual fsa
            JOIN Dim_Store ds ON fsa.DimStoreID = ds.DimStoreID
            JOIN Dim_Date dd ON fsa.DimSaleDateID = dd.date_pkey
        WHERE
            ds.StoreNumber IN (10, 21)
            AND dd.fiscal_year = 2013
        GROUP BY
            ds.StoreNumber,
            dd.FISCAL_YEAR
    ),
    StoreTargetData AS (
        SELECT
            ds.StoreNumber,
            dd.FISCAL_YEAR,
            SUM(fst.SalesTargetAmount) / 1000000 AS TotalTargetSales
        FROM
            Fact_SRCSalesTarget fst
            JOIN Dim_Store ds ON fst.DimStoreID = ds.DimStoreID
            JOIN Dim_Date dd ON fst.DimTargetDateID = dd.date_pkey
        WHERE
            ds.StoreNumber IN (10, 21)
            AND dd.fiscal_year = 2014
        GROUP BY
            ds.StoreNumber,
            dd.FISCAL_YEAR
    )
SELECT
    ssd.StoreNumber,
    ssd.fiscal_Year,
    ssd.TotalSalesAmount,
    std.TotalTargetSales,
    std.TotalTargetSales - ssd.TotalSalesAmount as deviation
FROM
    StoreSalesData ssd
    JOIN StoreTargetData std ON ssd.StoreNumber = std.StoreNumber
ORDER BY
    ssd.StoreNumber;
select
    *
from
    Q1;
