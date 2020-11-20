
# ---------------------------------------------------------------------- #
# GET AN INITIAL LOOK AT THE DATA I HAVE                                 #
# ---------------------------------------------------------------------- #

SHOW TABLES;
DESCRIBE `products`;
DESCRIBE `order details`;

SELECT * FROM employees; -- there are 9 employees

-- crate a joined table to see who reports to who
SELECT
  CONCAT(employees.FirstName, ' ', employees.LastName) AS `Workers`,
  employees.Title,
  CONCAT(managers.FirstName, ' ', managers.LastName) AS `Managers` 
FROM employees 
LEFT JOIN employees AS managers 
  ON employees.ReportsTo = managers.employeeID
ORDER BY
  managers.employeeID;
  
SELECT * FROM region; -- we have 4 REGION Eastern, Westerns, Northern and Southern        

SELECT * FROM territories; -- 53 territories

-- create a summary table which helps to see what region does the terrirories belong to
SELECT TerritoryDescription, RegionDescription  FROM region
RIGHT JOIN territories 
USING (RegionID);

-- this table shows how many territories belong to each region
SELECT  RegionDescription, count(TerritoryDescription) AS `Number of territories in the region` FROM region
LEFT JOIN territories 
USING (RegionID)
GROUP BY (RegionDescription);

SELECT * FROM employeeterritories;

-- create a table to see which emplyee covers the given territory and what is his/her title and salary (there are 4 territories which does not belong to any employee)
SELECT  TerritoryDescription, CONCAT(employees.FirstName, ' ', employees.LastName) AS Employee, Title, Salary 
FROM territories
LEFT JOIN employeeterritories
USING (TerritoryID)
LEFT JOIN employees
USING (EmployeeID)
ORDER BY (TerritoryDescription);

-- Create a table to see what territories belong to an employee
SELECT  CONCAT(employees.FirstName, ' ', employees.LastName) AS Employee, TerritoryDescription
FROM employees
LEFT JOIN employeeterritories
USING (EmployeeID)
LEFT JOIN territories
USING (TerritoryID)
ORDER BY (Employee);

SELECT * FROM categories; -- we have 8 categories for the products
							
SELECT * FROM suppliers; -- there are 29 different suppliers

SELECT * FROM products; -- there are 77 products

-- Find the 10 products from we have the highest stocked value in $USD
SELECT ProductName, UnitPrice, UnitsInStock, UnitPrice*UnitsInStock AS TotalStock FROM products
ORDER BY TotalStock DESC
LIMIT 10;

-- Find the 10 most expensive products on a unit level
SELECT ProductName, UnitPrice, UnitsInStock, UnitPrice*UnitsInStock AS TotalStock FROM products
ORDER BY UnitPrice DESC
LIMIT 10;

-- In what categories of products does one supplier supplies 
SELECT  DISTINCT CompanyName, City, CategoryName, Description
FROM suppliers
LEFT JOIN Products
USING (SupplierID)
LEFT JOIN Categories
USING (CategoryID);

SELECT * FROM Shippers; -- We have 3 different shippers

SELECT * FROM Orders; -- There were 830 orders between 1996-07-04 and 1998-05-06
SELECT * FROM `Order Details`;


SELECT DISTINCT ShipCountry, count(ShipCountry) FROM Orders GROUP BY ShipCountry;
-- From this I see that the two countries where most of the orders were delivered were Germany and the USA. 
-- For my analysis I decided to do an analytical layer for the USA.

SELECT CategoryName, Description, ROUND(SUM(od.UnitPrice*od.Quantity),2) AS 'Revenue ($)' FROM categories
LEFT JOIN Products
USING (CategoryID)
LEFT JOIN `Order Details` AS od
USING (ProductID)
GROUP BY CategoryName
ORDER BY 'Revenue ($)' DESC;
-- The most revenue $286526.95 is coming from the Beverage product category which contains products like soft drinks, coffees, teas, beers, and ales.
-- I will create a 

-- Analyze the orders, see the average unit price, the quantity and the total price each had 
SELECT OrderID, ROUND(AVG(UnitPrice), 2), SUM(Quantity), ROUND(SUM(UnitPrice*Quantity), 2) AS TotalPrice
FROM `Order Details`
GROUP BY OrderID 
ORDER BY TotalPrice DESC;
