
--Q1--BEGIN 
	
-- List all the states in which we have customers who have bought cellphones from 2005 till today.   

SELECT DISTINCT State
FROM (
SELECT State,
YEAR(Date) AS YEARS
FROM FACT_TRANSACTIONS T
LEFT JOIN DIM_LOCATION L
ON L.IDLocation = T.IDLocation
WHERE YEAR(Date) BETWEEN 2005 and 2026) X


--Q1--END

--Q2--BEGIN
	
-- What state in the US is buying the most 'Samsung' cell phones? 

SELECT TOP 1
    State ,
        SUM(Quantity) as sold_phone
FROM FACT_TRANSACTIONS T
LEFT JOIN DIM_LOCATION L
ON L.IDLocation = T.IDLocation
LEFT JOIN DIM_MODEL M
ON M.IDModel = T.IDModel
LEFT JOIN DIM_MANUFACTURER MA
ON MA.IDManufacturer = M.IDManufacturer
WHERE Country = 'US' AND Manufacturer_Name = 'Samsung'
GROUP BY State
ORDER BY sold_phone DESC



--Q2--END

--Q3--BEGIN      
	
 --Show the number of transactions for each model per zip code per state. 

 SELECT ZipCode ,
        m.IDModel,
        State,
        COUNT(*) No_of_transaction
 FROM FACT_TRANSACTIONS T
 JOIN DIM_LOCATION L
 ON T.IDLocation = L.IDLocation
 JOIN DIM_MODEL M 
 ON M.IDModel =T.IDModel
 GROUP BY ZipCode , m.IDModel , State   


--Q3--END

--Q4--BEGIN
-- Show the cheapest cellphone (Output should contain the price also)

SELECT TOP 1 Model_Name,
        Unit_price
FROM DIM_MODEL
ORDER BY Unit_price 


--Q4--END

--Q5--BEGIN
    --Find out the average price for each model in the top5 manufacturers in  
    --terms of sales quantity and order by average price.  

    WITH TOP5 AS(
        SELECT top 5 MA.Manufacturer_Name,
                SUM(Quantity) AS sold_phone
        FROM FACT_TRANSACTIONS T
        LEFT JOIN DIM_MODEL M
        ON M.IDModel = T.IDModel 
        LEFT JOIN DIM_MANUFACTURER MA
        ON MA.IDManufacturer = M.IDManufacturer
        group by MA.Manufacturer_Name
        order by sold_phone desc
    )
    SELECT T.IDModel ,MA.Manufacturer_Name,
            AVG(TotalPrice) AS AVERAGE
    FROM FACT_TRANSACTIONS T
    LEFT JOIN  DIM_MODEL M
    ON M.IDModel=T.IDModel
    LEFT JOIN DIM_MANUFACTURER MA
    ON MA.IDManufacturer = M.IDManufacturer

    WHERE MA.Manufacturer_Name IN (SELECT Manufacturer_Name FROM TOP5 )
    GROUP BY T.IDModel,MA.Manufacturer_Name



--Q5--END

--Q6--BEGIN
--List the names of the customers and the average amount spent in 2009,  
--where the average is higher than 500 

SELECT Customer_Name,
        AVG(TotalPrice) AS Spend
FROM FACT_TRANSACTIONS T
LEFT JOIN DIM_CUSTOMER C
ON T.IDCustomer = C.IDCustomer
WHERE YEAR(Date) = '2009' 
GROUP BY Customer_Name
HAVING AVG(TotalPrice) > 500


--Q6--END
	
--Q7--BEGIN  
-- List if there is any model that was in the top 5 in terms of quantity,simultaneously in 2008, 2009 and 2010.

