/*
select * from events;
select max(event_time), min(event_time) from events;


DROP table users_cumulated;

create table users_cumulated(
       user_id TEXT,
	   --the list of dates in the past where the user was active
	   dates_active DATE[],
	   --the current date for the user
	   date DATE,
	   PRIMARY KEY (user_id, date)
)
*/
INSERT INTO users_cumulated
with yesterday as (

   select *
   FROM users_cumulated
   WHERE date = DATE('2023-01-30')
   

),
 today AS(

   select 
     CAST (user_id AS TEXT) as user_id,
	 DATE(CAST(event_time AS TIMESTAMP)) as date_active
	 
   FROM events
   WHERE DATE(CAST(event_time as TIMESTAMP)) = DATE('2023-01-31')
   AND user_id is not NULL
   GROUP BY user_id , DATE(CAST(event_time as TIMESTAMP))

 )

 select  
   COALESCE(t.user_id,y.user_id) AS user_id,
   CASE 
       WHEN y.dates_active is NULL
	   THEN ARRAY[t.date_active]
	   WHEN t.date_active IS NULL THEN y.dates_active
	   ELSE ARRAY[t.date_active] || y.dates_active
	   END
	   as dates_active,
   COALESCE(t.date_active, y.date + INTERVAL '1 day' ) AS date
   from today t FULL OUTER JOIN yesterday y 
   ON t.user_id = y.user_id


select * from users_cumulated WHERE date = date('2023-01-31');

select * from generate_series(DATE('2023-01-01'),DATE('2023-01-31'),INTERVAL '1 day')

   


