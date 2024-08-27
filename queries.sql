1. Order and Sales Overview
1.1 Retrieve the total number of orders placed (To understand the overall demand for pizzas and gauge the volume of business).
SELECT 
    COUNT(order_id) number_of_orders
FROM 
    sorted_orders

1.2 Calculate the total revenue generated from pizza sales (To measure the total financial performance from pizza sales).
SELECT
    ROUND(SUM(quantity * price),2) revenue_pizza
FROM 
    order_details details
JOIN
    pizzas
ON 
    details.pizza_id = pizzas.pizza_id

  1.3 Identify the highest-priced pizza (To determine the premium product on the menu, which could be a focal point for marketing or sales strategies).
SELECT TOP 1
    *
FROM 
    pizzas
ORDER BY 
    price DESC

1.4 Identify the most common pizza size ordered (To understand customer preferences related to pizza size, which can help in inventory management and menu optimization).
SELECT TOP 1
    size,
    COUNT(order_details_id) number_size
FROM
    order_details details
JOIN 
    pizzas
ON  
    details.pizza_id = pizzas.pizza_id
GROUP BY 
    size
ORDER BY 
    COUNT(order_details_id) DESC


2. Pizza Types and Categories Analysis
2.1 List the top 5 most ordered pizza types along with their quantities (To identify the most popular pizzas, which can inform menu planning and promotional strategies).
SELECT TOP 5
    name,
    SUM(quantity) AS quantities
FROM 
    order_details AS details
LEFT JOIN
    pizzas
ON 
    details.pizza_id = pizzas.pizza_id
LEFT JOIN 
    pizza_types
ON 
    pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY name
ORDER BY SUM(quantity) DESC

2.2 Find the total quantity of each pizza category ordered (To understand customer preferences by category (e.g., vegetarian, meat lovers) and determine which categories are most favored).
SELECT DISTINCT
    category,
    SUM(quantity) OVER(PARTITION BY category) AS total_quantity_pizzas
FROM    
    order_details AS details
LEFT JOIN
    pizzas
ON
    details.pizza_id = pizzas.pizza_id
LEFT JOIN
    pizza_types
ON
    pizzas.pizza_type_id = pizza_types.pizza_type_id

3. Determine the top 3 most ordered pizza types based on revenue (To identify the best-selling pizzas from a revenue perspective and focus on these for sales strategies).
SELECT TOP 3
    name,
    SUM(price * quantity) AS revuene
FROM
    order_details AS details
LEFT JOIN
    pizzas
ON 
    details.pizza_id = pizzas.pizza_id
LEFT JOIN
    pizza_types
ON 
    pizza_types.pizza_type_id =  pizzas.pizza_type_id
GROUP BY
    name
ORDER BY
    SUM(price * quantity) DESC

2.4 Determine the top 3 most ordered pizza types based on revenue for each pizza category (To see which pizzas perform best within each category, helping to refine category-specific marketing and product offerings).
WITH revenue_table AS 
(
    SELECT
        name,
        category,
        SUM(quantity * price) AS revenue
    FROM 
        order_details AS details
    LEFT JOIN
        pizzas
    ON
        details.pizza_id = pizzas.pizza_id
    LEFT JOIN
        pizza_types
    ON
        pizzas.pizza_type_id = pizza_types.pizza_type_id
    GROUP BY 
        category,
        name
)
SELECT TOP 3 *
FROM 
    revenue_table
ORDER BY 
    revenue DESC

3. Time-Based Analysis
3.1 Determine the distribution of orders by hour of the day (To identify peak ordering times, which can inform staffing, inventory management, and targeted promotions).
/*GROUP BY*/
SELECT
    DATEPART(HOUR,time) AS hour_of_the_day,
    COUNT(order_details_id) AS number_orders
FROM
    order_details AS details
JOIN    
    orders
ON
    details.order_id = orders.order_id
GROUP BY DATEPART(HOUR,time)
ORDER BY  DATEPART(HOUR,time) ASC

/*WINDOW FUNCTION*/
SELECT DISTINCT
    DATEPART(HOUR,time) AS hour_of_the_day,
    COUNT(order_details_id) OVER(PARTITION BY DATEPART(HOUR,time)) 
FROM
    order_details AS details
