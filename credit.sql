
SELECT * FROM credit;
#write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with cte as  (select city, amount,sum(amount) as amountspent_city_wise ,dense_rank() over(order by sum(amount) desc) as ranks from credits group by 1),

 cte2 as (select sum(amount) as tota_amount from credits)

select c.city, round(c.amountspent_city_wise/c2.tota_amount *100,2)  as percentage from cte c join cte2 c2 ON 1=1;



#setting up dateformat
with cte as (select DATE_FORMAT(date, '%d%m%y') as date from credits)
select distinct(year(date)) from cte;


update credits
set date =  DATE_FORMAT(date, '%d%m%y') ;
SET SQL_SAFE_UPDATES = 0;

update credits
set `card type` = card_type;

select distinct(year(date)) from credits;
##write a query to print highest spend month and amount spent in that month for each card type
with cte as (SELEct year(date) as year ,month(date) as month ,`card type`,sum(amount) as amount from credits group by 1,2,3 order by 1) ,

cte2 as (select * , dense_rank() over(partition by `card type` order by amount) as r from cte)

select year,month,`card type`,amount from cte2 where r = 1;

# write a query to print the transaction details(all columns from the table) for each card type when
#it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as (select *,`card type` as card, sum(amount) over(partition by `card type` order by date) as cumulative_sum from credits),

 cte2 as (select * , dense_rank() over(partition by card order by cumulative_sum ) as ranks from cte where cumulative_sum>=1000000 )
 
 select * from cte2 where ranks =1;
 
 ##write a query to find city which had lowest percentage spend for gold card type
 with cte as (select city , `card type` as card, amount from credits where `card type` in ('gold') group by 1),
 
 cte2 as (select city, sum(amount) as total_amount from credits  where `card type` in ('gold') group by city)
 
 select a.*,b.total_amount,min(a.amount/b.total_amount *100) as percentage from cte a join cte2 b on a.city =b.city ;
 
 ## write a query to print 3 columns: city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
 
with cte as (select city,`exp type`,sum(amount) as total_amount from credits group by 1,2),

cte2 as (select  city,max(total_amount) as highest_expense_spent, min(total_amount) as lowest_exp_spent from cte group by 1 )

select c.city, max(case when highest_expense_spent = total_amount then `exp type` end) as highest_expense_type,
max(case when lowest_exp_spent = total_amount then `exp type` end) as lowest_exp_spent from cte c join  cte2 c2 on c.city =c2.city
group by 1;

##write a query to find percentage contribution of spends by females for each expense type
with cte as (select `exp type`,sum(amount) as amt_spent from credits where gender in ('f') group by 1),

cte2 as (select `exp type`,sum(amount) as total_amt from credits group by 1)

 select a.`exp type`,a.amt_spent/b.total_amt *100  as total_percentage from cte a join cte2 b on a.`exp type` = b.`exp type` ;
 
 ##which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (SELEct year(date) as year ,month(date) as month ,`exp type`,`card type`,sum(amount) as amount from credits group by 1,2,3,4),

cte1 as (select *,lag(amount) OVER (PARTITION BY `card type`, `exp type` ORDER BY year,month) as previous_amount from cte)

select `exp type`,`card type`,amount,(amount -previous_amount)/previous_amount *100 as growth from cte1 where year =2014 and month =1 order by 4 desc;


##during weekends which city has highest total spend to total no of transcations ratio 
select city,sum(amount) as amount,count(*) as total_orders, sum(amount)/count(*) as ratio from credits 
where date_format(date, '%w') in (5,6) group by 1;

 ##which city took least number of days to reach its 500th transaction after first transaction in that city
 with cte as (select city,min(date) as min_date ,max(date) as max_date ,count(*) as trans_count from credits group by 1)
 
 ,cte2 as (select * from cte where trans_count>=500)
 
 ,cte3 as (select *, row_number() over(partition by city order by date) as rn from credits
 where city in (select city from cte2)),
 
 cte4 as (select c2.city,c2.min_date,c2.max_date ,c2.trans_count,c3.date from cte2 c2 join cte3 on c2.city=c3.city
 where c3.rn =500)
 
 select city,nin_date,max_date,date,datediff(day,min_date,max_date) as days_to_reach_500 from cte4 order by 5;
 