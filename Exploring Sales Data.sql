---Inspecting Data
select * from PortfolioProject1.dbo.sales_data_sample
--Checking unique values
select distinct status from PortfolioProject1.dbo.sales_data_sample 
select distinct year_id from PortfolioProject1.dbo.sales_data_sample
select distinct PRODUCTLINE from PortfolioProject1.dbo.sales_data_sample 
select distinct COUNTRY from PortfolioProject1.dbo.sales_data_sample
select distinct DEALSIZE from PortfolioProject1.dbo.sales_data_sample 
select distinct TERRITORY from PortfolioProject1.dbo.sales_data_sample 

SELECT DISTINCT MONTH_ID FROM PortfolioProject1.dbo.sales_data_sample
WHERE year_id = 2003

---Analysis
----Let's start by grouping sales by productline
SELECT PRODUCTLINE, SUM(sales) Revenue
FROM PortfolioProject1.dbo.sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC


SELECT YEAR_ID, SUM(sales) Revenue
FROM PortfolioProject1.dbo.sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC

SELECT DEALSIZE,  sum(sales) Revenue
FROM PortfolioProject1.dbo.sales_data_sample
GROUP BY  DEALSIZE
ORDER BY 2 DESC


----What was the best month for sales in a specific year? How much was earned that month? 
SELECT  MONTH_ID, SUM(sales) Revenue, COUNT(ORDERNUMBER) Frequency
FROM PortfolioProject1.dbo.sales_data_sample
WHERE YEAR_ID = 2004 --change year to see the rest
GROUP BY  MONTH_ID
ORDER BY 2 DESC


--November seems to be the month, what product do they sell in November
SELECT  MONTH_ID, PRODUCTLINE, SUM(sales) Revenue, COUNT(ORDERNUMBER)
FROM PortfolioProject1.dbo.sales_data_sample
WHERE YEAR_ID = 2004 AND MONTH_ID = 11 --change year to see the rest
GROUP BY  MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC


----Who is our best customer (this could be best answered with RFM)


DROP TABLE IF EXISTS #rfm
;WITH rfm AS
(
	SELECT
		CUSTOMERNAME, 
		SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) last_order_date,
		(SELECT MAX(ORDERDATE) FROM PortfolioProject1.dbo.sales_data_sample) max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM PortfolioProject1.dbo.sales_data_sample)) Recency
	FROM PortfolioProject1.dbo.sales_data_sample
	GROUP BY CUSTOMERNAME
),
rfm_calc AS
(

	SELECT r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	FROM rfm r
)
SELECT
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary AS rfm_cell,
	CAST(rfm_recency AS varchar) + CAST(rfm_frequency AS varchar) + CAST(rfm_monetary  AS varchar)rfm_cell_string
INTO #rfm
FROM rfm_calc c

SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	CASE
		WHEN rfm_cell_string IN (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  --lost customers
		WHEN rfm_cell_string IN (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- (Big spenders who havent purchased lately) slipping away
		WHEN rfm_cell_string IN (311, 411, 331) THEN 'new customers'
		WHEN rfm_cell_string IN (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfm_cell_string IN (323, 333,321, 422, 332, 432) THEN 'active' --(Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string IN (433, 434, 443, 444) then 'loyal'
	END rfm_segment

FROM #rfm



--What products are most often sold together? 
--select * from [dbo].[sales_data_sample] where ORDERNUMBER =  10411

SELECT DISTINCT ORDERNUMBER, STUFF(

	(select ',' + PRODUCTCODE
	from PortfolioProject1.dbo.sales_data_sample p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, COUNT(*) rn
				FROM PortfolioProject1.dbo.sales_data_sample
				WHERE STATUS = 'Shipped'
				GROUP BY  ORDERNUMBER
			)m
			WHERE rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		FOR xml path (''))

		, 1, 1, '') ProductCodes

FROM PortfolioProject1.dbo.sales_data_sample s
ORDER BY 2 DESC


---EXTRAs----
--What city has the highest number of sales in a specific country
SELECT city, SUM (sales) Revenue
FROM PortfolioProject1.dbo.sales_data_sample
WHERE country = 'UK'
GROUP BY city
ORDER BY 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from PortfolioProject1.dbo.sales_data_sample
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 DESC
