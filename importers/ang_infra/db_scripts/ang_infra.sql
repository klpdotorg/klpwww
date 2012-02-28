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
  district varchar(30),
  project varchar(30),
  circle varchar(100),
  name varchar(100),
  ans_array varchar(220)
);
