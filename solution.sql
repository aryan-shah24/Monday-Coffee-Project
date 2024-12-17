CREATE  DATABASE monday_coffee;

CREATE TABLE city
(
  city_id INT PRIMARY KEY,
  city_name VARCHAR(15),
  population BIGINT,
  estimated_rent FLOAT,
  city_rank INT
);

CREATE TABLE customers
( 
 customer_id INT PRIMARY KEY,
 customer_name VARCHAR(25),
 city_id INT,
 CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id) 
);

CREATE TABLE products
(
 product_id INT PRIMARY KEY,
 product_name VARCHAR(35),
 price FLOAT
);

CREATE TABLE sales
(
 sale_id INT PRIMARY KEY,
 sale_date date,
 product_id INT,
 customer_id INT,
 total FLOAT,
 rating INT,
 CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
 CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

-- Monday Coffee -- Reports & Data Analysis

-- Q1. Coffee consumers count 
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
       city_name, ROUND((population * 0.25)/1000000, 2) as coffee_consumers_in_millions, city_rank
FROM city
ORDER BY 2 DESC;

-- Q2. Total revenue from coffee sales
-- What is the total revenue generated from coffee sales across all citiess in the last quarter of 2023?

SELECT 
  ci.city_name,
  SUM(s.total) as total_revenue
 FROM sales as s
 JOIN customers as c
 ON s.customer_id = c.customer_id
 JOIN city as ci
 ON ci.city_id = c.city_id
 WHERE EXTRACT(YEAR FROM s.sale_date) = 2023
 AND EXTRACT(QUARTER FROM s.sale_date) = 4
 GROUP BY 1
 ORDER BY 2 DESC;
 
 -- Q3. Sales count for each product
 -- How any units of each coffee product have been sold?
 
 SELECT 
   p.product_name,
   COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q4.Average sales amount per city 
-- What is the average sales amount per customer in each city? 

SELECT 
  ci.city_name,
  SUM(s.total) as total_revenue,
  COUNT(DISTINCT s.customer_id) as total_customer,
  ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
 FROM sales as s
 JOIN customers as c
 ON s.customer_id = c.customer_id
 JOIN city as ci
 ON ci.city_id = c.city_id
 GROUP BY 1
 ORDER BY 2 DESC;
 
 -- Q5. City population and Coffee Consumers
 -- Provide a list of cities along with their populations and estimated coffee consumers
 
 WITH city_table as
(
  SELECT 
   city_name,
   ROUND((population * 0.25)/1000000, 2) AS coffee_consumers
FROM city
),
customers_table AS
(SELECT
  ci.city_name,
  COUNT(DISTINCT c.customer_id) as unique_cx
FROM sales as s
JOIN customers as c 
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1)
SELECT 
  customers_table.city_name,
  city_table.coffee_consumers,
  customers_table.unique_cx
FROM city_table 
JOIN customers_table 
ON city_table.city_name = customers_table.city_name;

-- Q6. Top selling products  by city 
-- What are the top 3 selling products in each city based on sales volumes

SELECT * FROM 
(
SELECT 
  ci.city_name,
  p.product_name,
  COUNT(s.sale_id) as total_orders,
  DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as ranks
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city  as ci
ON ci.city_id = c.city_id
GROUP BY 1, 2
) as t1
WHERE ranks <= 3;

-- Q7. Customer segmentation by city 
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
  ci.city_name,
  COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s 
ON s.customer_id = c.customer_id
WHERE
  s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ,13, 14)
GROUP BY 1;

-- Q8. Average sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH city_table
AS
(SELECT 
  ci.city_name,
  COUNT(DISTINCT s.customer_id) as total_cx,
  ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
FROM sales as s
JOIN customers as c 
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent AS
(SELECT 
  city_name,
  estimated_rent
FROM city)

SELECT 
  cr.city_name,
  cr.estimated_rent,
  ct.total_cx,
  ct.avg_sale_per_customer,
  ROUND(cr.estimated_rent/ct.total_cx, 2) as avg_rent_per_cx
FROM city_rent as cr 
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 5 DESC;

-- Q.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline)in sales over different time periods (monthly) by each city 

WITH monthly_sales 
AS
(SELECT 
  ci.city_name,
  EXTRACT(MONTH FROM sale_date) as month,
  EXTRACT(YEAR FROM sale_date) as year,
  SUM(s.total) as total_sale
FROM sales as s
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1, 2, 3
ORDER BY 1, 3, 2
),
growth_ratio AS
(SELECT
  city_name,
  month,
  year,
  total_sale as cr_month_sale,
  LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
  FROM monthly_sales
)
SELECT
  city_name,
  month,
  year,
  cr_month_sale,
  last_month_sale,
  ROUND((cr_month_sale-last_month_sale)/last_month_sale * 100, 2) as growth_ratio
  FROM growth_ratio
  WHERE
    last_month_sale IS NOT NULL;
    
-- Q10. Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumers
    
WITH city_table
AS
(SELECT 
  ci.city_name,
  SUM(s.total) as total_revenue,
  COUNT(DISTINCT s.customer_id) as total_cx,
  ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id), 2) AS avg_sale_per_customer
FROM sales as s
JOIN customers as c 
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
),
city_rent AS
(SELECT 
  city_name,
  estimated_rent,
  ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
FROM city)

SELECT 
  cr.city_name,
  total_revenue,
  cr.estimated_rent as total_rent,
  ct.total_cx,
  estimated_coffee_consumer,
  ct.avg_sale_per_customer,
  ROUND(cr.estimated_rent/ct.total_cx, 2) as avg_rent_per_cx
FROM city_rent as cr 
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;

/*
-- Recommandations
City 1. Pune
    1. Avg rent per cx is very less,
    2.highest total revenue,
    3.ave_sales per cx is also high

City 2. Delhi
    1. Highest estimated coffee consumer which is 7.7M
    2. Highest total cs which is 68
    3. avg rent per cx is 330 (still under 500)
    
City 3. Jaipur
    1. Highest cx no which is 69
    2. avg rent per cx is very less 156
    3. avg sales per cx is better which at 11.6k