-- use the northwind dataset
USE northwind;

# ---------------------------------------------------------------------- #
#                             ANALYTICS PLAN                             #
# ---------------------------------------------------------------------- #

-- The Northwind data set contains data about a fictitious specialty foods export­import company. 
-- We have data on the orders made, the employees who worked on each, the customers who ordered,
-- shippers applied, suppliers, products and categories which were delivered. First I needed to create analyze
-- analytical data store, which contains all the relevant information for further analysis. After this I created 
-- an automatic trigger, which updates my analytical data store whenever new order is entered to the data set. 
-- The final aim of my analysis is to create data marts first one which shows the products in the bevarages category 
-- to help an product category manager, the second is a mart for all the country level order stats within Europe and
-- the last to see the workload of the employees with the help of the countries belonging to them. 

# ------------------------------------------------------- #
#                 ANALYTICAL DATA STORE                   #
# ------------------------------------------------------- #
-- Creating a denormalized snapshot of the operational tables to see useful data for the sales of the company.
-- For this I included for each OrderID, the date of the order, the data of shipping, the days between these two to see how many days 
-- a customer have to wait from making the order until the product is shipped to them. I included the name of the products (one order may contain one ar many products),
-- the categories each product belong to, the price per unit, the quantity ordered, and the calculated revenue (UnitPrice*Quantity). Beside these this sales data contains
-- the company who made the order, the one who supplied the product and the shipper and the employee who handeled the ordered.
--  Last but not least we have counry, to se where the revenue is coming from.

DROP PROCEDURE IF EXISTS CreateSalesDataStore;

DELIMITER //

CREATE PROCEDURE CreateSalesDataStore()
BEGIN

	DROP TABLE IF EXISTS sales;
    
    CREATE TABLE sales AS
		SELECT  
		OrderID, OrderDate, ShippedDate, DATEDIFF(ShippedDate, OrderDate) AS DaysToDeliver, 
		ProductName AS Product, CategoryName AS Category, 
		od.UnitPrice , 
		od.Quantity, 
		ROUND(od.UnitPrice*od.Quantity, 2) AS Revenue,  
		 c.CompanyName AS Customer, 
		 s. CompanyName AS Supplier, 
		 ship.CompanyName AS Shipper, 
         CONCAT(employees.FirstName, ' ', employees.LastName) AS Employee,
		 c.Country AS Country
		FROM `Order Details` AS od 
		INNER JOIN Orders
		USING (OrderID)
		INNER JOIN Shippers AS ship
		ON ShipperID = ShipVia 
		INNER JOIN Customers AS c
		USING (CustomerID)
		INNER JOIN Products AS p
		USING (ProductID)
		INNER JOIN Categories
		USING (CategoryID)
		INNER JOIN Suppliers AS s
       USING (SupplierID) 
       INNER JOIN employees
        USING (EmployeeID)
		
        ORDER BY OrderID, Revenue;

END //
DELIMITER ;
                            
CALL CreateSalesDataStore();

-- Test if the analytical data store was created properly 
SELECT * FROM Sales;
-- There were 2155 products ordered in the operational data set, and this code show our new table has exactly the same number of rows, so the code ran properly
SELECT count(*) FROM sales;

# ------------------------------------------------------- #
#                       ELT  pipeline                     #
# ------------------------------------------------------- #

-- As each order is imputted into

CREATE TABLE messages (message varchar(255) NOT NULL);

DROP TRIGGER IF EXISTS NewOrderInsert; 

TRUNCATE messages;

DELIMITER //

CREATE TRIGGER NewOrderInsert
AFTER INSERT
ON `Order Details` FOR EACH ROW
BEGIN
	
    INSERT INTO messages SELECT CONCAT('new OrderID: ', NEW.OrderID);
  	
    INSERT INTO Sales
	SELECT  
		OrderID, OrderDate, ShippedDate, DATEDIFF(ShippedDate, OrderDate) AS DaysToDeliver, 
		ProductName AS Product, CategoryName AS Category, 
		od.UnitPrice , 
		od.Quantity, 
		ROUND(od.UnitPrice*od.Quantity, 2) AS Revenue,  
		 c.CompanyName AS Customer, 
		 s. CompanyName AS Supplier, 
		 ship.CompanyName AS Shipper,
         CONCAT(employees.FirstName, ' ', employees.LastName) AS Employee,
		 c.Country AS Country
		FROM `Order Details` AS od 
		LEFT JOIN Orders
		USING (OrderID)
		LEFT JOIN Shippers AS ship
		ON ShipperID = ShipVia 
		LEFT JOIN Customers AS c
		USING (CustomerID)
		LEFT JOIN Products AS p
		USING (ProductID)
		LEFT JOIN Categories
		USING (CategoryID)
		LEFT JOIN Suppliers AS s
		USING (SupplierID)
        LEFT JOIN employees
        USING (EmployeeID)
    WHERE od.OrderID = NEW.OrderID;
        
