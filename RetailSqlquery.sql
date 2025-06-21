--Create empty table 

/*CREATE TABLE df_orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    ship_mode VARCHAR(20),
    segment VARCHAR(20),
    country VARCHAR(20),
    city VARCHAR(20),
    state VARCHAR(20),
    postal_code VARCHAR(20),
    region VARCHAR(20),
    category VARCHAR(20),
    sub_category VARCHAR(20),
    product_id VARCHAR(50),
    quantity INT,
    discount DECIMAL(7,2),
    sale_price DECIMAL(7,2),
    profit DECIMAL(7,2)
);*/


SELECT * FROM df_orders;

--Analysis part

--find top 10 highest reveue generating products
select top 10 product_id,
    sum(sale_price) as sales
from df_orders
group by product_id
order by sales desc;


--find top 5 highest selling products in each region

SELECT DISTINCT region from df_orders;

WITH RankedProducts AS (
    SELECT region, product_id,
        SUM(sale_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(sale_price) DESC) AS sales_rank
    FROM df_orders
    GROUP BY region, product_id
)
SELECT region, product_id, total_sales
FROM RankedProducts
WHERE sales_rank <= 5
ORDER BY region, total_sales DESC;

--find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023

SELECT DISTINCT year(order_date) FROM df_orders;


WITH MonthlyGrowth AS (
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month, 
        SUM(sale_price) AS total_sales 
    FROM df_orders
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT 
    order_month,
    SUM(CASE WHEN order_year = 2022 THEN total_sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN order_year = 2023 THEN total_sales ELSE 0 END) AS sales_2023
FROM MonthlyGrowth
GROUP BY order_month
ORDER BY order_month;

--for each category which month had highest sales

SELECT DISTINCT category FROM df_orders;

WITH CategoryMonthSales AS (
    SELECT 
        category,
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        SUM(sale_price) AS total_sales
    FROM df_orders
    GROUP BY category, YEAR(order_date), MONTH(order_date)
),
RankedSales AS (
    SELECT 
        category,
        order_year,
        order_month,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_sales DESC) AS sales_rank
    FROM CategoryMonthSales
)
SELECT category, order_year, order_month, total_sales
FROM RankedSales
WHERE sales_rank = 1
ORDER BY category;

--which sub category had highest growth by profit in 2023 compare to 2022

WITH ProfitByYear AS (
    SELECT 
        sub_category,
        YEAR(order_date) AS order_year,
        SUM(profit) AS total_profit
    FROM df_orders
    GROUP BY sub_category, YEAR(order_date)
),
Growth AS (
    SELECT 
        sub_category,
        SUM(CASE WHEN order_year = 2022 THEN total_profit ELSE 0 END) AS profit_2022,
        SUM(CASE WHEN order_year = 2023 THEN total_profit ELSE 0 END) AS profit_2023,
        SUM(CASE WHEN order_year = 2023 THEN total_profit ELSE 0 END) 
            - SUM(CASE WHEN order_year = 2022 THEN total_profit ELSE 0 END) AS profit_growth
    FROM ProfitByYear
    GROUP BY sub_category
)
SELECT sub_category, profit_2022, profit_2023, profit_growth
FROM Growth
ORDER BY profit_growth DESC;
