select * from game_details;
 --fact data modeling finding duplicates
-- select game_id , team_id, player_id ,count(1) from game_details group by 1,2,3 having count(1) > 1 limit 100;

with deduped as (

select *, ROW_NUMBER () OVER(partition by game_id, team_id, player_id ) as row_num from game_details
)

select * from deduped where row_num = 1 ;


INSERT INTO fct_game_details
with deduped as (
      
     select g.game_date_est ,
	        g.season,
			g.home_team_id,
			g.visitor_team_id,
	        gd.*,
			ROW_NUMBER () OVER(partition by gd.game_id, team_id, player_id ORDER BY  g.game_date_est) as row_num 
	 from game_details gd JOIN games g ON gd.game_id = g.game_id
	

)

select game_date_est as dim_game_date,
       season AS dim_season,
	   team_id AS dim_team_id ,
	   player_id AS dim_payer_id,
	   player_name AS dim_payer_name,
	   start_position AS dim_start_position,
	   team_id = home_team_id AS dim_is_playing_at_home ,
	   COALESCE(POSITION('DNP' in comment),0) >0 as dim_did_not_play ,
	    COALESCE(POSITION('DND' in comment),0) >0 as dim_did_not_dress,
		 COALESCE(POSITION('NWT' in comment),0) >0 as dim_did_not_with_team,
		 CAST(SPLIT_PART(min,':',1) AS REAL) +
		 CAST(SPLIT_PART(min,':',2) AS REAL)/60 AS m_minutes,
		  fgm AS m_fgm,
		  fga AS m_fga,
		  fg3m AS m_fg3m,
		  fg3a AS m_fg3a,
		  ftm AS m_ftm,
		  oreb AS m_oreb,
		  dreb AS m_dreb,
		  reb AS m_reb,
		  ast AS m_ast,
		  stl AS m_stl,
		  blk AS m_blk,
		  "TO" As turnovers,
		  pf AS m_pf,
		  pts AS m_pts,
		  plus_minus AS m_plus_minus
	   from deduped where row_num = 1;

CREATE TABLE fct_game_details(
    dim_game_date DATE,
	dim_season INTEGER,
	dim_team_id INTEGER,
	dim_player_id INTEGER,
	dim_player_name TEXT,
	dim_start_position TEXT,
	dim_is_playing_at_home BOOLEAN,
	dim_did_not_play BOOLEAN,
	dim_did_not_dress BOOLEAN,
	dim_did_not_team BOOLEAN,
    m_minutes REAL,
	m_fgm INTEGER,
	m_fga INTEGER,
	m_fg3m INTEGER,
	m_fg3a INTEGER,
	m_fta INTEGER,
	m_oreb INTEGER,
	m_dreb INTEGER,
	m_reb INTEGER,
	m_ast INTEGER,
	m_stl INTEGER,
	m_blk INTEGER,
	m_turnovers INTEGER,
	m_pf INTEGER,
	m_pts INTEGER,
	m_plus_minus INTEGER,
	PRIMARY KEY (dim_game_date, dim_team_id, dim_player_id) --the reason why are dim_team_id can player be on same team ,no so its optional
	
)

select t.*, gd.* from fct_game_details gd JOIN teams t ON t.team_id = gd.dim_team_id;

select dim_player_name ,
       dim_is_playing_at_home,
       count(1) AS num_games ,
	   sum(m_pts) AS total_points,
	   COUNT(CASE WHEN dim_did_not_team then 1 END) as bailed_num ,
	   CAST(COUNT(CASE WHEN dim_did_not_team then 1 END) AS REAL) /count(1) AS bailed_percent
	   FROM fct_game_details
GROUP BY 1,2 order by 6 desc;

