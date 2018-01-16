-- Codeacademy.com - SQL: Analyzing Business Metrics

-- CHAPTER 1

-- Extract day from date

select date(ordered_at) as day
from orders
order by day
limit 100;

-- Daily Count of orders

select date(ordered_at), count(1)
from orders
group by 1
order by 1;

-- Daily Revenue

select date(ordered_at), round(sum(amount_paid), 2) as daily_revenue
from orders
    join order_items on 
      orders.id = order_items.order_id
-- where name = 'kale-smoothie'
group by 1
order by 1;

-- Sums of orders by products

select name, round(sum(amount_paid), 2)
from order_items
group by name
order by 2 desc;

-- Percent of orders by products

select name, round(sum(amount_paid) /
  (select sum(amount_paid) from order_items) * 100.0, 2) as pct
from order_items
group by 1
order by 2 desc;

-- Grouping with Case Statements

select
  case name
    when 'kale-smoothie'    then 'smoothie'
    when 'banana-smoothie'  then 'smoothie'
    when 'orange-juice'     then 'drink'
    when 'soda'             then 'drink'
    when 'blt'              then 'sandwich'
    when 'grilled-cheese'   then 'sandwich'
    when 'tikka-masala'     then 'dinner'
    when 'chicken-parm'     then 'dinner'
    else 'other'
  end as category, 
  round(1.0 * sum(amount_paid) / 
  (select sum(amount_paid) from order_items) * 100, 2) as pct
from order_items
group by 1
order by 2 desc;

-- Reorder Rates

/* 

We'll define reorder rate as the ratio of the total number of orders to the number of people making those orders. 
A lower ratio means most of the orders are reorders. A higher ratio means more of the orders are first purchases. 

*/

select name, round(1.0 * count(distinct order_id) /
  count(distinct delivered_to), 2) as reorder_rate
from order_items
  join orders on
    orders.id = order_items.order_id
group by 1
order by 2 desc;

/*

Let's generalize what we've learned so far:

Data aggregation is the grouping of data in summary form.
Daily Count is the count of orders in a day.
Daily Revenue Count is the revenue on orders per day.
Product Sum is the total revenue of a product.
Subqueries can be used to perform complicated calculations and create filtered or aggregate tables on the fly.
Reorder Rate is the ratio of the total number of orders to the number of people making orders.

*/

-- CHAPTER 2

-- Daily Revenue

select
  date(created_at),
  round(sum(price), 2)
from purchases
group by 1
order by 1;

-- Daily Revenue 2

/* 

 That query doesn't take refunds into account. We'll update the query to exclude refunds.
Fields like refunded_at will only have data if the transaction was refunded, and otherwise left null.

*/

select
  date(created_at),
  round(sum(price), 2) as daily_rev
from purchases
where refunded_at is not null
group by 1
order by 1;

-- Daily Active Users -- DAU

select
  date(created_at), 
  count(distinct user_id) as dau
from gameplays
group by 1
order by 1;

-- Daily Active Users 2

-- Since Mineblocks is on multiple platforms, we can calculate DAU per-platform.

select
  date(created_at), 
  platform,
  count(distinct user_id) as dau
from gameplays
group by 1, 2
order by 1, 2;

-- Daily Average Revenue Per Purchasing User -- ARPPU

-- This metric shows if the average amount of money spent by purchasers is going up over time.
-- Daily ARPPU is defined as the sum of revenue divided by the number of purchasers per day.

select
  date(created_at),
  round(sum(price) / count(distinct user_id), 2) as arppu
from purchases
where refunded_at is null
group by 1
order by 1;

-- Daily Average Revenue Per User -- ARPU

/*

ARPU measures the average amount of money we're getting across all players, whether or not they've purchased.
ARPPU increases if purchasers are spending more money. 
ARPU increases if more players are choosing to purchase, even if the purchase size stays consistent.

Daily ARPU is defined as revenue divided by the number of players, per-day. 
To get that, we'll need to calculate the daily revenue and daily active users separately, and then join them on their dates.

In the final select statement, daily_revenue.dt represents the date, while daily_revenue.rev / daily_players.players is the daily revenue divided by the number of players that day. In full, it represents how much the company is making per player, per day. 

*/

with daily_revenue as (
  select
    date(created_at) as dt,
    round(sum(price), 2) as rev
  from purchases
  where refunded_at is null
  group by 1
), 
daily_players as (
  select
    date(created_at) as dt,
    count(distinct user_id) as players
  from gameplays
  group by 1
)

select
  daily_revenue.dt,
  daily_revenue.rev / daily_players.players
from daily_revenue
  join daily_players using (dt);
  
 -- 1 Day Retention
 
 /*
 
Retention can be defined many different ways, but we'll stick to the most basic definition. 
For all players on Day N, we'll consider them retained if they came back to play again on Day N+1.
 
Before we can calculate retention we need to get our data formatted in a way where we can determine if a user returned.

Currently the gameplays table is a list of when the user played, and it's not easy to see if any user came back.

By using a self-join, we can make multiple gameplays available on the same row of results. This will enable us to calculate retention.

The power of self-join comes from joining every row to every other row. This makes it possible to compare values from two different rows in the new result set. In our case, we'll compare rows that are one date apart from each user.

1 Day Retention is defined as the number of players who returned the next day divided by the number of original players, per day.

 */

select
  date(g1.created_at) as dt,
  round(100 * count(distinct g2.user_id) /
    count(distinct g1.user_id)) as retention
from gameplays as g1
  left join gameplays as g2 on
    g1.user_id = g2.user_id
    and date(g1.created_at) = date(datetime(g2.created_at, '-1 day'))
group by 1
order by 1
limit 100;

/*

Let's generalize what we've learned so far:

Key Performance Indicators are high level health metrics for a business.
Daily Revenue is the sum of money made per day.
Daily Active Users are the number of unique users seen each day
Daily Average Revenue Per Purchasing User (ARPPU) is the average amount of money spent by purchasers each day.
Daily Average Revenue Per User (ARPU) is the average amount of money across all users.
1 Day Retention is defined as the number of players from Day N who came back to play again on Day N+1.
	
*/