JOIN    
    orders
ON
    details.order_id = orders.order_id
ORDER BY 
    DATEPART(HOUR,time) ASC

3.2 Group the orders by date and calculate the average number of pizzas ordered per day (To assess daily order trends, which can help in forecasting demand and managing resources).
WITH group_order AS 
(
    SELECT
        date,
        SUM(quantity) AS number_of_pizzas
    FROM
        order_details AS details
    LEFT JOIN
        orders
    ON
        details.order_id = orders.order_id
    GROUP BY 
        date  
)
SELECT 
    ROUND(AVG(number_of_pizzas),0) AS the_average_number_of_pizzas_ordered_per_day  
FROM 
    group_order

3.3 Analyze the cumulative revenue generated over time (To track revenue growth over time, which can reveal seasonal trends and overall business health).
WITH revenue_table AS
(
  SELECT 
      DATEPART(YEAR,date) AS [year],
      DATEPART(MONTH,date) AS [month],
      DATEPART(DAY,date) AS [day],
      (quantity * price) AS revenue
  FROM
      order_details AS details
  LEFT JOIN
  sorted_orders
  ON 
      details.order_id = sorted_orders.order_id
  LEFT JOIN
      pizzas
  ON
      details.pizza_id = pizzas.pizza_id
)
SELECT DISTINCT
  [year],
  [month],
  [day],
  SUM(revenue) OVER(ORDER BY [year],[month],[day]) AS cumulative_revenue
FROM 
  revenue_table
ORDER BY
  [year],[month],[day]

3.4 Analyze the revenue by categories generated over time (To understand how different pizza categories perform over time, helping to adjust offerings and promotions accordingly).
WITH revenue_table AS
(
  SELECT 
      DATEPART(YEAR,date) AS [year],
      DATEPART(MONTH,date) AS [month],
      DATEPART(DAY,date) AS [day],
      category,
      (quantity * price) AS revenue
  FROM
      order_details AS details
  LEFT JOIN
  sorted_orders
  ON 
      details.order_id = sorted_orders.order_id
  LEFT JOIN
      pizzas
  ON
      details.pizza_id = pizzas.pizza_id
  LEFT JOIN
      pizza_types
  ON
      pizzas.pizza_type_id = pizza_types.pizza_type_id
)
SELECT DISTINCT
  [year],
  [month],
  [day],
  SUM(CASE WHEN category = 'Classic' THEN revenue END) OVER(PARTITION BY [year],[month],[day]) AS revenue_category_classic,
  SUM(CASE WHEN category = 'Supreme' THEN revenue END) OVER(PARTITION BY [year],[month],[day]) AS revenue_category_supreme,
  SUM(CASE WHEN category = 'Chicken' THEN revenue END) OVER(PARTITION BY [year],[month],[day]) AS revenue_category_chicken,
  SUM(CASE WHEN category = 'Veggie' THEN revenue END) OVER(PARTITION BY [year],[month],[day]) AS revenue_category_veggie
FROM 
  revenue_table
ORDER BY
  [year],[month],[day]

4. Revenue Contribution Analysis
4.1 Calculate the percentage contribution of each pizza type to total revenue (To understand the impact of each pizza on total sales, which can guide pricing and marketing strategies).
WITH revenue_table AS
(
  SELECT
      name,
      SUM(price * quantity) AS revenue
  FROM
      order_details AS details
  LEFT JOIN
      pizzas
  ON 
      details.pizza_id = pizzas.pizza_id
  LEFT JOIN
      pizza_types
  ON 
      pizza_types.pizza_type_id =  pizzas.pizza_type_id
  GROUP BY
      name
),
total_revenue_table AS
(
  SELECT 
      *,
      SUM(revenue) OVER() AS total_revenue
  FROM revenue_table
)
SELECT
  name,
  revenue,
  total_revenue,
  FORMAT((revenue*1.0/total_revenue),'p') AS revenue_percentage
FROM 
  total_revenue_table

4.2 Find the category-wise distribution of pizzas (To analyze customer behavior across different pizza categories, which can inform decisions on product diversification and inventory management).
SELECT
    category,
    COUNT(DISTINCT pizza_type_id) AS number_pizzas
FROM
    pizza_types
GROUP BY 
    category
