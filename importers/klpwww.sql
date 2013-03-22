-- Schema creation script for KLP aggregate DB
-- This DB drives the KLP website
-- Created: Mon, 07 Jun 2010 13:32:23 IST
-- (C) Alok G Singh <alok@klp.org.in>

-- This code is released under the terms of the GNU GPL v3 
-- and is free software

DROP TABLE IF EXISTS "tb_bhierarchy" cascade;
CREATE TABLE "tb_bhierarchy" (
  "id" integer unique, -- 'Hierarchy id'
  "name" varchar(300) NOT NULL,
  PRIMARY KEY  ("id")
);


DROP TABLE IF EXISTS "tb_boundary_type" cascade;
CREATE TABLE "tb_boundary_type" (
  "id" integer unique, 
  "name" varchar(300) NOT NULL,
  PRIMARY KEY  ("id")
);


DROP TABLE IF EXISTS "tb_boundary" cascade;
CREATE TABLE "tb_boundary" (
  "id" integer unique, -- 'Boundary id'
  "parent" integer default NULL,
  "name" varchar(300) NOT NULL,
  "hid" integer NOT NULL references "tb_bhierarchy" ("id") on delete cascade,
  "type" integer NOT NULL references "tb_boundary_type" ("id") on delete cascade,
  PRIMARY KEY  ("id")
);

DROP TABLE IF EXISTS "tb_address" cascade;
CREATE TABLE "tb_address" (
  "id" integer unique, -- 'Address id'
  "address" varchar(1000) default NULL,
  "area" varchar(1000) default NULL,
  "pincode" varchar(20) default NULL,
  "landmark" varchar(1000) default NULL,
  "instidentification" varchar(1000) default NULL,
  "bus" varchar(1000) default NULL,
  "instidentification2" varchar(1000) default NULL,
  PRIMARY KEY ("id")
);

DROP TYPE IF EXISTS school_category cascade;
CREATE TYPE school_category as enum('Model Primary', 'Anganwadi', 'Akshara Balwadi', 'Independent  Balwadi', 'Others', 'Lower Primary', 'Upper Primary', 'Secondary');
DROP TYPE IF EXISTS school_sex cascade;
CREATE TYPE school_sex as enum('boys','girls','co-ed');
DROP TYPE IF EXISTS sex cascade;
CREATE TYPE sex as enum('male','female');
DROP TYPE IF EXISTS school_moi cascade;
CREATE TYPE school_moi as enum('kannada','urdu','tamil','telugu','english','marathi','malayalam', 'hindi', 'konkani', 'sanskrit', 'sindhi', 'other', 'gujarathi', 'not known', 'english and marathi', 'multi lng', 'nepali', 'oriya', 'bengali', 'english and hindi', 'english, telugu and urdu');  -- 'Medium of instruction
DROP TYPE IF EXISTS school_management cascade;
CREATE TYPE school_management as enum('ed', 'swd', 'local', 'p-a', 'p-ua', 'others', 'approved', 'ssa', 'kgbv', 'p-a-sc', 'p-a-st', 'jawahar', 'central', 'sainik', 'central govt', 'nri', 'madrasa-a', 'madrasa-ua', 'arabic-a', 'arabic-ua', 'sanskrit-a', 'sanskrit-ua', 'p-ua-sc', 'p-ua-st');


DROP TABLE IF EXISTS "tb_school" cascade;
CREATE TABLE "tb_school" (
  "id" integer unique, -- 'School id'
  "bid" integer NOT NULL REFERENCES "tb_boundary" ("id") ON DELETE CASCADE, -- 'Lowest Boundary id'
  "aid" integer default NULL REFERENCES "tb_address" ("id") ON DELETE CASCADE, -- 'Address id'
  "dise_code" varchar(14) default NULL,
  "name" varchar(300) NOT NULL,
  "cat" school_category default NULL,
  "sex" school_sex default 'co-ed',
  "moi" school_moi default 'kannada',
  "mgmt" school_management default 'ed',
  "status" integer NOT NULL,
  PRIMARY KEY  ("id")
);

