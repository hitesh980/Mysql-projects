DROP TABLE players_scd;
CREATE TABLE players_scd (
      player_name TEXT,
	  scorer_class scoring_class,
	  is_active BOOLEAN,
	  start_season INTEGER,
	  end_season INTEGER,
	  current_season INTEGER,
	  PRIMARY KEY ( player_name,start_season)


);
select * from  players_scd;
select player_name, scorer_class,is_active from players where current_season =1995;


INSERT INTO players_scd
WITH with_previous AS (
select player_name ,
current_season,
scorer_class,
is_active,
LAG(scorer_class,1) over(partition by player_name ORDER BY current_season) 
       AS previous_scoring_class,
LAG(is_active,1) over(partition by player_name ORDER BY current_season) 
       AS previous_in_active
from players WHERE current_season <= 2021 ),

with_indicators AS(

select *, 
     CASE WHEN  scorer_class<> previous_scoring_class THEN 1 
	      WHEN is_active<> previous_in_active THEN 1
	      else 0 END AS  change_indicator
FROM with_previous),

with_streaks AS(

select * , SUM(change_indicator) 
OVER (partition BY player_name ORDER BY current_season)
            AS streak_indentifier
FROM with_indicators 
)

SELECT player_name , 
       scorer_class,
	   is_active,
	   MIN(current_season) as start_season,
	   MAX(current_season) as end_season,
	   2021 AS current_season
	 FROM with_streaks
	GROUP BY player_name ,streak_indentifier ,is_active,scorer_class
	ORDER BY player_name ,streak_indentifier;

select * from players_scd;
CREATE TYPE scd_type AS (
                 scorer_class scoring_class,
				 is_active boolean,
				 start_season INTEGER,
				 end_season INTEGER
                     )
					 
WITH last_season_scd AS (
   SELECT * from players_scd
   WHERE current_season = 2021
   AND end_season = 2021

), 
   historical_scd AS(
      SELECT 
	     player_name,
		   scorer_class,
		   is_active,
		   start_season,
		   end_season
	  
	  
	  from players_scd
      WHERE current_season = 2021
      AND end_season < 2021

   ),

   this_season_data AS(
       SELECT * from players
       WHERE current_season = 2022
),

unchanged_records AS( 
       select
	      ts.player_name,
		  ts.scorer_class,
		  ts.is_active,
		  ls.start_season,
		  ts.current_season as end_season		   
       from this_season_data ts 
       JOIN  last_season_scd ls
	   ON ls.player_name = ts.player_name
	   WHERE ts.scorer_class = ls.scorer_class
	   AND ts.is_active = ls.is_active

),
      changed_records AS(
            select
	      ts.player_name,
		  UNNEST (ARRAY [
		      ROW(
			       ls.scorer_class,
				   ls.is_active,
				   ls.start_season,
				   ls.end_season 
			  )::scd_type,
			  ROW(
			       ts.scorer_class,
				   ts.is_active,
				   ts.current_season,
				   ts.current_season
			  )::scd_type
		  ]) as records
       from this_season_data ts 
       JOIN  last_season_scd ls
	   ON ls.player_name = ts.player_name
	   WHERE (ts.scorer_class <> ls.scorer_class
	   OR ts.is_active <> ls.is_active)
	   
	  ),
       unnested_changed_records AS (

	   SELECT player_name,
	      (records::scd_type).scorer_class,
		  (records::scd_type).is_active,
		  (records::scd_type).start_season,
		  (records::scd_type).end_season

		  FROM changed_records

	   ),

	   new_records AS(
          SELECT 
		      ts.player_name,
			    ts.scorer_class,
				ts.is_active,
				ts.current_season AS start_season,
				ts.current_season AS end_season
		  from this_season_data ts
		  LEFT JOIN last_season_scd ls
		  ON ts.player_name = ls.player_name
		  WHERE ls.player_name IS NULL

	   )
SELECT * from historical_scd

UNION ALL

SELECT * from unchanged_records

UNION ALL

select * from unnested_changed_records

UNION ALL

select * from new_records