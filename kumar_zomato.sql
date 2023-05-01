CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);
select * from goldusers_signup;
select * from sales;
#what is the total amount spent on each product by customers
select s.userid , sum(p.price) as total_spent from sales s INNer join product p ON s.product_id = p.product_id GROUP BY s.userid;

#how many days each customer has visited zomato
select userid ,count(distinct created_date) from sales group by userid;

#what is the first product purchased by customer
select userid, product_id from
(select userid ,created_date,product_id, dense_rank() over(partition by userid order by created_date) as rk from sales)s;

#what is the most purchased item on the menu and how many times it was purchased all customers
select userid,count(product_id) from sales where product_id =(select product_id from sales group by 1 order by  count(product_id) desc limit  1)
group by userid;

#what is the most popular item for customers
select userid,product_id, rank() over(partition by userid order by count(product_id) desc) from sales group by 1,2;

use practice;
#which item was purchsed first after they became a gold  member
select * from goldusers_signup;
select * from users;
select * from product;
select * from sales;
select c.*,rank() over(partition by userid order by created_date) from (select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s inner join goldusers_signup g On s.userid = g.userid where
s.created_date >= g.gold_signup_date order by g.gold_signup_date)c;

#which item was purchased just before customer became a member

select userid,product_name,created_date from(select a.userid, a.product_id ,a.created_date,b.product_name,rank() over(partition by a.userid order by created_date asc) as r 
from sales a join product b on a.product_id =b.product_id )t
where r = 1;

#which item was purchased just before customer becoming a gold member
select * from (select c.*,rank() over(partition by userid order by created_date desc) as r  from 
(select s.userid,s.created_date,s.product_id,g.gold_signup_date from sales s inner join goldusers_signup g On s.userid = g.userid where
s.created_date <= g.gold_signup_date order by g.gold_signup_date)c)t where r= 1 ;

#what is the total order and amount spent on each customer before they becoming a member
select s.userid,s.created_date,s.product_id,g.gold_signup_date,count(s.product_id),sum(p.price) from sales s inner join goldusers_signup g On s.userid = g.userid
join product p On s.product_id = p.product_id where
s.created_date <= g.gold_signup_date
group by 1
 order by g.gold_signup_date;
 use practice;
 
 mysql -u root -p
mysql > SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

sql_mode = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION";

SET GLOBAL sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

#each product generates purchasing points 5rs = 2 zomato_points as cashbacks
#p1 5rs = 1 zomato point
#p2 10rs = 5 zomato point or 2rs = 1 zomato point
#p3 5rs = 1 zomato point
#calcuate the metric
with cte as (select s.userid ,p.product_id,sum(p.price) as s from sales s join product p on s.product_id =p.product_id 
group by 1,2 order by 1)
select *,
case when product_id = 1 then s/5
when product_id = 2 then s*5/10
when product_id = 3 then s/5
else NULL end as zomato_points
from cte;

#alternative total_points collected and zomato
with cte as (select s.userid ,p.product_id,sum(p.price) as s from sales s join product p on s.product_id =p.product_id 
group by 1,2 order by 1)
select userid,sum(points) as points_collected ,sum(round(s/points,0)) as zomato_points  from
(select *,case when product_id=1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from cte)t
group by userid

#calculating zomato points
with cte as (select s.userid ,p.product_id,sum(p.price) as s from sales s join product p on s.product_id =p.product_id 
group by 1,2 order by 1)
select *,zomato_points*2.5 as cashback from (select userid,sum(points) as points_collected ,sum(round(s/points,0)) as zomato_points  from
(select *,case when product_id=1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points from cte)t
group by userid)r