



------------      27-06-2022 RDB & SQL Course Project Session    ------------


--1. Join all the tables and create a new table called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)


SELECT *
INTO combined_table
FROM
(
SELECT 
cd.Cust_id, cd.Customer_Name, cd.Province, cd.Region, cd.Customer_Segment, 
mf.Ord_id, mf.Prod_id, mf.Sales, mf.Discount, mf.Order_Quantity, mf.Product_Base_Margin,
od.Order_Date, od.Order_Priority,
pd.Product_Category, pd.Product_Sub_Category,
sd.Ship_id, sd.Ship_Mode, sd.Ship_Date
FROM market_fact mf
INNER JOIN cust_dimen cd ON mf.Cust_id = cd.Cust_id
INNER JOIN orders_dimen od ON od.Ord_id = mf.Ord_id
INNER JOIN prod_dimen pd ON pd.Prod_id = mf.Prod_id
INNER JOIN shipping_dimen sd ON sd.Ship_id = mf.Ship_id
) A





SELECT *
FROM combined_table




--2. Find the top 3 customers who have the maximum count of orders.


SELECT	TOP 3 Cust_id, COUNT (DISTINCT Ord_id) CNT_ORDERS
FROM	combined_table
GROUP BY Cust_id 
ORDER BY CNT_ORDERS DESC





--3.Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
--Use "ALTER TABLE", "UPDATE" etc.


ALTER TABLE combined_table
ADD DaysTakenForDelivery INT 



UPDATE combined_table
SET DaysTakenForDelivery = DATEDIFF (DAY, Order_Date, Ship_Date)



SELECT *
FROM	combined_table




------


--4. Find the customer whose order took the maximum time to get delivered.
--Use "MAX" or "TOP"



SELECT	top 1 *
FROM	combined_table
ORDER BY daysTakenForDelivery Desc




select [Cust_id],[Customer_Name],DaysTakenForDelivery  
from [dbo].[combined_table]
where DaysTakenForDelivery = (select max(DaysTakenForDelivery) from [dbo].[combined_table])

----



--5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
--You can use such date functions and subqueries


--2011 Ocak ay�nda gelen m��terilerin, 2011' in di�er aylar�nda ka� tanesinin tekrar geldi�ini g�steriniz.

WITH T1 AS (
SELECT	DISTINCT Cust_id
FROM	combined_table
WHERE	YEAR (Order_Date) = 2011
AND		MONTH(Order_Date) = 1
)
SELECT	DATENAME(MONTH, Order_Date) ORD_MONTH, MONTH(order_date) ord_month_2 , COUNT (DISTINCT T1.Cust_id) CNT_CUST
FROM	combined_table A, T1 
WHERE	A.Cust_id = T1.Cust_id
AND		YEAR (Order_Date) = 2011
GROUP BY 	DATENAME(MONTH, Order_Date), MONTH(order_date)
ORDER BY 2



------------------



----------

--6. write a query to return for each user the time elapsed between the first purchasing and the third purchasing, 
--in ascending order by Customer ID
--Use "MIN" with Window Functions



---Her m��terinin ilk sipari�i ile 3. sipari�i aras�ndaki g�n fark�n� d�nd�ren bir sorgu yaz�n�z.

SELECT	DISTINCT Cust_id, Order_Date, Ord_id
FROM	combined_table
WHERE Cust_id = 'Cust_1025'
ORDER BY 2,3




WITH T1 AS (
SELECT	DISTINCT Cust_id, MIN (Order_Date) OVER (PARTITION BY cust_id) First_order_date
FROM	combined_table
), T2 AS
(
SELECT	DISTINCT Cust_id, Order_date, ord_id,
		DENSE_RANK () OVER (PARTITION BY cust_id ORDER BY order_date, ord_id) ord_date_number
FROM	combined_table
)
SELECT DISTINCT t1.cust_id, First_order_date, Order_Date, ord_date_number, DATEDIFF (DAY, t1.First_order_date,t2.Order_Date) DATE_DIFF
FROM T1, T2
WHERE T1.Cust_id = T2.Cust_id
AND	 T2.ord_date_number = 3






select * 
from combined_table
where cust_id = 'cust_110'
order by Order_Date

-------------------


--7. Write a query that returns customers who purchased both product 11 and product 14, 
--as well as the ratio of these products to the total number of products purchased by the customer.
--Use CASE Expression, CTE, CAST AND such Aggregate Functions



---Her bir m��teri i�in 11 numaral� �r�n� ve 14 numaral� �r�n� ald�klar� say�n�n ald�klar� t�m �r�n say�s�na oran�.

SELECT Cust_id, SUM(Order_Quantity) CNT_PROD
FROM combined_table
WHERE Prod_id = 'Prod_11'
GROUP BY Cust_id



