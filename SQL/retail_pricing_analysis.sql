select * from superstore;

--How do different discount levels affect sales, total profit, profit margin, and loss-making order lines?--
select
    discount * 100 as discount_pct,
    count(*) as total_orders,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    round(sum(profit) / nullif(sum(sales), 0) * 100, 2) as profit_margin_pct,
    round(avg(discount) * 100, 2) as avg_discount_pct,
    count(*) filter (where profit < 0) as loss_lines,
    round(count(*) filter (where profit < 0) * 100.0 / count(*), 2) as loss_line_pct
from superstore
group by discount
order by discount;

 --How do discount levels affect profitability across Furniture, Office Supplies, and Technology?--
select
    category,
    discount * 100 as discount_pct,
    count(*) as total_orders,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    round(sum(profit) / nullif(sum(sales), 0) * 100, 2) as profit_margin_pct,
    count(*) filter (where profit < 0) as loss_lines,
    round(count(*) filter (where profit < 0) * 100.0 / count(*), 2) as loss_line_pct
from superstore
group by category, discount
order by category, discount;

--Which product subcategories become unprofitable at different discount levels?--
select
    category,
    sub_category,
    discount * 100 as discount_pct,
    count(*) as total_orders,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    round(sum(profit) / nullif(sum(sales), 0) * 100, 2) as profit_margin_pct,
    count(*) filter (where profit < 0) as loss_lines,
    round(count(*) filter (where profit < 0) * 100.0 / count(*), 2) as loss_line_pct
from superstore
group by category, sub_category, discount
order by category, sub_category, discount;

-- Which individual products are generating an overall negative profit for the business?--
select
    product_id,
    product_name,
    category,
    sub_category,
    count(*) as total_orders,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    round(sum(profit) / nullif(sum(sales), 0) * 100, 2) as profit_margin_pct
from superstore
group by product_id, product_name, category, sub_category
having sum(profit) < 0
order by total_profit;
--Which specific products are experiencing the highest losses at particular discount levels?--
select
    product_id,
    product_name,
    category,
    sub_category,
    discount * 100 as discount_pct,
    count(*) as total_orders,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    count(*) filter (where profit < 0) as loss_lines,
    round(count(*) filter (where profit < 0) * 100.0 / count(*), 2) as loss_line_pct
from superstore
group by product_id, product_name, category, sub_category, discount
having sum(profit) < 0
order by total_profit
limit 20;
-- How do sales, orders, profit, and profit margin change month by month?--
select
    date_trunc('month', order_date)::date as order_month,
    count(distinct order_id) as total_orders,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    round(sum(profit) / nullif(sum(sales), 0) * 100, 2) as profit_margin_pct
from superstore
group by date_trunc('month', order_date)
order by order_month;

--Which customer segment contributes the most sales and profit, and which segment has the strongest profitability?--
select
    segment,
    count(distinct order_id) as total_orders,
    count(*) as total_lines,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    round(sum(profit) / nullif(sum(sales), 0) * 100, 2) as profit_margin_pct,
    round(avg(discount) * 100, 2) as avg_discount_pct,
    count(*) filter (where profit < 0) as loss_lines,
    round(count(*) filter (where profit < 0) * 100.0 / count(*), 2) as loss_line_pct
from superstore
group by segment
order by total_profit desc;

--How does each customer segment perform at different discount levels in terms of profitability?--
select
    segment,
    discount * 100 as discount_pct,
    count(*) as total_orders,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    round(sum(profit) / nullif(sum(sales), 0) * 100, 2) as profit_margin_pct,
    count(*) filter (where profit < 0) as loss_lines,
    round(count(*) filter (where profit < 0) * 100.0 / count(*), 2) as loss_line_pct
from superstore
group by segment, discount
order by segment, discount;

--Which regions generate the highest profit, and which regions have profitability problems?--
select
    region,
    count(distinct order_id) as total_orders,
    count(*) as total_lines,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    round(sum(profit) / nullif(sum(sales), 0) * 100, 2) as profit_margin_pct,
    round(avg(discount) * 100, 2) as avg_discount_pct,
    count(*) filter (where profit < 0) as loss_lines,
    round(count(*) filter (where profit < 0) * 100.0 / count(*), 2) as loss_line_pct
from superstore
group by region
order by total_profit desc;

--ADVANCED ANALYSIS --
--Which products contribute the most to the business's total positive profit, and how many products account for approximately 80% of the total positive profit?
with product_profit as (
    select
        product_id,
        product_name,
        sum(sales) as total_sales,
        sum(profit) as total_profit
    from superstore
    group by product_id, product_name
),
positive_products as (
    select *
    from product_profit
    where total_profit > 0
),
ranked_products as (
    select
        product_id,
        product_name,
        round(total_sales::numeric, 2) as total_sales,
        round(total_profit::numeric, 2) as total_profit,
        round(
            total_profit * 100.0
            / sum(total_profit) over (),
            2
        ) as profit_contribution_pct,
        dense_rank() over (
            order by total_profit desc
        ) as profit_rank,
        sum(total_profit) over (
            order by total_profit desc, product_id
            rows between unbounded preceding
            and current row
        ) * 100.0
        / sum(total_profit) over () as cumulative_profit_pct
    from positive_products
)
select
    product_id,
    product_name,
    total_sales,
    total_profit,
    profit_contribution_pct,
    profit_rank,
    round(cumulative_profit_pct::numeric, 2)
        as cumulative_profit_pct
