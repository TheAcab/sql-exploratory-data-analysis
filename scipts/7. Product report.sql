--1. Gather essenatial columns
--2. Segment by revenue (high, mid and low performers)
--3. Aggregate:	total orders, total sales, total qty sold, total customer (unique), lifespan
--4. Calculate valuables kpi's: recency (months since last sales), avg order revenue(AOR), avg monthly revenue

--1. Gather essenatial columns
create view  gold.report_products as

with product_query_base as (
select 
f.order_number,
f.order_date,
f.customer_key,
f.sales_amount,
f.quantity,
p.PRODUCT_key,
p.product_name,
p.category,
p.subcategory,
p.cost
from gold.fact_sales f

left join gold.dim_products p
on p.PRODUCT_key = f.product_key

where order_date is not null ),

----------------------------------------------------
--Aggregate:	total orders, total sales, total qty sold, total customer (unique), lifespan--
product_aggregations as(
select 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	datediff(month, min (order_date), max(order_date)) as lifespan,
	max (order_date) as last_sales_date,
	count(distinct order_number) as total_orders,
	count(distinct customer_key) as total_customers,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	round(avg(cast(sales_amount as float) / nullif(quantity, 0)),1) as avg_selling_price
	from product_query_base

	group by
	product_key,
	product_name,
	category,
	subcategory,
	cost)

	select 
	PRODUCT_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sales_date,
	datediff(month, last_sales_date, GETDATE()) as recency_in_months,
	CASe	
		when total_sales > 50000 then 'High Performer'
		when total_sales>= 10000 then 'Mid Range'
		else 'Low performer'
	end as product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
		case 
			when total_customers = 0 then 0 
			else total_sales / total_orders
		end as avg_order_revenue,

		case 
			when lifespan = 0 then total_sales
			else total_sales/ lifespan
		end as avg_monthly_revenue
	from product_aggregations
	
