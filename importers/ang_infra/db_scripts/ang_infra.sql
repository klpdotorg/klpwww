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
  ans integer 
);

DROP TABLE tb_ang_info;
CREATE TABLE tb_ang_info (
   sid integer,
   dist varchar(32),
   proj varchar(32),
   circ varchar(100),
   name varchar(100)
);


