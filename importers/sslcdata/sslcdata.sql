DROP TABLE IF EXISTS "tb_academic_year" cascade;
CREATE TABLE "tb_academic_year" (
  "id" integer unique, -- 'Academic year id'
  "name" varchar(20),
  PRIMARY KEY ("id")
);

insert into tb_academic_year values('1','2007-2008');
insert into tb_academic_year values('2','2008-2009');
insert into tb_academic_year values('6','2005-2006');
insert into tb_academic_year values('7','2004-2005');
insert into tb_academic_year values('90','2006-2007');
insert into tb_academic_year values('100','2000-2001');
insert into tb_academic_year values('101','2010-2011');
insert into tb_academic_year values('102','2011-2012');
insert into tb_academic_year values('121','2012-2013');
insert into tb_academic_year values('103','2015-2016');
insert into tb_academic_year values('104','2016-2017');
insert into tb_academic_year values('105','2017-2018');
insert into tb_academic_year values('106','2018-2019');
insert into tb_academic_year values('107','2019-2020');
insert into tb_academic_year values('108','2020-2021');
insert into tb_academic_year values('109','2021-2022');
insert into tb_academic_year values('110','2022-2023');
insert into tb_academic_year values('111','2023-2024');
insert into tb_academic_year values('112','2024-2025');
insert into tb_academic_year values('119','2009-2010');

DROP TABLE IF EXISTS "tb_sslcresults";
CREATE TABLE "tb_sslcresults" (
  "dist_code" varchar(10),
  "school_code" varchar(10),
  "reg_no" varchar(100),
  "dob" varchar(100),
  "student_name" varchar(100),
  "mother_name" varchar(100),
  "father_name" varchar(100),
  "caste_code" varchar(20),
  "gender_code" varchar(20),
  "medium" varchar(5),
  "physical_condition" varchar(10),
  "center_code" varchar(10),
  "l1_marks" varchar(50),
  "l1_result" varchar(5),
  "l2_marks" varchar(50),
  "l2_result" varchar(5),
  "l3_marks" varchar(50),
  "l3_result" varchar(5),
  "s1_marks" varchar(50),
  "s1_result" varchar(5),
  "s2_marks" varchar(50),
  "s2_result" varchar(5),
  "s3_marks" varchar(50),
  "s3_result" varchar(5),
  "total" varchar(10),
  "result" varchar(10),
  "class" varchar(10),
  "schoolname" varchar(500)  ,
  "ayid" integer NOT NULL REFERENCES "tb_academic_year" ("id") ON DELETE CASCADE,
  "taluq_code" varchar(10),
  "school_type" varchar(10),
  "urban_rural" varchar(10),
  "candidate_type" varchar(10)
);