WITH T1 AS 
(
SELECT Cust_id, 
		SUM(CASE WHEN Prod_id = 'Prod_11' THEN Order_Quantity ELSE 0 END ) cnt_prod_11 ,
		SUM (CASE WHEN Prod_id = 'Prod_14' THEN Order_Quantity ELSE 0 END ) cnt_prod_14
FROM combined_table
GROUP BY Cust_id
HAVING
	SUM(CASE WHEN Prod_id = 'Prod_11' THEN Order_Quantity ELSE 0 END ) > 0
	AND
	SUM (CASE WHEN Prod_id = 'Prod_14' THEN Order_Quantity ELSE 0 END ) > 0
), T2 AS (
SELECT Cust_id, SUM (Order_Quantity) Total_prod
FROM	combined_table
GROUP BY Cust_id
)
SELECT T1.cust_id,  CAST (1.0*cnt_prod_11/Total_prod AS numeric(3,2)) AS prod_11_rate, CAST (1.0*cnt_prod_14/Total_prod AS NUMERIC(3,2)) AS  prod_14_rate
FROM	T1, T2
WHERE	T1.cust_id = T2.cust_id



-----------------------


--CUSTOMER SEGMENTATION


--M��TER�LER�N S�PAR��LER� ARASINDAK� ORTALAMA AY SAYISI

--E�ER M��TER� ORTALAMA 3 AYDA B�R S�PAR�� VER�YORSA D�ZENS�Z B�R M��TER� OLARAK KABUL ED�LEB�L�R.
--....


CREATE VIEW CUST_MONTH_VIEW AS 
SELECT DISTINCT cust_id, YEAR (Order_Date) ORD_YEAR, MONTH(Order_Date) ORD_MONTH_2,
		DENSE_RANK() OVER (ORDER BY YEAR (Order_Date), MONTH(Order_Date)) ORD_MONTH
FROM combined_table



CREATE VIEW TIME_GAPS AS 
SELECT *, ORD_MONTH - LAG (ORD_MONTH) OVER (PARTITION BY cust_id ORDER BY ORD_MONTH) TIME_GAP
FROM CUST_MONTH_VIEW



WITH T1 AS 
(
SELECT Cust_id, AVG(TIME_GAP) AVG_TIME_GAP
FROM TIME_GAPS
GROUP BY Cust_id
)
SELECT Cust_id, 
		CASE WHEN AVG_TIME_GAP <= 2 THEN 'regular' 
			WHEN AVG_TIME_GAP >2 THEN 'irregular'
			ELSE 'churn' 
		END AS CUST_LABEL
FROM T1
order by 2




--MONTH-WISE RETENTION RATE

--Ayl�k m��teri kazanma oran�.

--2011 �ubat ay�nda gelen 100 m��teriden 10 tanesi 2011 ocak ay�nda gelenlerdendi. 



SELECT *
FROM TIME_GAPS
WHERE TIME_GAP = 1
ORDER BY Cust_id, ORD_MONTH



WITH T1 AS (
--her ay�n toplam m��teri say�s�
SELECT ORD_MONTH , count (DISTINCT Cust_id) CNT_CUSTOMER
FROM TIME_GAPS
GROUP BY ORD_MONTH
), T2 AS (
--her ay i�in bir �nceki aydan gelen m��teri say�s�
SELECT ORD_MONTH , count (DISTINCT Cust_id) CNT_CUSTOMER_PREV_MONTH
FROM TIME_GAPS
WHERE TIME_GAP = 1
GROUP BY ORD_MONTH
) 
SELECT DISTINCT T1.*, T2.*, C.ORD_YEAR, C.ORD_MONTH_2,  CAST (1.0*CNT_CUSTOMER_PREV_MONTH / CNT_CUSTOMER AS numeric (3,2)) MONTHLY_RETENTION_RATE
FROM T1, T2, TIME_GAPS C
WHERE T1.ORD_MONTH = T2.ORD_MONTH
AND T2.ORD_MONTH = C.ORD_MONTH









drop table if exists result_table
create table result_table (
	years int,
	months int,
	monthly_rate decimal(10,2)
)
----------
---------
declare	 @rank_min int
		,@rank_max int
		,@result decimal(10,2)

select @rank_min = min(rank_by_time) from tbl_by_time
select @rank_max = max(rank_by_time) from tbl_by_time

while @rank_min < @rank_max
begin
	with t1 as(
	select cust_id
	from tbl_by_time
	where	rank_by_time = @rank_min
	intersect 
	select cust_id
	from tbl_by_time
	where	rank_by_time = @rank_min+1
	) 
	select @result = (1.0*count(*)/(select count(*) from tbl_by_time where rank_by_time = @rank_min+1))
	from t1	
insert into result_table 
values ( (select distinct years from tbl_by_time where rank_by_time=@rank_min+1)
		,(select distinct months from tbl_by_time where rank_by_time=@rank_min+1)
		,@result
		)
set @rank_min += 1
end


----



CREATE VIEW log_customer AS 
SELECT DISTINCT Cust_id, Ord_id, Order_date, MONTH(Order_Date) [Month], YEAR(Order_Date) [Year]
FROM combined_table

SELECT DISTINCT [Year], [Month], 
	SUM (CASE WHEN Monthly_time_gap = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY [Year], [Month])
	AS number_retained_customers
FROM (
SELECT *,
		DATEDIFF(month, Order_date, lead(Order_date) OVER (PARTITION BY Cust_id ORDER BY Order_Date )) AS Monthly_time_gap
FROM log_customer ) AS a
ORDER BY 1,2




select * 
FROM combined_table








