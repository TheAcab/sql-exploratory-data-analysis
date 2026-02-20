

--Customer report
----------------------------
--Purpose"
	-- this report consolidates key customer metrics and behaviours

--Highlights:
	--1. Gathers essential fields such as names, ages, and transactions details
	--2. Segments customer into categories (VIP, Regular, New) and age groups.
	--3. Aggregates customer level metrics:
		--total sales
		--total orders
		--total qty purchased
		--lifespan (in months)
	--4. Calculates valuable KPIs:
		--recency (months since last order)
		--average order value
		--average monthly spend

	--retrive core columns


	create view gold.report_customers as



	with base_query as (																						--4.
	-- 1) Base query: retrieves core columns from tables
select																													--1.
	f.order_number,																								--3
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT( c.first_name, ' ' , c.last_name) as customer_name,
	c.birthdate,
	DATEDIFF(year, c.birthdate, GETDATE()) age											--3.1
	from gold.fact_sales f	

	left join gold.dim_customers c																		--2.
	on c.customer_key  = f.customer_key														--2.1

	where order_date is not null)

	,customer_aggregation as(
	--2) Customer aggregations: Summarizes key metrics at customer level
	select																												--5
	customer_key,
	customer_number,
	customer_name,
	age,
	count(distinct order_number) as total_orders,
	sum(sales_amount) as total_sales,
	sum (quantity) as total_quantity,
	count(distinct product_key) as total_products,
	max(order_date) as last_order_date,
	DATEDIFF(MONTH, min(order_date), max(order_date)) as lifespan


	from base_query
	group by																											--6
		customer_key,
		customer_number,
		customer_name,
		age)

	select
		customer_key,
		customer_number,
		customer_name,
		age,
		case 
			when age < 20 then 'Under20'
			when age between 20 and 29 then '20-29'
			when age between 30 and 39 then '30-39'
			when age between 40 and 49 then '40-49'
			else '50 and above'
		end as age_group,
		case
			when lifespan > = 12 and total_sales > 5000 then 'VIP'
			when lifespan > = 12 and total_sales < = 5000 then 'Regular'
			else 'New'
		end as customer_segment,
		last_order_date,
		DATEDIFF (MONTH, last_order_date, getdate()) as recency,
		total_orders,
		total_sales,
		total_quantity,
		 lifespan,
-- calculate average order value (AV0)
case when total_sales = 0 then 0		--use this formula to avoid deviding by zero and retrieve incorrect results
	else total_sales / total_orders
end as avg_order_value,

--calculate avg monthly spend
case when lifespan = 0 then total_sales
	else total_sales / lifespan
end as avg_monthly_spend
		from  customer_aggregation;
