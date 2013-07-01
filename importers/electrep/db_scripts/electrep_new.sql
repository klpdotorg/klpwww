-- Schema creation script for KLP intermediate DB
-- This DB is for populating EMS DB

-- This code is released under the terms of the GNU GPL v3 
-- and is free software


DROP TYPE IF EXISTS school_category cascade;
CREATE TYPE school_category as enum('Model Primary', 'Anganwadi', 'Akshara Balwadi', 'Independent  Balwadi', 'Lower Primary', 'Upper Primary', 'Secondary');

DROP TYPE IF EXISTS gender cascade;
CREATE TYPE gender as enum('Boy','Girl');

DROP TYPE IF EXISTS school_moi cascade;
CREATE TYPE school_moi as enum('kannada','urdu','tamil','telugu','english','marathi','malayalam', 'hindi', 'konkani', 'sanskrit', 'sindhi', 'other', 'gujarathi', 'not known', 'english and marathi', 'multi lng', 'nepali', 'oriya', 'bengali', 'english and hindi', 'english, telugu and urdu');

DROP TYPE IF EXISTS sex cascade;
CREATE TYPE sex as enum('male','female');

DROP TYPE IF EXISTS statuses cascade;
CREATE TYPE statuses as enum('active','inactive');

DROP TYPE IF EXISTS admin_heirarchy cascade;
CREATE TYPE admin_heirarchy as enum('Centre','State','District','Zone','MP Constituency','MLA Constituency','City Corporation','Ward','Gram Panchayat');

DROP TABLE IF EXISTS "tb_electedrep_master" cascade;
CREATE TABLE "tb_electedrep_master" (
  "id" serial unique, 
  "parent" integer,
  "elec_comm_code" integer,
  "const_ward_name" character varying(300),
  "const_ward_type" admin_heirarchy,
  "neighbours" character varying(100),
  "current_elected_rep" character varying(300),
  "current_elected_party" character varying(300),
  "losing_elected_party" character varying(300),
  "prev_elected_rep" character varying(300),
  "prev_elected_party" character varying(300),
  "entry_year" character varying(12),
  "status" statuses default 'active', 
  PRIMARY KEY ("id")
);

insert into tb_electedrep_master (parent,elec_comm_code,const_ward_name,const_ward_type) values (null,null,'INDIA','Centre');
insert into tb_electedrep_master (parent,elec_comm_code,const_ward_name,const_ward_type) values (1,10,'KARNATAKA','State');
insert into tb_electedrep_master (parent,elec_comm_code,const_ward_name,const_ward_type) values (2,null,'BBMP-Bangalore','City Corporation');
insert into tb_electedrep_master (parent,elec_comm_code,const_ward_name,const_ward_type) values (2,null,'Bangalore','District');
insert into tb_electedrep_master (parent,elec_comm_code,const_ward_name,const_ward_type) values (2,null,'Bangalore Rural','District');


DROP TABLE IF EXISTS "tb_school_electedrep" cascade;
CREATE TABLE "tb_school_electedrep" (
  "sid" integer unique, -- school id
  "ward_id" integer,
  "mla_const_id" integer,
  "mp_const_id" integer,
  "heirarchy" integer,
  PRIMARY KEY  ("sid")
);

DROP TABLE IF EXISTS "tb_school_stu_counts" cascade;
CREATE TABLE "tb_school_stu_counts"(
  "sid" integer,
  "moi" school_moi default 'kannada',
  "cat" school_category,
  "mt" school_moi default 'kannada',
  "sex" gender,
  "numstu" integer
);