END //

DELIMITER ;

-- Check sales table before inserting a new row
SELECT * FROM sales order by OrderDate DESC; -- The last order was made 1998-05-06
SELECT count(*) FROM sales; -- We have 2155 records 

INSERT INTO Orders  VALUES(100,'SUPRD', 5,'2021-11-20','2020-12-18', '2020-12-15', 3, 95.345, 'Data Engineering cruiser', 'Hauptstr. 31', 'Bern', '', 3012, 'Switzerland' );
INSERT INTO `Order Details` VALUES (100, 11, 19.3, 9, 0);

-- Testing if the trigger works
SELECT * FROM messages; -- In the messages table we see that there was a new order with OrderID: 100

-- Checking the orders table 
SELECT * FROM Orders ORDER BY OrderDate DESC; -- It has the newly inserted order with OrderID: 100

SELECT * FROM sales order by OrderDate DESC; -- The last order was made 1998-05-06
SELECT count(*) FROM sales; -- We have 2155 records 


# ------------------------------------------------------- #
#                        Data Marts                       #
# ------------------------------------------------------- #

-- DATA MART 1
-- A data mart to see what was the total quantity and revenue for each product sold during the period which belong to the Beverages catagory

DROP VIEW IF EXISTS Beverages;

CREATE VIEW `Beverages` AS
SELECT MIN(OrderDate) AS FirstOrder, MAX(OrderDate) AS LastOrderDate, Category, Product, ROUND(UnitPrice, 2) AS UnitPrice, SUM(Quantity) AS TotalQuantity, SUM(Revenue) AS TotalRevenue
FROM Sales
WHERE Category = "Beverages"
GROUP BY Product
ORDER BY TotalRevenue DESC;

SELECT * FROM beverages;

-- The most successful product was "Cte de Blaye" with the total revenue of $149984.2 and quantity of 632, 
-- on the other hand 'Rhnbru Klosterbier' was sold in the highest quantity.


-- DATA MART 2
-- The aim is to see a country level summed sales data with total quantity sold and revenue earned for countries located in Europe.
-- I also included a column assigning a revenue generation level to each country. (low if < 100000,  medium between 100000 & 200000, and high if > 200000)

DROP VIEW IF EXISTS Europe;

CREATE VIEW `Europe` AS
SELECT  Country, 
ROUND(UnitPrice, 2) AS UnitPrice, 
SUM(Quantity) AS TotalQuantity, 
SUM(Revenue) AS TotalRevenue,
CASE
            WHEN SUM(Revenue) <= 50000 THEN 'Low Revenue Country'
            WHEN SUM(Revenue) <= 100000 THEN 'Medium Revenue Country'
            ELSE 'High Revenue Country'
        END AS RevenueGeneration
FROM Sales
WHERE Country IN ('Belgium', 'Denmark', 'Switzerland', 'France', 'Germany', 'Austria', 'Finland', 'Ireland', 'Italy', 'Norway', 'Poland', 'Spain', 'Sweden', 'UK')
GROUP BY Country
ORDER BY TotalRevenue DESC;

SELECT * FROM Europe;

-- The most revenues came from Germany and Austia and the least revenue generation country is Poland. 

-- DATA MART 3
-- In the third data view the aim was to see what countries belong to each employee with what revenues, quantities sold

DROP VIEW IF EXISTS Employee;

CREATE VIEW `Employee` AS
SELECT DISTINCT Employee, Country, ROUND(AVG(UnitPrice),2) AS UnitPrice, SUM(Quantity) AS Quantity, SUM(Revenue) AS Revenue
FROM Sales
GROUP BY Country
ORDER BY Employee, Revenue;

SELECT * FROM employee;

-- We can see that Margaret Peacock is responsible for the most countries.





