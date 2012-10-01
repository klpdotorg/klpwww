-- Schema creation script for KLP intermediate DB
-- This DB is for populating EMS DB

-- This code is released under the terms of the GNU GPL v3 
-- and is free software
drop table "tb_middaymeal";
create table "tb_middaymeal"
(
	id integer not null,
	schoolname varchar(100),
	dy varchar(2),
	mon varchar(15),
	yr varchar(4),
	indent_onetofive integer,
	indent_sixtoseven integer,
	indent_eight integer,
	indent_ninetoten integer,
	attend_onetofive integer,
	attend_sixtoseven integer,
	attend_eight integer,
	attend_ninetoten integer
);
