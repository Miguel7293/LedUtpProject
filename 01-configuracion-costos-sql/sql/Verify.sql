SELECT DB_NAME() AS DatabaseName, SUSER_SNAME() AS LoginName;
SELECT COUNT(*) AS Customers FROM SalesLT.Customer;
SELECT TOP (10) ProductID, Name, ListPrice
FROM SalesLT.Product
ORDER BY ProductID;