from ranked_products
order by profit_rank, product_id;

--How have the business's sales, profit, and profit margin changed from one year to the next, and are we improving or declining in profitability?
YOY ANALYSIS
with yearly_performance as (
    select
        extract(year from order_date) as order_year,
        round(sum(sales), 2) as total_sales,
        round(sum(profit), 2) as total_profit,
        round(
            sum(profit) / nullif(sum(sales), 0) * 100,
            2
        ) as profit_margin_pct
    from superstore
    group by extract(year from order_date)
),
yearly_comparison as (
    select
        order_year,
        total_sales,
        total_profit,
        profit_margin_pct,
        lag(total_sales) over (order by order_year) as previous_year_sales,
        lag(total_profit) over (order by order_year) as previous_year_profit,
        lag(profit_margin_pct) over (order by order_year) as previous_year_margin
    from yearly_performance
)
select
    order_year,
    total_sales,
    total_profit,
    profit_margin_pct,
    previous_year_sales,
    previous_year_profit,
    previous_year_margin,
    round(
        (total_sales - previous_year_sales)
        / nullif(previous_year_sales, 0) * 100,
        2
    ) as sales_growth_pct,
    round(
        (total_profit - previous_year_profit)
        / nullif(abs(previous_year_profit), 0) * 100,
        2
    ) as profit_growth_pct,
    round(
        profit_margin_pct - previous_year_margin,
        2
    ) as margin_change_percentage_points
from yearly_comparison
order by order_year;

--Are most customer orders profitable, or does the business depend on a smaller number of highly profitable orders to offset loss-making orders?
ORDER LEVEL PROFITABILITY ANALYSIS
with order_profitability as (
    select
        order_id,
        customer_id,
        segment,
        region,
        count(*) as total_products,
        sum(sales) as total_sales,
        sum(profit) as total_profit
    from superstore
    group by
        order_id,
        customer_id,
        segment,
        region
),
order_summary as (
    select
        *,
        case
            when total_profit > 0 then 'profitable'
            when total_profit < 0 then 'loss-making'
            else 'break-even'
        end as order_status
    from order_profitability
)
select
    order_status,
    count(*) as total_orders,
    round(
        count(*) * 100.0 / sum(count(*)) over (),
        2
    ) as order_percentage,
    round(sum(total_sales), 2) as total_sales,
    round(sum(total_profit), 2) as total_profit,
    round(avg(total_profit), 2) as avg_profit_per_order
from order_summary
group by order_status
order by total_orders desc;
--Are different regions generating sufficient profit from the discounts they offer, or are some regions sacrificing too much profit through discounting?
select
    region,
    discount,
    count(distinct order_id) as total_orders,
    count(*) as total_order_lines,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    round(
        sum(profit) / nullif(sum(sales), 0) * 100,
        2
    ) as profit_margin_pct,
    round(avg(discount) * 100, 2) as discount_pct,
    count(*) filter (
        where profit < 0
    ) as loss_making_lines,
    round(
        count(*) filter (where profit < 0) * 100.0
        / count(*),
        2
    ) as loss_line_pct
from superstore
group by
    region,
    discount
order by
    region,
    discount;
--Which customers contribute the most profit, and are there customers generating high sales but low or negative profit?
with customer_profit as (
    select
        customer_id,
        customer_name,
        segment,
        count(distinct order_id) as total_orders,
        sum(sales) as total_sales,
        sum(profit) as total_profit
    from superstore
    group by
        customer_id,
        customer_name,
        segment
),
ranked_customers as (
    select
        *,
        round(
            total_profit * 100.0
            / nullif(sum(total_profit) over (), 0),
            2
        ) as profit_contribution_pct,
        dense_rank() over (
            order by total_profit desc
        ) as profit_rank,
        case
            when total_profit > 0 then 'profitable'
            when total_profit < 0 then 'loss-making'
            else 'break-even'
        end as customer_status
    from customer_profit
)
select
    customer_id,
    customer_name,
    segment,
    total_orders,
    round(total_sales, 2) as total_sales,
    round(total_profit, 2) as total_profit,
    profit_contribution_pct,
    profit_rank,
    customer_status
from ranked_customers
order by total_profit desc;
-- Which combinations of product categories, subcategories, and discount levels generate the highest profits or losses, and where should the business reconsider its discount strategy?
select
    category,
    sub_category,
    discount,
    count(*) as total_order_lines,
    count(distinct order_id) as total_orders,
    round(sum(sales), 2) as total_sales,
    round(sum(profit), 2) as total_profit,
    round(
        sum(profit) / nullif(sum(sales), 0) * 100,
        2
    ) as profit_margin_pct,
    round(
        count(*) filter (where profit < 0) * 100.0
        / count(*),
        2
    ) as loss_line_pct,
    case
        when sum(profit) < 0 then 'loss-making'
        when sum(profit) > 0 then 'profitable'
        else 'break-even'
    end as profitability_status
from superstore
group by
    category,
    sub_category,
    discount
order by
    category,
    sub_category,
    discount;


