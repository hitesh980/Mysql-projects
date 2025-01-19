

/*
create TABLE array_metrics (
     user_id NUMERIC,
	 month_start DATE,
	 metric_name TEXT,
	 metric_array REAL[],
	 PRIMARY KEY(user_id,month_start,metric_name)
)
*/


INSERT INTO array_metrics
with daily_aggregate AS (
    SELECT user_id,
	       DATE(event_time) AS date,
	       COUNT(1) as num_site_hits
	FROM events
	WHERE DATE(event_time) = DATE('2023-01-02')
	AND user_id is NOT NULL
	GROUP BY user_id, DATE(event_time)
),
  yesterday_array as (
      select * from array_metrics
	  WHERE month_start = DATE('2023-01-01')

  )

select 
   COALESCE(da.user_id,ya.user_id) as user_id,
   COALESCE(ya.month_start,DATE_TRUNC('month',da.date)) as month_start,
    'site_hits' AS metric_name,
	CASE WHEN ya.metric_array IS NOT NULL THEN
	ya.metric_array|| ARRAY[COALESCE(da.num_site_hits,0)]
	 
	WHEN ya.metric_array IS NULL 
	THEN ARRAY_FILL(0,ARRAY[COALESCE (date - DATE(DATE_TRUNC('month',date)),0)]) ||  --7th of january - start of the month which is one we gonna get six zeros 
	ARRAY[COALESCE(da.num_site_hits,0)]
	END

from daily_aggregate da
FULL OUTER JOIN yesterday_array ya ON da.user_id = ya.user_id
ON CONFLICT(user_id,month_start,metric_name)
DO
 UPDATE SET metric_array = EXCLUDED.metric_array;

 select * from array_metrics;

 select cardinality(metric_array) , count(1) from array_metrics
 GROUP BY 1

WITH agg as ( 
     select metric_name ,month_start,ARRAY[
                   SUM(metric_array[1]),
				   SUM(metric_array[2]),
				   SUM(metric_array[3])
                   ]  as summed_array

 FROM array_metrics GROUP BY metric_name,month_start)

select * from agg CROSS JOIN UNNEST(agg.summed_array)
          WITH ORDINALITY AS a ( elem , index)
 