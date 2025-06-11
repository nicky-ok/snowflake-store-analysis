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
