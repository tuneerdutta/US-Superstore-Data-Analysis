--CREATE DATABASE US_Superstore_Sales;
USE US_Superstore_Sales;

SELECT * FROM superstore
WHERE Row_ID IS NULL OR Order_ID IS NULL OR Order_Date IS NULL OR Ship_Date IS NULL OR Ship_Mode IS NULL
OR Customer_ID IS NULL OR Customer_Name IS NULL OR Segment IS NULL OR Country IS NULL OR City IS NULL
OR State IS NULL OR Postal_Code IS NULL OR Region IS NULL OR Product_ID IS NULL OR Category IS NULL
OR Sub_Category IS NULL OR Product_Name IS NULL OR Sales IS NULL;

--DELETE FROM superstore WHERE Postal_Code IS NULL;

--------------CUSTOMERS TABLE-----------------------

WITH CTE1 AS(
SELECT Customer_ID, Customer_Name, TRIM(SUBSTRING(Customer_Name,0,CHARINDEX(' ',Customer_Name))) AS First_Name,
TRIM(SUBSTRING(Customer_Name,CHARINDEX(' ',Customer_Name),LEN(Customer_Name))) as Last_Name,
City,State,Country,Postal_Code,Region
FROM superstore),
CTE2 AS(
SELECT *,ROW_NUMBER() OVER(PARTITION BY Customer_ID ORDER BY (SELECT 1)) AS RNK
FROM CTE1)
SELECT Customer_ID,CASE WHEN First_Name =' ' THEN 'Aman' ELSE First_Name END AS First_Name,Last_Name,City,State,Country,Postal_Code,Region
FROM CTE2 WHERE RNK=1
ORDER BY First_Name,Last_Name;

----- SHIPPERS TABLE---------
SELECT DISTINCT CASE WHEN Ship_Mode='First Class' THEN 101
WHEN Ship_Mode='Same Day' THEN 102
WHEN Ship_Mode='Standard Class' THEN 103
WHEN Ship_Mode='Second Class' THEN 104 END AS Shipper_ID,
Ship_Mode
FROM superstore
ORDER BY Shipper_ID;

--------- ORDERS TABLE------------------------
WITH CTE1 AS(
SELECT DISTINCT Order_ID, Customer_ID, Order_Date,Ship_Date,
CASE WHEN Ship_Mode='First Class' THEN 101
WHEN Ship_Mode='Same Day' THEN 102
WHEN Ship_Mode='Standard Class' THEN 103
WHEN Ship_Mode='Second Class' THEN 104 END AS Shipper_ID, ROUND(Sales,2) AS Sales
FROM superstore
WHERE Customer_ID IN (SELECT Customer_ID FROM Customers)),
CTE2 AS(
SELECT * ,ROW_NUMBER() OVER(PARTITION BY Order_ID ORDER BY Sales) as rnk
FROM CTE1)
SELECT Order_ID, Customer_ID, Order_Date,Ship_Date,Shipper_ID,Sales
FROM CTE2
WHERE RNK=1
ORDER BY Order_ID;

-----------------------------------ORDER DETAILS--------------------------

SELECT DISTINCT Row_ID AS OrderDetailsID,Order_ID,Product_ID
FROM superstore 
WHERE Customer_ID IN 
(SELECT Customer_ID 
FROM Customers)
ORDER BY OrderDetailsID;

-----------------------------------PRODUCTS------------------------------
WITH CTE1 AS(
SELECT DISTINCT Product_ID,Product_Name, Category, Sub_Category
FROM superstore
WHERE Customer_ID IN (SELECT Customer_ID FROM Customers)
AND Product_ID IN (SELECT Product_ID FROM OrderDetails)),
CTE2 AS(
SELECT *,ROW_NUMBER() OVER(PARTITION BY Product_ID ORDER BY Category) AS RNK
FROM CTE1)
SELECT Product_ID,Product_Name, Category, Sub_Category
FROM CTE2 
WHERE RNK=1
ORDER BY Product_ID;

----------------------------------FULL TABLE---------------------------------
SELECT C.Customer_ID,First_Name,Last_Name,City,State,Country,Postal_Code,Region,O.Order_ID,Order_Date,Ship_Date,ROUND(Sales,2) AS Sales,
P.Product_ID,Product_Name,Category,Sub_Category,S.Shipper_ID,Ship_Mode
FROM Customers C INNER JOIN Orders O
ON C.Customer_ID=O.Customer_ID INNER JOIN OrderDetails OD
ON O.Order_ID=OD.Order_ID INNER JOIN Products P
ON P.Product_ID=OD.Product_ID INNER JOIN Shippers S 
ON O.Shipper_ID=S.Shipper_ID

-------------------------------------INSIGHTS-----------------------------
--Max and Min sales for each quarter for each year
SELECT YEAR(Order_Date) AS Year, DATEPART(QUARTER,Order_Date) AS Quarter, ROUND(MAX(Sales),2) AS Max_Sales, ROUND(MIN(Sales),2) AS Min_Sales
FROM Orders
GROUP BY YEAR(Order_Date),DATEPART(QUARTER,Order_Date)
ORDER BY Year,Quarter;

-- Aquisition of Customers
WITH CTE AS(
SELECT YEAR(Order_Date) AS Year,DATENAME(MONTH,Order_Date) AS Month_Name,DATEPART(MONTH,Order_Date) AS mt, COUNT(C.Customer_ID) AS Count_of_customers
FROM Customers C INNER JOIN Orders O
ON C.Customer_ID = O.Customer_ID
GROUP BY YEAR(Order_Date),DATENAME(MONTH,Order_Date),DATEPART(MONTH,Order_Date))
SELECT Year,Month_Name,Count_of_customers FROM CTE
ORDER BY Year,mt

-- TOP 3 CUSTOMERS WHO BOUGHT MORE NUMBER OF PRODUCTS
WITH CTE AS(
SELECT YEAR(Order_Date) AS Year,DATENAME(MONTH,Order_Date) AS Month_Name,DATEPART(MONTH,Order_Date) AS mt,
CONCAT(First_Name,' ',Last_Name) AS Full_Name, COUNT(P.Product_ID) AS Product_Count
FROM Customers C INNER JOIN Orders O
ON C.Customer_ID = O.Customer_ID INNER JOIN OrderDetails OD
ON O.Order_ID=OD.Order_ID INNER JOIN Products P
ON P.Product_ID=OD.Product_ID
GROUP BY YEAR(Order_Date),DATENAME(MONTH,Order_Date),DATEPART(MONTH,Order_Date),CONCAT(First_Name,' ',Last_Name)),
CTE1 AS(
SELECT *,ROW_NUMBER() OVER(PARTITION BY Year,Month_Name ORDER BY Product_Count DESC) AS RNK
FROM CTE)
SELECT Year,Month_Name,Full_Name,Product_Count
FROM CTE1
WHERE RNK<=3
ORDER BY Year,mt,Product_Count DESC,Full_Name;









