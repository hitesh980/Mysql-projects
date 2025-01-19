
create type vertex_type as ENUM(
    'player',
	'team',
	 'game'

);

create TABLE vertices(

identifier TEXT,
type vertex_type,
properties JSON,
PRIMARY KEY (identifier,type)


);

create type edge_type AS
    ENUM ('plays_against','shares_team', 'plays_in','plays_on')


create table edges(
    subject_identifier TEXT,
	subject_type vertex_type,
	object_identifier TEXT,
	object_type vertex_type,
	edge_type edge_type,
	properties JSON,
	PRIMARY KEY (  subject_identifier,
	                subject_type,
					object_identifier,
					object_type,
					 edge_type )
)