SELECT IDModel FROM (
SELECT TOP 5 IDModel,SUM(Quantity) SOLD_QTY
FROM FACT_TRANSACTIONS
WHERE YEAR(DATE) = '2008'
GROUP BY IDModel
ORDER BY SOLD_QTY DESC) X
intersect
SELECT IDModel FROM (
SELECT TOP 5 IDModel,SUM(Quantity) SOLD_QTY
FROM FACT_TRANSACTIONS
WHERE YEAR(DATE) = '2009'
GROUP BY IDModel
ORDER BY SOLD_QTY DESC) X
intersect
SELECT IDModel FROM (
SELECT TOP 5 IDModel,SUM(Quantity) SOLD_QTY
FROM FACT_TRANSACTIONS
WHERE YEAR(DATE) = '2010'
GROUP BY IDModel
ORDER BY SOLD_QTY DESC) X;


--Q7--END	

--Q8--BEGIN
--Show the manufacturer with the 2nd top sales in the year of 2009 and the  manufacturer with the 2nd top sales in the year of 2010.  
 
WITH Top2 AS (
SELECT 
YEAR(Date) AS Year_,
Manufacturer_Name,
SUM(TotalPrice) AS TotalPrice,
DENSE_RANK() OVER(PARTITION BY YEAR(Date)ORDER BY SUM(TotalPrice) DESC ) AS rn
FROM FACT_TRANSACTIONS t
JOIN DIM_MODEL m 
ON m.IDModel = t.IDModel
JOIN DIM_MANUFACTURER ma 
ON ma.IDManufacturer = m.IDManufacturer
WHERE YEAR(Date) IN (2009,2010)
GROUP BY YEAR(Date), Manufacturer_Name
)
SELECT 
       Year_,
       Manufacturer_Name,
       TotalPrice FROM Top2
WHERE rn = 2

--Q8--END
--Q9--BEGIN
/* Show the manufacturers that sold cellphones in 2010 but did not in 2009.  */
SELECT DISTINCT Manufacturer_Name
FROM fac t
JOIN DIM_MODEL m 
ON t.IDModel = m.IDModel
JOIN DIM_MANUFACTURER ma 
ON ma.IDManufacturer = m.IDManufacturer
WHERE YEAR(Date) = 2010

EXCEPT

SELECT DISTINCT Manufacturer_Name
FROM FACT_TRANSACTIONS t
JOIN DIM_MODEL m 
ON t.IDModel = m.IDModel
JOIN DIM_MANUFACTURER ma 
ON ma.IDManufacturer = m.IDManufacturer
WHERE YEAR(Date) = 2009;


--Q9--END

--Q10--BEGIN
--. Find top 10 customers and their average spend, average quantity by each  year.
-- Also find the percentage of change in their spend. 

WITH TOP10 AS (
SELECT TOP 10
C.IDCustomer,
C.Customer_Name,
SUM(T.TotalPrice) AS TotalSpend
FROM FACT_TRANSACTIONS T
JOIN DIM_CUSTOMER C
ON C.IDCustomer = T.IDCustomer
GROUP BY C.IDCustomer, C.Customer_Name
ORDER BY TotalSpend DESC
),

YEARLY_DATA AS (
SELECT 
C.Customer_Name,
YEAR(T.Date) AS Year_,
AVG(T.TotalPrice) AS Avg_Spend,
AVG(T.Quantity) AS Avg_Quantity
FROM FACT_TRANSACTIONS T
JOIN DIM_CUSTOMER C
ON C.IDCustomer = T.IDCustomer
WHERE C.IDCustomer IN (SELECT IDCustomer FROM TOP10)
GROUP BY C.Customer_Name, YEAR(T.Date)
)
SELECT 
Customer_Name,
Year_,
Avg_Spend,
Avg_Quantity,
LAG(Avg_Spend) OVER(PARTITION BY Customer_Name ORDER BY Year_) AS Previous_Year_Spend,
ROUND(((Avg_Spend - LAG(Avg_Spend) OVER(PARTITION BY Customer_Name ORDER BY Year_ )) /
LAG(Avg_Spend) OVER(PARTITION BY Customer_Name ORDER BY Year_)) * 100,2) AS Spend_Percentage_Change
FROM YEARLY_DATA

--Q10--END
	