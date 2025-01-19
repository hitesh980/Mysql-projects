DROP table actors;
DROP type films;

create type films as(
     film TEXT,
	 votes INTEGER,
	 rating REAL,
	 filmid TEXT
)

create type quality_class as 
    ENUM('star','good','average','bad')


create table actors(
    actorid text,
    actor text,
	current_year INTEGER,
    films films[],
	quality_class quality_class,
	is_active BOOLEAN,
	PRIMARY KEY (actorid,current_year)
);

--cumulative table generation
/*
with years AS (
   select * from generate_series(2002,2002) as year
), actors_first_year AS(
       select actor, 
	   actorid,
	   min(year) as first_year 
	   FROM actor_films 
	   GROUP BY actor,actorid
   
), actors_and_years AS
 
  (select * from 
      actors_first_year
      JOIN years y ON 
	  actors_first_year.first_year <= y.year)-- we used less than symbol so we would get actual min year records otherwise 
select
   ay.actor,
   ay.actorid,
   ay.year,
   ARRAY_REMOVE(
      ARRAY_AGG(
           CASE
		     when af.year is NOT NULL then
			 ROW(
                 af.film,
	             af.year,
	             af.votes,
	             af.rating
                 )::films
			 END)
			OVER(PARTITION BY ay.actorid ORDER BY COALESCE(ay.year,af.year) ),
			NULL
	  
   ) as films,
   case
      when rating > 8 then 'star'
	  when rating >7 then 'good'
	  when rating>6 then 'average'
	  else 'bad'
	END::quality_class AS quality_class
	FROM  actors_and_years as ay 
	LEFT JOIN actor_films  as af
	ON ay.actorid = af.actorid
	AND ay.year = af.year

*/
create table actors(
    actorid text,
    actor text,
	current_year INTEGER,
    films films[],
	quality_class quality_class,
	is_active BOOLEAN,
	PRIMARY KEY (actorid,current_year)
);

with last_year AS(
    select * from actors
	where current_year =2000
), this_year AS (
      select * from actor_films
	  where year = 2001

), this_films_and_rating AS (
     Select actorid ,
	        actor,
			year ,
			ARRAY_AGG(ROW(
                ty.film,
				ty.votes,
				ty.rating,
				ty.filmid)::films) as current_films,
			avg(rating) as average_rating
	 from  this_year as ty GROUP BY actorid,actor,year
)

SELECT
     COALESCE (ly.actorid,ty.actorid) as actorid, --we use one is there when other value is absent
     COALESCE (ly.actor,ty.actor) as actor,
	 COALESCE (ly.current_year + 1,ty.year) as current_year,
	 CASE
	    WHEN ly.current_year IS NULL
		THEN ty.current_films 
		WHEN ty.year is NULL
		THEN ly.films
		ELSE ly.films ||ty.current_films	    
	  END::films[] AS films,
	  CASE 
	     WHEN ty.average_rating is NULL
		 then ly.quality_class
		 ELSE 
		    CASE 
			  
			    when ty.average_rating > 8 then 'star'
	            when ty.average_rating > 7 then 'good'
	            when ty.average_rating>  6 then 'average'
	            else 'bad'
	  END:: quality_class
	 END::quality_class,
	  
	  CASE
	     WHEN 
		   ty IS NULL 
		   then False
		   ELSE True
	  END AS is_active
	 FROM this_films_and_rating AS ty 
	 FULL OUTER JOIN last_year As ly
	 ON ly.actorid = ty.actorid
	 