DROP TABLE IF EXISTS "tb_child" cascade;
CREATE TABLE "tb_child" (
  "id" integer unique, -- 'School id'
  "name" varchar(300),
  "dob" date default NULL,
  "sex" sex NOT NULL default 'male',
  "mt" school_moi default 'kannada', -- Mother tongue
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "tb_class" cascade;
CREATE TABLE "tb_class" (
  "id" integer unique, -- 'Class id'
  "sid" integer, -- School id
  "name" char(50) NOT NULL,
  "section" char(1) default NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "tb_academic_year" cascade;
CREATE TABLE "tb_academic_year" (
  "id" integer unique, -- 'Academic year id'
  "name" varchar(20),
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "tb_student" cascade;
CREATE TABLE "tb_student" (
  "id" integer unique, -- 'Student id'
  "cid" integer NOT NULL REFERENCES "tb_child" ("id") ON DELETE CASCADE, -- 'Child id'
  "otherstudentid" varchar(100),
  "status" integer NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "tb_student_class" cascade;
CREATE TABLE "tb_student_class" (
  "stuid" integer NOT NULL REFERENCES "tb_student" ("id") ON DELETE CASCADE, -- 'Student id'
  "clid" integer NOT NULL REFERENCES "tb_class" ("id") ON DELETE CASCADE, -- 'Class id'
  "ayid" integer NOT NULL REFERENCES "tb_academic_year" ("id") ON DELETE CASCADE,
  "status" integer NOT NULL
);

DROP TABLE IF EXISTS "tb_partner" cascade;
CREATE TABLE "tb_partner" (
  "id" serial unique, -- 'Programme id'
  "name" varchar(300) NOT NULL,
  "status" integer NOT NULL,
  "info" varchar(500),
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "tb_programme" cascade;
CREATE TABLE "tb_programme" (
  "id" serial unique, -- 'Programme id'
  "name" varchar(300) NOT NULL,
  "start" date default CURRENT_DATE,
  "end" date default CURRENT_DATE,
  "type" integer NOT NULL references "tb_boundary_type" ("id") on delete cascade,
  "ayid" integer  REFERENCES "tb_academic_year" ("id") ON DELETE CASCADE,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "tb_assessment" cascade;
CREATE TABLE "tb_assessment" (
  "id" serial unique, -- 'Assessment id'
  "name" varchar(300) NOT NULL,
  "pid" integer references "tb_programme" ("id") ON DELETE CASCADE, -- Programme id
  "start" date default CURRENT_DATE,
  "end" date default CURRENT_DATE,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "tb_question" cascade;
CREATE TABLE "tb_question" (
  "id" integer, -- 'Question id'
  "assid" integer references "tb_assessment" ("id") ON DELETE CASCADE, -- Assessment id
  "desc" varchar(100) NOT NULL,
  "qtype" integer, --0- grade, 1-marks
  "maxmarks" decimal,
  "minmarks" decimal default 0,
  "grade" varchar(100),
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "tb_student_eval" cascade;
CREATE TABLE "tb_student_eval" (
  "qid" integer references "tb_question" ("id") ON DELETE CASCADE, -- 'Question id'
  "stuid" integer references "tb_student" ("id") ON DELETE CASCADE, -- Student id
  "mark" numeric(5,2) default NULL,
  "grade" char(30) default NULL,
  PRIMARY KEY ("qid", "stuid")
);

DROP TABLE IF EXISTS "tb_teacher" cascade;
CREATE TABLE "tb_teacher" (
  "id" integer unique,
  "name" varchar(300),
  "sex" sex NOT NULL default 'male',
  "status" integer,
  "mt" school_moi default 'kannada', -- Mother tongue
  "dateofjoining" date default NULL,
  "type" varchar(50),
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "tb_teacher_qual" cascade;
CREATE TABLE "tb_teacher_qual" (
"tid" integer references "tb_teacher" ("id") ON DELETE CASCADE,
"qualification" varchar(100),
  PRIMARY KEY ("tid","qualification")
);

DROP TABLE IF EXISTS "tb_teacher_class" cascade;
CREATE TABLE "tb_teacher_class" (
  "teacherid" integer references "tb_teacher" ("id") ON DELETE CASCADE, -- Teacher id
  "clid" integer NOT NULL REFERENCES "tb_class" ("id") ON DELETE CASCADE, -- 'Class id'
  "ayid" integer NOT NULL default 102 REFERENCES "tb_academic_year" ("id") ON DELETE CASCADE,
  "status" integer
);


-- Remote views via dblink

CREATE OR REPLACE VIEW vw_boundary_coord as 
       select * from dblink('host=localhost dbname=klp-coord user=klp password=1q2w3e4r', 'select * from boundary_coord') 
       as t1 (id_bndry integer, 
              type varchar(20), 
              coord geometry);

CREATE OR REPLACE VIEW vw_inst_coord as
       select * from dblink('host=localhost dbname=klp-coord user=klp password=1q2w3e4r', 'select * from inst_coord') 
       as t2 (instid integer,
              coord geometry);

DROP TYPE IF EXISTS admin_heirarchy cascade;
CREATE TYPE admin_heirarchy as enum('Centre','State','District','Zone','MP Constituency','MLA Constituency','City Corporation','Ward','Gram Panchayat');

CREATE OR REPLACE VIEW vw_electedrep_master as
       select * from dblink('host=localhost dbname=electrep_new user=klp password=1q2w3e4r', 
       'select id,parent,elec_comm_code,const_ward_name,const_ward_type,neighbours,current_elected_rep,current_elected_party from tb_electedrep_master')
       as t7 ( id integer,
              parent integer,
              elec_comm_code integer,
              const_ward_name character varying(300),
              const_ward_type admin_heirarchy,
              neighbours character varying(100),
              current_elected_rep character varying(300),
              current_elected_party character varying(300));

CREATE OR REPLACE VIEW vw_school_electedrep as
       select * from dblink('host=localhost dbname=electrep_new user=klp password=1q2w3e4r', 
       'select * from tb_school_electedrep')
       as t8 ( sid integer,
         ward_id integer,
         mla_const_id integer,
         mp_const_id integer,
         heirarchy integer);

CREATE OR REPLACE VIEW vw_school_eval as
select * from dblink('host=localhost dbname=pratham_mysore user=klp password=1q2w3e4r',
       'select * from tb_school_eval')
       as t (
         sid integer,
         disecode character varying(100),
         domain character varying(100),
         qid integer,
         value character varying(50));


DROP VIEW vw_dise_info;
CREATE OR REPLACE VIEW vw_dise_info as
select * from dblink('host=localhost dbname=dise_all user=klp password=1q2w3e4r', 'select df.school_code, to_number(df.tot_clrooms,''999''), to_number(df.male_tch,''999'') + to_number(df.female_tch,''999'') - to_number(df.noresp_tch,''999''), 
 to_number(de.class1_total_enr_boys,''999'') + 
 to_number(de. class2_total_enr_boys,''999'') + 
 to_number(de. class3_total_enr_boys,''999'') + 
 to_number(de. class4_total_enr_boys,''999'') + 
 to_number(de. class5_total_enr_boys,''999'') + 
 to_number(de. class6_total_enr_boys,''999'') + 
 to_number(de. class7_total_enr_boys,''999'') + 
 to_number(de. class8_total_enr_boys,''999'') , 
 to_number(de. class1_total_enr_girls,''999'') + 
 to_number(de. class2_total_enr_girls,''999'') +
 to_number(de. class3_total_enr_girls,''999'') + 
 to_number(de. class4_total_enr_girls,''999'') + 
 to_number(de. class5_total_enr_girls,''999'') + 
 to_number(de. class6_total_enr_girls,''999'') + 
 to_number(de. class7_total_enr_girls,''999'') + 
 to_number(de. class8_total_enr_girl,''999''),
 to_number(dg.lowest_class,''999''),
 to_number(dg.highest_class,''999''),
 de.acyear,
 to_number(dg.school_dev_grant_recd,''99999''),
 to_number(dg.school_dev_grant_expnd,''99999''),
 to_number(dg.tlm_grant_recd,''99999''),
 to_number(dg.tlm_grant_expnd,''99999''),
 to_number(dg.funds_from_students_recd,''999999''),
 to_number(dg.funds_from_students_expnd,''999999''),
 to_number(df.books_in_library,''999999'')
from tb_dise_facility df,tb_dise_enrol de,tb_dise_general dg where de.school_code=df.school_code and de.school_code=dg.school_code')
as t1 (
  dise_code character varying(32),
  classroom_count integer,
  teacher_count integer,
  boys_count integer,
  girls_count integer,
  lowest_class integer,
  highest_class integer,
  acyear character varying(15),
  sg_recd integer,
  sg_expnd integer,
  tlm_recd integer,
  tlm_expnd integer,
  ffs_recd integer,
  ffs_expnd integer,
  books_in_library integer
);

DROP VIEW vw_dise_facility_agg;        
CREATE OR REPLACE VIEW vw_dise_facility_agg as
select * from dblink('host=localhost dbname=dise_all user=klp password=1q2w3e4r', 'select * from tb_dise_facility_agg')
as t1 (
		dise_code character varying(32),
		df_metric character varying(30),
		score numeric(5,0),
		df_group character varying(30)
);

DROP VIEW vw_dise_rte_agg;        
CREATE OR REPLACE VIEW vw_dise_rte_agg as
select * from dblink('host=localhost dbname=dise_all user=klp password=1q2w3e4r', 'select * from tb_dise_rte_agg')
as t1 (
		dise_code character varying(32),
		rte_metric character varying(36),
		status character varying(30),
		rte_group character varying(32)
);
   
DROP VIEW vw_dise_display_master;        
CREATE OR REPLACE VIEW vw_dise_display_master as
select * from dblink('host=localhost dbname=dise_all user=klp password=1q2w3e4r', 'select * from tb_display_master')
as t1 (
		key character varying(36),
		value character varying(200)
);

DROP VIEW vw_paisa_data;
CREATE OR REPLACE VIEW vw_paisa_data as
			select * from dblink('host=localhost dbname=dise_all user=klp password=1q2w3e4r', 'select * from tb_paisa_data')
			as t1 (
		 grant_type character varying(32),
		 grant_amount integer,
		 criteria character varying(32),
		 operator character varying(3),
		 factor character varying(32)
);

DROP VIEW vw_libinfra;
CREATE OR REPLACE VIEW vw_libinfra as
    select * from dblink('host=localhost dbname=libinfra user=klp password=1q2w3e4r', 'select * from tb_libinfra')
         as t1 (
		sid integer,
		libstatus character varying(300),
		handoveryear integer,
		libtype character varying(300),
		numbooks  integer,
		numracks integer,
		numtables integer,
		numchairs integer,
		numcomputers integer,
		numups integer
);

DROP VIEW vw_anginfra_agg;
CREATE OR REPLACE VIEW vw_anginfra_agg as
    select * from dblink('host=localhost dbname=ang_infra user=klp password=1q2w3e4r', 'select * from tb_ang_infra_agg')
         as t1 (
    sid integer,
    ai_metric character varying(30),
    perc_score numeric(5,0),
    ai_group character varying(30)
);

DROP VIEW vw_ang_display_master;        
CREATE OR REPLACE VIEW vw_ang_display_master as
select * from dblink('host=localhost dbname=ang_infra user=klp password=1q2w3e4r', 'select * from tb_display_master')
as t1 (
		key character varying(36),
		value character varying(200)
);

DROP VIEW vw_mdm_agg;
CREATE OR REPLACE VIEW vw_mdm_agg as
select * from dblink('host=localhost dbname=apmdm user=klp password=1q2w3e4r', 'select * from tb_mdm_agg')
as t1 (
   "id" integer,
   "mon" varchar(15),
   "wk" integer,
   "indent" integer,
   "attend" integer
);

drop view vw_lib_level_agg;
create or replace view vw_lib_level_agg as
SELECT t1.klp_school_id, t1.class, t1.month, t1.year, t1.book_level, t1.child_count
   FROM dblink('host=localhost dbname=library user=klp password=1q2w3e4r', 'select * from level_agg') t1(klp_school_id integer, class integer, month character varying(10), year character varying(10), book_level character varying(50), child_count integer);


drop view vw_lib_lang_agg;
create or replace view vw_lib_lang_agg as
SELECT t1.klp_school_id, t1.class, t1.month, t1.year, t1.book_lang, t1.child_count
   FROM dblink('host=localhost dbname=library user=klp password=1q2w3e4r', 'select * from lang_agg') t1(klp_school_id integer, class integer, month character varying(10), year character varying(10), book_lang character varying(50), child_count integer);

drop view vw_lib_borrow;
create or replace view vw_lib_borrow as
SELECT t1.trans_year, t1.class, t1.issue_date, t1.klp_school_id, t1.school_name, t1.klp_child_id
   FROM dblink('host=localhost dbname=library user=klp password=1q2w3e4r', 'select trans_year,class,issue_date,klp_school_id,school_name,klp_child_id from libentry where flag is not null') t1(trans_year character varying(30), class numeric(3,0), issue_date character varying(20), klp_school_id numeric(7,0), school_name character varying(50), klp_child_id character varying(30));

-- The web user will query the DB
GRANT SELECT ON tb_school, 
                tb_student, 
                tb_bhierarchy, 
                tb_address, 
                tb_boundary, 
                tb_academic_year, 
                tb_programme, 
                tb_assessment, 
                tb_question, 
                tb_class, 
                tb_child, 
                tb_teacher,
                tb_teacher_class,
                tb_student_class,
                tb_student_eval,
                vw_boundary_coord, 
                vw_inst_coord,
                vw_electedrep_master,
                vw_school_electedrep,
                vw_school_eval,
                vw_paisa_data,
                vw_dise_display_master,
                vw_dise_facility_agg,
                vw_dise_info,
		vw_libinfra,
                vw_anginfra_agg,
                vw_ang_display_master,
                vw_mdm_agg,
                vw_lib_level_agg,
                vw_lib_lang_agg,
                vw_lib_borrow
TO web;
