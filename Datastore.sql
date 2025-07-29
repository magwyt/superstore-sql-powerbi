--Creating database
CREATE DATABASE SuperstoreDB;
GO
USE SuperstoreDB;

--Created Staging_Superstore table and loaded the data

--Creating star schema tables
CREATE TABLE Customers (
	CustomerID NVARCHAR(20) PRIMARY KEY,
    CustomerName NVARCHAR(100),
    Segment NVARCHAR(50),
    Country NVARCHAR(50),
    City NVARCHAR(50),
    State NVARCHAR(50),
    PostalCode NVARCHAR(20),
    Region NVARCHAR(50)
);

CREATE TABLE Products (
    ProductID NVARCHAR(20) PRIMARY KEY,
    ProductName NVARCHAR(200),
    Category NVARCHAR(50),
    SubCategory NVARCHAR(50)
);

CREATE TABLE Orders (
    OrderID NVARCHAR(20),
    OrderDate DATE,
    ShipDate DATE,
    ShipMode NVARCHAR(50),
    CustomerID NVARCHAR(20),
    ProductID NVARCHAR(20),
    Sales DECIMAL(10,2),
    Quantity INT,
    Discount DECIMAL(4,2),
    Profit DECIMAL(10,2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
--Checking for nulls for future Primary Keys
SELECT * FROM Staging_Superstore WHERE Customer_ID IS NULL OR Product_ID IS NULL;

--Loading data to Customers table from Staging_Superstore table
WITH UniqueCustomers AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY Customer_Name) AS rn
    FROM Staging_Superstore
)
INSERT INTO Customers
SELECT
    Customer_ID,
    Customer_Name,
    Segment,
    Country,
    City,
    State,
    Postal_Code,
    Region
FROM UniqueCustomers
WHERE rn = 1;

--Loading data to Products table from Staging_Superstore table
WITH UniqueProducts AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Product_ID ORDER BY Product_Name) AS rn
    FROM Staging_Superstore
)
INSERT INTO Products
SELECT
    Product_ID,
    Product_Name,
    Category,
    Sub_Category
FROM UniqueProducts
WHERE rn = 1;

--Loading data to Orders table from Staging_Superstore table
INSERT INTO Orders
(
    OrderID,
    ProductID,
    OrderDate,
    ShipDate,
    ShipMode,
    CustomerID,
    Sales,
    Quantity,
    Discount,
    Profit
)
SELECT
    Order_ID,
    Product_ID,
    Order_Date,
    Ship_Date,
    Ship_Mode,
    Customer_ID,
    Sales,
    Quantity,
    Discount,
    Profit
FROM Staging_Superstore;

--Data analysis:

-- KPIs
SELECT 
	SUM(Sales) AS TotalSales,
	SUM(Profit) AS TotalProfit,
	COUNT(DISTINCT OrderID) AS TotalOrders,
	COUNT(DISTINCT c.CustomerID) AS TotalCustomers,
	FORMAT(ROUND(SUM(Profit)/SUM(Sales) * 100,2), '#0.00') AS ProfitMarginPercent,
	AVG(DATEDIFF(DAY, OrderDate, ShipDate)) AS AvgShippingTimeDays,
	FORMAT(ROUND(SUM(Sales)/COUNT(OrderID),2), '#0.00') AS AvgOrderValue
FROM Orders o
INNER JOIN Customers c
ON o.CustomerID = c.CustomerID

--Top 10 Customers by Sales
SELECT TOP 10
    c.CustomerName,
    SUM(o.Sales) AS TotalSales
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerName
ORDER BY TotalSales DESC;

--Top 10 Customers by Profit
SELECT TOP 10 
	CustomerName, 
	SUM(Profit) AS TotalProfit
FROM Customers c
INNER JOIN Orders o
ON c.CustomerID = o.CustomerID
GROUP BY CustomerName
ORDER BY TotalProfit ASC;

--Top 10 Products by Profit
SELECT TOP 10
    p.ProductName,
    SUM(o.Profit) AS TotalProfit
FROM Orders o
INNER JOIN Products p ON o.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalProfit DESC;

--Top 10 Products by Sales
SELECT TOP 10
    p.ProductName,
    SUM(o.Sales) AS TotalSales
FROM Orders o
INNER JOIN Products p ON o.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalSales DESC;

--No of Orders by Region
SELECT
    c.Region,
    COUNT(o.OrderID) AS OrderCount
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY c.Region
ORDER BY OrderCount DESC;

--Average Sales by Segment
SELECT
    c.Segment,
    AVG(o.Sales) AS AvgSales
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY c.Segment
ORDER BY AvgSales DESC;

--Top 10 Products by Quantity
SELECT TOP 10
    p.ProductName,
    SUM(o.Quantity) AS TotalQuantity
FROM Orders o
INNER JOIN Products p ON o.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalQuantity DESC;

--Profit by Year-Month
SELECT
    FORMAT(OrderDate, 'yyyy-MM') AS YearMonth,
    SUM(Profit) AS TotalProfit
FROM Orders
GROUP BY FORMAT(OrderDate, 'yyyy-MM')
ORDER BY YearMonth;

--Sales by Category
SELECT 
	Category, 
	SUM(Sales) AS TotalSales
FROM Products p
INNER JOIN Orders o
ON p.ProductID = o.ProductID
GROUP BY Category
ORDER BY TotalSales DESC;

--No of Customers by State
SELECT 
	State, 
	COUNT(CustomerID) AS CustomerCount
FROM Customers
GROUP BY State
ORDER BY CustomerCount DESC;

--Top 10 Orders by Sales
SELECT TOP 10 
	OrderID, 
	SUM(Sales) AS TotalSales 
FROM Orders 
GROUP BY OrderID
ORDER BY TotalSales DESC;

--Profit Margin % by Year-Month
SELECT 
    FORMAT(OrderDate, 'yyyy-MM') AS YearMonth,
    FORMAT(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, '#0.00') AS ProfitMarginPercent
FROM Orders
GROUP BY FORMAT(OrderDate, 'yyyy-MM')
ORDER BY YearMonth;
