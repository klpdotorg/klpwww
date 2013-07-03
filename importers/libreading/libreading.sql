-- Schema creation script for KLP intermediate DB
-- This DB is for populating EMS DB

-- This code is released under the terms of the GNU GPL v3 
-- and is free software

DROP TYPE IF EXISTS sex cascade;
CREATE TYPE sex as enum('boy','girl','err');

drop table "tb_assessment";
create table "tb_assessment"
(
	klpid integer not null,
	schoolname varchar(100),
        studentid varchar(32) not null,
	studentname varchar(100),
        acadyear varchar(12),
        gender sex not null,
        class integer,
        grade varchar(12)
);

drop table "tb_assess_agg";
create table "tb_assess_agg"
(
	sid integer not null,
        acyear varchar(12),
        gender sex not null,
        class integer,
        grade varchar(12),
        stucount integer
);
