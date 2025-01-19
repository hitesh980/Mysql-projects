
INSERT INTO vertices
Select 
    game_id AS identifier,
	
	'game'::vertex_type AS type,
	json_build_object(
	   'pts_home', pts_home,
	   'pts_away', pts_away,
	   'winning_team',CASE when home_team_wins = 1 then home_team_id ELSE visitor_team_id END

	) as properties
  from games;

INSERT INTO VERTICES 
WITH players_agg AS (
  select 
    player_id AS identifier,
	max(player_name) AS player_name,
	count(1) as number_of_games,
	sum(pts) as total_points,
	ARRAY_AGG(DISTINCT team_id) AS teams
	


from game_details GROUP BY player_id 
)

select identifier, 'player'::vertex_type,
     json_build_object(
         'player_name',
		 player_name,
		 'number_of_games',
		 number_of_games,
		 'total_points', total_points,
		 'teams',teams
	 )
FROM players_agg


INSERT INTO vertices
with teams_deduped AS (
   SELECT *, ROW_NUMBER() OVER(PARTITION BY team_id ) as row_num
   FROM teams
)
select 
   team_id AS identifier,	  
   'team'::vertex_type AS type,
   json_build_object(
      'abbreviation', abbreviation,
	  'nickname' , nickname,
	  'city', city,
	  'arena', arena,
	  'year_founded', yearfounded
   )
from  teams_deduped where row_num =1


select type,count(1) FROM vertices group by 1;

select * from game_details LIMIT 100;

##fdsfvs

INSERT INTO edges
with deduped AS (
      SELECT *, row_number() over(partition by player_id,game_id) as row_num FROM game_details
),
   filtered AS (
      select * from deduped where row_num = 1
   ),
     aggregated AS(
          
	 
     select 
	        f1.player_id as subject_player_id,
		
			f2.player_id as object_player_id,	   
	
		 CASE when f1.team_abbreviation = f2.team_abbreviation
		    THEN 'shares_team' :: edge_type
			ELSE 'plays_against'::edge_type
			END as edge_type,
			max(f1.player_name) as subject_player_name,
			max(f2.player_name) as object_player_name,
			COUNT(1) AS num_games,
			SUM(f1.pts) AS subject_points,
			SUM(f2.pts) AS object_points
			
	 from filtered f1 
	        JOIN filtered f2
		    ON f1.game_id = f2.game_id
		    AND f1.player_name <> f2.player_name
		WHERE f1.player_id > f2.player_id
		GROUP BY 
		    f1.player_id,

			f2.player_id,
		
		    CASE when f1.team_abbreviation = f2.team_abbreviation
		    THEN 'shares_team' :: edge_type
			ELSE 'plays_against'::edge_type
			END 
			 )
	 select 
	          subject_player_id AS subject_identifier,
             'player'::vertex_type as subject_type,
              object_player_id AS object_identifier,
             'player'::vertex_type AS object_type,
             edge_type AS edge_type,
			 json_build_object (
                 'num_games', num_games,
				  'subject_points', subject_points,
				  'object_points',object_points
			 )
	 from aggregated 
	/* this query will generate all the possible combinations
	in this query there two combination(edges) so you might just need one
	*/
		    
		  
   
INSERT INTO edges
with deduped AS (
  SELECT *, row_number() over(partition by player_id,game_id) as row_num FROM game_details
)
SELECT 
   player_id AS subject_identifier,
   'player'::vertex_type as subject_type,
   game_id AS object_identifier,
   'game'::vertex_type AS object_type,
   'plays_in'::edge_type AS edge_type,
   json_build_object(
       'start_position', start_position,
	   'pts', pts,
	   'team_id', team_id,
	    'team_abbreviation', team_abbreviation
   ) as properties
 FROM deduped WHERE row_num = 1;
   
select player_id, game_id ,count(1) FROM game_details GROUP BY 1,2;
##checking duplicates


select * FROM vertices v JOIN edges e ON e.subject_identifier = v.identifier
AND e.subject_type = v.type;
/* this query gives duplicates because the properties coulumn in the edges was treated like string */

select v.properties->>'player_name',
       MAX(e.properties->>'pts')
	   FROM vertices v JOIN edges e ON e.subject_identifier = v.identifier
AND e.subject_type = v.type GROUP BY 1 ORDER BY 2 desc;


select v.properties->>'player_name',
v2.properties->>'player_name',
coalesce(cast(v.properties->>'total_points' as real) /
cast(v.properties->>'number_of_games' as real), 0) career_points_x_games ,
coalesce(cast(e.properties->>'subject_points' as real) /
cast(e.properties->>'num_games' as real), 0) points_x_games ,
e.properties->>'subject_points' subject_points,
e.properties->>'num_games' num_games,
e.edge_type
from vertices v join edges e
on e.subject_identifier = v.identifier
and e.subject_type = v.type
join vertices v2 on 
v2.identifier = e.object_identifier
and e.subject_type = v2.type
where e.object_type = 'player'::vertex_type;

