--segment products into cost ranges and count how many products fall into each segment
with product_segments as 
(select 
PRODUCT_key,
product_name,
cost,
case when cost <100 then 'Below 100'
			when cost between 100 and 500 then '100-500'
			when cost between 500 and 1000 then '500-1000'
			else 'Above 1000'
end cost_range																	--new column name
from gold.dim_products)

select 
cost_range,
count(product_key) as total_products
from product_segments
group by cost_range
order by total_products desc

--Group customers into three segments vased on their spending behaviour:
--VIP: customers with 12 months of history and spending more than 5000
--Regulare: 12 months of history but spending less than 5000
--New: customers with less than 12 months history
--find the total number of customers by each group
with customer_spending as
(select 
c.customer_key,
sum (f.sales_amount)total_spending,
min (order_date) first_order,
max(order_date) last_order,
datediff(month, min(order_date), max (order_date)) as lifespan
from gold.fact_sales f

left join gold.dim_customers c
on f.customer_key = c.customer_key

group by c.customer_key)

select 
customer_segment,
count(customer_key) as total_customers
from
(select customer_key,
case when lifespan >= 12 and total_spending > 5000 then 'VIP'
			when lifespan >= 12 and total_spending <= 5000 then 'Regular'
else 'New'
end customer_segment
from customer_spending) t
group by customer_segment
order by total_customers