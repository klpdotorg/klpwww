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

CREATE OR REPLACE VIEW vw_school_chart_agg as
       select * from dblink('host=localhost dbname=klpwww0 user=klp password=1q2w3e4r', 'select * from tb_school_chart_agg')
       as t1 (
  sid integer,
  assid integer,
  clid integer,
  sex sex,
  mt school_moi,
  aggtext varchar(100),
  aggval numeric(6,2),
  aggmax numeric(6,2)
);

CREATE OR REPLACE VIEW vw_electoral_coord as
       select * from dblink('host=localhost dbname=klp-coord user=klp password=1q2w3e4r', 'select * from electoral_coord')
       as t1 (id_bndry integer,
              type varchar(20),
              coord geometry);

CREATE OR REPLACE VIEW vw_dise_facility as
select * from dblink('host=localhost dbname=dise_blore user=klp password=1q2w3e4r', 'select * from tb_dise_facility')
as t1 (
  dise_id character varying(32),
  building_status integer,
  classroom_count integer,
  classroom_good integer,
  classroom_major_repair integer,
  classroom_minor_repair integer,
  otherrooms_good integer,
  otherrooms_major_repair integer,
  otherrooms_minor_repair integer,
  toilet_tommon integer,
  toilet_boys integer,
  toilet_girls integer,
  kitchen_devices_grant integer,
  status_of_mdm integer,
  computer_lab integer,
  room_for_hm integer,
  electricity integer,
  boundary_wall integer,
  library integer,
  playground integer,
  blackboard integer,
  books_in_library integer,
  drinking_water integer,
  medical_checkup integer,
  ramps integer,
  no_of_computers integer,
  male_tch integer,
  female_tch integer,
  noresp_tch integer,
  head_tch integer,
  graduate_teachers integer,
  tch_with_profqual integer,
  days_non_tch_assgn integer,
  tch_non_tch_assgn integer,
  teacher_count integer,
  status statuses
);

CREATE OR REPLACE VIEW vw_paisa_data as
       select * from dblink('host=localhost dbname=dise_blore user=klp password=1q2w3e4r', 'select * from tb_paisa_data')
       as t1 (
  grant_type character varying(32),
  grant_amount integer,
  criteria character varying(32),
  operator character varying(3),
  factor character varying(32)
 );

CREATE OR REPLACE VIEW vw_school_dise as
       select * from dblink('host=localhost dbname=dise_blore user=klp password=1q2w3e4r', 'select * from tb_school_dise')
       as t1 (
  district character varying(100),
  block character varying(100),
  clust character varying(100),
  sid integer,
  name character varying(100),
  dise_code character varying(32),
  cat school_category,
  moi school_moi
 );

CREATE OR REPLACE VIEW vw_libinfra as
select * from dblink('host=localhost dbname=libinfra user=klp password=1q2w3e4r', 'select * from tb_libinfra')
as t1 (
  sid integer,
  libstatus  character varying(300),
  handoveryear integer ,
  libtype character varying(300),
  numbooks integer,
  numracks integer,
  numtables integer,
  numchairs integer,
  numcomputers integer,
  numups integer
);

CREATE OR REPLACE VIEW vw_ang_infra_agg as
select * from dblink('host=localhost dbname=ang_infra user=klp password=1q2w3e4r', 'select * from tb_ang_infra_agg')
as t1 (
   sid integer,
   ai_metric character varying(30),
   perc_score numeric(5,0),
   ai_group character varying(30)
);

CREATE OR REPLACE VIEW vw_ai_questions as
select * from dblink('host=localhost dbname=ang_infra user=klp password=1q2w3e4r', 'select * from tb_ai_questions')
as t1 (
  id integer,
  question character varying(200)
);

CREATE OR REPLACE VIEW vw_dise_facility_agg as
select * from dblink('host=localhost dbname=dise_blore user=klp password=1q2w3e4r', 'select * from tb_dise_facility_agg')
as t1 (
   sid integer,
   df_metric character varying(30),
   score numeric(5,0),
   df_group character varying(30)
);

CREATE OR REPLACE VIEW vw_lib_lang_agg as
select * from dblink('host=localhost dbname=library user=klp password=1q2w3e4r', 'select * from lang_agg')
as t1 (
   sid integer,
   class integer,
   month character varying(10),
   year character varying(10),
   book_lang character varying(50),
   child_count integer
);

CREATE OR REPLACE VIEW vw_lib_level_agg as
select * from dblink('host=localhost dbname=library user=klp password=1q2w3e4r', 'select * from level_agg')
as t1 (
   sid integer,
   class integer,
   month character varying(10),
   year character varying(10),
   book_level character varying(50),
   child_count integer
);
