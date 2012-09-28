-- Schema creation script for Pratham Mysore

-- This code is released under the terms of the GNU GPL v3 
-- and is free software


DROP TYPE IF EXISTS school_category cascade;
CREATE TYPE school_category as enum('Model Primary', 'Anganwadi', 'Akshara Balwadi', 'Independent  Balwadi', 'Lower Primary', 'Upper Primary', 'Secondary');

DROP TYPE IF EXISTS school_moi cascade;
CREATE TYPE school_moi as enum('kannada','urdu','tamil','telugu','english','marathi','malayalam', 'hindi', 'konkani', 'sanskrit', 'sindhi', 'other', 'gujarathi', 'not known', 'english and marathi', 'multi lng', 'nepali', 'oriya', 'bengali', 'english and hindi', 'english, telugu and urdu');

DROP TYPE IF EXISTS statuses cascade;
CREATE TYPE statuses as enum('active','inactive');


DROP TABLE IF EXISTS "tb_school_info" cascade;
CREATE TABLE "tb_school_info"(
"district" varchar(50),
"block" varchar(50),
"cluster" varchar(50),
"schoolname" varchar(100),
"address" varchar(300),
"moi" varchar(50),
"disecode" varchar(100)
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
  "type" integer, 
  "ayid" integer,
  "partnerid" integer,
  "ptype" integer,
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
  "desc" varchar(100) NOT NULL,
  "assid" integer references "tb_assessment" ("id") ON DELETE CASCADE, -- Assessment id
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "tb_school_eval" cascade;
CREATE TABLE "tb_school_eval"(
  "sid" integer,
  "disecode" varchar(100),
  "domain" varchar(100),
  "qid" integer references "tb_question" ("id") ON DELETE CASCADE, 
  "value" varchar(50)
);

