-- Schema creation script for KLP intermediate DB
-- This DB is for populating EMS DB

-- This code is released under the terms of the GNU GPL v3 
-- and is free software

DROP TABLE tb_ai_questions;
CREATE TABLE tb_ai_questions (
  id integer,
  question varchar(200)
);

DROP TABLE tb_ai_answers;
CREATE TABLE tb_ai_answers (
  sid integer,
  qid integer,
  ans integer,
  year varchar(100) 
);

DROP TABLE tb_ang_info;
CREATE TABLE tb_ang_info (
   sid integer primary key,
   dist varchar(32),
   proj varchar(32),
   circ varchar(100),
   name varchar(100)
);

DROP TABLE IF EXISTS "tb_ang_infra_agg";
CREATE TABLE "tb_ang_infra_agg" (
  "sid" integer,
  "ai_metric" varchar(30),
  "perc_score" numeric(5),
  "ai_group" varchar(30),
  "year" varchar(100)
);

drop table tb_display_master;
create table tb_display_master(
   key varchar(32),
   value varchar(200)
);

insert into tb_display_master values ('progress',' Maintains Progress Records for Children');
insert into tb_display_master values ('blackboard',' Has Blackboards for Teaching');
insert into tb_display_master values ('floor',' Has Flooring Intact');
insert into tb_display_master values ('roof',' Has Roofs Intact');
insert into tb_display_master values ('walls',' Has Walls Intact');
insert into tb_display_master values ('building',' Is in a Designated Building by DWCD');
insert into tb_display_master values ('drinking_water',' Has Drinking Water Facilities');
insert into tb_display_master values ('meal_served',' Has Clean and Timely Meals');
insert into tb_display_master values ('waste_basket',' Has Waste Baskets');
insert into tb_display_master values ('water_supply',' Has Water Supply');
insert into tb_display_master values ('toilet_roof',' Has Shelters for Toilets');
insert into tb_display_master values ('toilet',' Has Toilets');
insert into tb_display_master values ('handwash',' Has Handwash Facilities');
insert into tb_display_master values ('space',' Has Spacious Classrooms and Play Isas');
insert into tb_display_master values ('akshara_kits',' Uses Akshara Foundation Teaching Kits');
insert into tb_display_master values ('bvs',' Has Functional Bal Vikas Samithis');
insert into tb_display_master values ('toilet_usable',' Has Usable Toilets');
