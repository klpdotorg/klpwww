-- Schema creation script for KLP intermediate DB
-- This DB is for populating EMS DB

-- This code is released under the terms of the GNU GPL v3 
-- and is free software


DROP TYPE IF EXISTS school_category cascade;
CREATE TYPE school_category as enum('Model Primary', 'Anganwadi', 'Akshara Balwadi', 'Independent  Balwadi', 'Lower Primary', 'Upper Primary', 'Secondary');

DROP TYPE IF EXISTS school_moi cascade;
CREATE TYPE school_moi as enum('kannada','urdu','tamil','telugu','english','marathi','malayalam', 'hindi', 'konkani', 'sanskrit', 'sindhi', 'other', 'gujarathi', 'not known', 'english and marathi', 'multi lng', 'nepali', 'oriya', 'bengali', 'english and hindi', 'english, telugu and urdu');

DROP TYPE IF EXISTS statuses cascade;
CREATE TYPE statuses as enum('active','inactive');

DROP TABLE IF EXISTS "tb_dise_facility" cascade;
CREATE TABLE "tb_dise_facility" (
  "dise_id" character varying(32),
  "classroom_count" integer, 
  "teacher_count" integer,
  "status" statuses default 'active' 
);

DROP TABLE IF EXISTS "tb_school_dise" cascade;
CREATE TABLE tb_school_dise as
       select * from dblink('host=localhost dbname=klpwwwnew user=klp password=1q2w3e4r', 'select b3.name,b2.name,b1.name,s.id,s.name,s.dise_code,s.cat,s.moi from tb_school s, tb_boundary b1, tb_boundary b2, tb_boundary b3 where s.bid = b1.id and b1.parent=b2.id and b2.parent=b3.id and b3.id in (433,8877) and s.status=2')
       as t1 (
  district varchar(100),
  block varchar(100),
  clust varchar(100),
  sid integer,
  name varchar(100),
  dise_code varchar(32),
  cat school_category,
  moi school_moi
);

DROP TABLE IF EXISTS "tb_paisa_data" cascade;
CREATE TABLE "tb_paisa_data" (
  "grant_type" character varying(32),
  "grant_amount" integer,
  "criteria" character varying(32), -- possible values teacher_count, classroom_count, school_cat
  "operator" character varying(3), -- possible values gt - greater than,eq - equal to, per - multiply, lt - less than
  "factor" character varying(32)
);

insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('maintenance',10000,'classroom_count','gt', '3');
insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('maintenance',5000,'classroom_count','lt', '3');
insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('tlm',500,'teacher_count','per', null);
insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('annual',5000,'school_cat','eq','Lower Primary');
insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('annual',12000,'school_cat','eq','Upper Primary');
-- Assumption that all upper primaries have class 1 - 7 ( Otherwise grant for upper primary with 5,6,7 is 7000)
insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('annual',12000,'school_cat','eq','Model Primary');
-- Assumption that all model primaries are upper primary
