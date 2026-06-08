CREATE DATABASE SUPERSTORE;
USE SUPERSTORE;


/* Find the top 5 states by total sales. */

SELECT TOP 5
state, SUM(sales) AS TOTAL_SALES
FROM superstore_clean
GROUP BY state
ORDER BY TOTAL_SALES DESC;


/* Find the profit margin for each category. */

SELECT category,
CONCAT(ROUND(SUM(profit) * 100.0 / SUM(sales), 2), '%') AS PROFIT_MARGIN
FROM superstore_clean
GROUP BY category;


/* Find the top 10 loss-making products. */

SELECT TOP 10
product_id, product_name,
SUM(profit) AS TOTAL_PROFIT
FROM superstore_clean
GROUP BY product_id, product_name
ORDER BY TOTAL_PROFIT ASC;


/* Find all categories whose total sales are greater than the average category sales. */

SELECT category,
SUM(sales) AS TOTAL_SALES
FROM superstore_clean
GROUP BY category
HAVING SUM(sales) > (
    SELECT AVG(total_sales)
    FROM (SELECT SUM(sales) AS total_sales
    FROM superstore_clean
    GROUP BY category) AS SUB
);


/* Find the top 3 products by total sales in each category. */

WITH PRODUCT_SALES_BY_CATEGORY AS
(SELECT product_id, product_name, category,
SUM(sales) AS TOTAL_SALES
FROM superstore_clean
GROUP BY product_id, category, product_name),
RANKED_PRODUCTS AS
(SELECT *,
RANK() OVER (PARTITION BY category ORDER BY TOTAL_SALES DESC) AS SALES_RANK
FROM PRODUCT_SALES_BY_CATEGORY)
SELECT * FROM RANKED_PRODUCTS
WHERE SALES_RANK <= 3;


/* Find the average profit of all categories and return only those categories
whose total profit is greater than the average category profit. */

WITH AVG_PROFIT_CAT AS
(SELECT category,
SUM(profit) AS TOTAL_PROFIT
FROM superstore_clean
GROUP BY category)
SELECT * FROM AVG_PROFIT_CAT
WHERE TOTAL_PROFIT > (SELECT AVG(TOTAL_PROFIT) FROM AVG_PROFIT_CAT);


/* Find the customer with the highest total sales in each region
using a CTE and ROW_NUMBER(). */

WITH CUST_BY_HIGH_SALES_REGION AS
(SELECT customer_id, customer_name, region,
SUM(sales) AS TOTAL_SALES
FROM superstore_clean
GROUP BY customer_id, customer_name, region),
RANK_CAT AS
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY region ORDER BY TOTAL_SALES DESC) AS ROW_NUM
FROM CUST_BY_HIGH_SALES_REGION)
SELECT * FROM RANK_CAT
WHERE ROW_NUM = 1;


/* Find the second highest profit product in each category using a CTE and ROW_NUMBER(). */

WITH PRODUCT_SALES AS
(SELECT product_id, product_name, category,
SUM(profit) AS TOTAL_PROFIT
FROM superstore_clean
GROUP BY product_id, product_name, category),
RANKED_PRODUCT AS
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY category ORDER BY TOTAL_PROFIT DESC) AS ROW_NUM
FROM PRODUCT_SALES)
SELECT * FROM RANKED_PRODUCT
WHERE ROW_NUM = 2;


/* Write a query to find the month-over-month sales growth percentage. */

WITH MONTHLY_SALES AS
(SELECT year, month,
SUM(sales) AS MONTHLY_SALES
FROM superstore_clean
GROUP BY year, month),
PREV_MONTH_SALES AS
(SELECT *,
LAG(MONTHLY_SALES) OVER (ORDER BY year, month ASC) AS PREV_MONTH
FROM MONTHLY_SALES)
SELECT year, month, MONTHLY_SALES, PREV_MONTH,
ROUND((MONTHLY_SALES - PREV_MONTH) * 100.0 / PREV_MONTH, 2) AS MOM_GROWTH_PERCENT
FROM PREV_MONTH_SALES
WHERE PREV_MONTH IS NOT NULL
ORDER BY year, month;


/* Find each category's profit contribution as a percentage of total profit. */

SELECT category,
SUM(profit) AS TOTAL_PROFIT,
CONCAT(ROUND(SUM(profit) * 100.0 / SUM(SUM(profit)) OVER (), 2), '%') AS PROFIT_CONTRIBUTION
FROM superstore_clean
GROUP BY category;