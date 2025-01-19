with users as 
(select * from users_cumulated WHERE date = date('2023-01-31')
),

series  AS
 (SELECT * from generate_series(DATE('2023-01-01'),DATE('2023-01-31'),INTERVAL '1 day') as series_date
 ),

 place_holder_ints as (

 select 
   CASE WHEN 
     dates_active @> ARRAY[DATE(series_date)]
	 THEN CAST(POW(2,32-(date -DATE(series_date))) AS BIGINT)
	 ELSE 0
	 END as placeholder_int_value
	 , * from users CROSS JOIN series
--WHERE user_id = '13431269135311700000'


 )

select 
  user_id,
  CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32)),
  BIT_COUNT(CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32))) > 0 AS dim_is_monthly_active,
  BIT_COUNT(CAST('11111110000000000000000000000000' AS BIT(32)) &
            CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32))) > 0 as dim_is_weekly_active,
			-- this is typlical 1 and 1 would give you 1 otherwise 0 for the first week
  BIT_COUNT(CAST('10000000000000000000000000000000' AS BIT(32)) &
            CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32))) > 0 as dim_is_daily_active			
  
  FROM place_holder_ints
  GROUP BY user_id 
    