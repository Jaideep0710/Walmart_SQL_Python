use walmart_db;

-- 
select * from walmart;
------ 
select count(*) from walmart;

----
select 
	count(distinct branch) as total_branch
from walmart;

----
select
	branch,
	count(*) as Each_total
from walmart
group by branch;

----
select Max(quantity) as highest_quantity from walmart;


-- Business Problems
-- Q1: What are the different payment methods, and how many transactions and items were sold with each method?
select 
	payment_method,
    count(*) as total_transactions,
    sum(quantity) as no_of_qty_sold
from walmart
group by payment_method
order by total_transactions desc;

-- Q2: Which category received the highest average rating in each branch?

with cte as(
select 
	branch,
	category,
    round(avg(rating),2) as avg_rating,
    rank() over(partition by branch order by avg(rating) desc) as rn
from walmart
group by category,branch)
select 
	branch,
	category,
	avg_rating
from cte 
where rn=1;


-- Q3: What is the busiest day of the week for each branch based on transaction volume?
with cte as(
select 	
	branch,
	date_format(str_to_date(date,'%d/%m/%y'),'%W') as day_name,
    count(*) as  no_transactions,
    row_number() over(partition by branch order by  count(*) desc) as rn
from walmart
group by branch,day_name
order by branch,no_transactions desc)
select 
	branch,
    day_name,
    no_transactions
from cte 
where rn=1;

-- Q4: How many items were sold through each payment method?
select 
	payment_method,
    sum(quantity) as no_of_qty_sold
from walmart
group by payment_method
order by no_of_qty_sold desc;


-- Q5: What are the average, minimum, and maximum ratings for each category in each city?
select
	city,
	category,
    round(avg(rating),2) as avg_rating,
    min(rating) as min_rating,
    max(rating) as max_rating
from walmart
group by city,category
order by avg_rating desc;


-- Q6: What is the total profit for each category, ranked from highest to lowest?
select 
	category,
    round(sum(total),2) as total_Revenue,
    round(sum(total * profit_margin),2) as total_Profit
from walmart
group by category
order by total_revenue desc;

-- Q7: What is the most frequently used payment method in each branch?
with cte as(
	select
		branch,
		payment_method,
		count(*) as total_method,
		row_number() over(partition by branch order by count(*) desc) as rn
	from walmart
	group by branch,payment_method)
select 
	branch,
    payment_method,
    total_method
from cte 
where rn=1
order by total_method desc;

-- Q8: How many transactions occur in each shift (Morning, Afternoon, Evening)
-- across branches?

select 
	branch,
	case	
		when hour(time) <12  then 'Morning'
        when hour(time) between  12  and 17 then 'Afternoon'
        else 'Evening' end  as day_time,
        count(*) as total
from walmart
group by day_time,branch
order by branch,total desc;

-- Q9: Which 5 branches experienced the largest decrease in revenue compared to
-- the previous year?
with revenue_2022 as
(
	select 
		branch,
		sum(total) as revenue
	from walmart
    where date_format(str_to_date(date,'%d/%m/%y'),'%Y') = 2022
	group by branch
),
revenue_2023 as(
select 
		branch,
		sum(total) as revenue
	from walmart
    where date_format(str_to_date(date,'%d/%m/%y'),'%Y') = 2023
	group by branch)
select 
	r_22.branch,
	r_22.revenue as Year_2022,
    r_23.revenue as Year_2023,
   round( (r_22.revenue - r_23.revenue) / r_22.revenue  *  100,2) as rev_ration
from revenue_2022 r_22
join revenue_2023 r_23
ON r_22.branch=r_23.branch
where r_22.revenue > r_23.revenue
order by rev_ration desc
limit 5;

-- Q10: Find categories where profit_margin is low despite high unit_price.
select 
	category,
	 round(avg(profit_margin),2) as avg_profit_margin,
     round(avg(unit_price),2) as avg_unit_price
from walmart
group by category
order by avg_profit_margin asc, avg_unit_price desc;

-- Q11: Analyze whether buying more items relates to better or worse rating.
select 
	quantity,
    round(avg(rating),2) as avg_rating
from walmart
group by quantity
order by quantity;

-- Q12: Question: Average Spend per Invoice per Branch
SELECT 
    branch,
    round(sum(total) / count(DISTINCT invoice_id), 2) AS avg_spend_per_invoice
from walmart
group by branch;

-- Q13: Identify low-performing categories (low sales & low rating).
select 
	category,
    round(sum(total),2) as total_sales,
    round(avg(rating),2) as avg_rating
from walmart
group by category
order by total_sales asc ,avg_rating asc;

-- Q14:  Top 3 hours with highest revenue by branch.
with hourly_sales as(
select 
	branch,
	hour(time) as hour_of_day,
    round(sum(total),2) as total_sales
	from walmart
	group by branch,hour(time)),
ranked_sales as(
	select *,
		row_number() over(partition by branch order by total_sales) as rn
	from hourly_sales)
select 
    branch,
    hour_of_day,
    total_sales
from ranked_sales
where rn <= 3
order by  branch, total_sales desc;
    
-- Q15:Which day of week gets the highest average profit margin?.
select 
    dayname(date) AS day_of_week,
    ROUND(AVG(profit_margin), 2) AS avg_profit_margin
from walmart
group by DAYNAME(date)
order by avg_profit_margin desc
LIMIT 1;

-- Q16: Compare weekend vs weekday sales pattern
-- Use DAYNAME(date) or WEEKDAY(date)
select
    CASE 
        WHEN WEEKDAY(STR_TO_DATE(date, '%d/%m/%y')) < 5 then 'Weekday'
        else 'Weekend'
    END AS day_type,
    round(SUM(total), 2) AS total_sales,
    round(AVG(total), 2) AS avg_sales,
    count(*) AS total_transactions
from walmart
group by day_type;
