DROP TABLE IF EXISTS "tb_sys_data" cascade;
CREATE TABLE "tb_sys_data" (
  "id" serial unique, -- 'SYS id'
  "schoolid" integer,
  "name" varchar(100),
  "email" varchar(100),
  "telephone" varchar(50),
  "dateofvisit" varchar(50),
  "comments" varchar(2000),
  "entered_timestamp" timestamp with time zone not null default now(),
  "verified" varchar(1) default 'N'
);

DROP TABLE IF EXISTS "tb_sys_qans";
CREATE TABLE "tb_sys_qans"(
  "sysid" integer NOT NULL references "tb_sys_data" ("id") on delete cascade,
  "qid" integer,
  "answer" varchar(500)
);

DROP TYPE IF EXISTS sys_question_type;
CREATE TYPE sys_question_type as enum('text', 'numeric', 'radio','checkbox');

DROP TABLE IF EXISTS "tb_sys_questions";
CREATE TABLE "tb_sys_questions" (
  "id" serial unique, -- 'Question id'
  "hiertype" integer, -- 1 for school, 2 for preschool
  "qtext" varchar(500),
  "qfield" varchar(50)
);
 
--Seed data for school questions
INSERT INTO tb_sys_questions values(default,1,'An All weather (pucca) building','schoolq1');
INSERT INTO tb_sys_questions values(default,1,'Boundary wall/ Fencing','schoolq2');
INSERT INTO tb_sys_questions values(default,1,'Play ground','schoolq3');
INSERT INTO tb_sys_questions values(default,1,'Accessibility to students with disabilities','schoolq4');
INSERT INTO tb_sys_questions values(default,1,'Separate office for Headmaster','schoolq5');
INSERT INTO tb_sys_questions values(default,1,'Separate room as Kitchen / Store for Mid day meals','schoolq6');
INSERT INTO tb_sys_questions values(default,1,'Separate Toilets for Boys and Girls','schoolq7');
INSERT INTO tb_sys_questions values(default,1,'Drinking Water facility','schoolq8');
INSERT INTO tb_sys_questions values(default,1,'Library','schoolq9');
INSERT INTO tb_sys_questions values(default,1,'Play Material or Sports Equipment','schoolq10');
INSERT INTO tb_sys_questions values(default,1,'Did you see any evidence of mid day meal being served (food being cooked, food waste etc.) on the day of your visit?','schoolq11');
INSERT INTO tb_sys_questions values(default,1,'How many functional class rooms (exclude rooms that are not used for conducting classes for whatever reason) does the school have?','schoolq12');
INSERT INTO tb_sys_questions values(default,1,'Teachers sharing a single class room','schoolq13');
INSERT INTO tb_sys_questions values(default,1,'How many classrooms had no teachers in the class?','schoolq14');
INSERT INTO tb_sys_questions values(default,1,'What was the total numbers of teachers present (including head master)?','schoolq15');

--Seed data for anganwadi sys
INSERT INTO tb_sys_questions values(default,2,'Anganwadi opened on time (10 A.M)','angq1');
INSERT INTO tb_sys_questions values(default,2,'A proper building (designated for running Anganwadi)','angq2');
INSERT INTO tb_sys_questions values(default,2,'Were at least 50% of the children enrolled were present on the day of visit?','angq3');
INSERT INTO tb_sys_questions values(default,2,'Attendance being recorded','angq4');
INSERT INTO tb_sys_questions values(default,2,'Spacious enough premises for children','angq5');
INSERT INTO tb_sys_questions values(default,2,'Space for the Children to Play','angq6');
INSERT INTO tb_sys_questions values(default,2,'Designated area for storing and cooking food','angq7');
INSERT INTO tb_sys_questions values(default,2,'If this space to stock food was observed, was this space  neat and free from dust, waste and protected from rain and wind and free from pest, worms and rats?','angq8');
INSERT INTO tb_sys_questions values(default,2,'Hygeinic measures for storing and cooking food','angq9');
INSERT INTO tb_sys_questions values(default,2,'Evidence of Food served on time','angq10');
INSERT INTO tb_sys_questions values(default,2,'Well maintained floor ','angq11');
INSERT INTO tb_sys_questions values(default,2,'Roof well maintained - without damage /leakage ','angq12');
INSERT INTO tb_sys_questions values(default,2,'Boundary Wall, Doors, windows for security','angq13');
INSERT INTO tb_sys_questions values(default,2,'Colourful Wall paintings','angq14');
INSERT INTO tb_sys_questions values(default,2,'Use of a Waste Basket','angq15');
INSERT INTO tb_sys_questions values(default,2,'Drinking Water facility','angq16');
INSERT INTO tb_sys_questions values(default,2,'Hand Wash facility','angq17');
INSERT INTO tb_sys_questions values(default,2,'Toilet','angq18');
INSERT INTO tb_sys_questions values(default,2,'Is the teacher trained  to teach physically challenged / disabled children?','angq19');
INSERT INTO tb_sys_questions values(default,2,'Are Bal Vikas Samithi meetings held as per the norm?','angq20');
INSERT INTO tb_sys_questions values(default,2,'Is there a Friends of Anganwadi group for this anganwadi?','angq21');
INSERT INTO tb_sys_questions values(default,2,'Blackboard','angq22');
INSERT INTO tb_sys_questions values(default,2,'Teaching and Learning Material','angq23');
INSERT INTO tb_sys_questions values(default,2,'Play material','angq24');

--Seed extra for school questions
INSERT INTO tb_sys_questions values(default,1,'Designated Librarian/Teacher','schoolq16');
INSERT INTO tb_sys_questions values(default,1,'Class-wise timetable for the Library','schoolq17');
INSERT INTO tb_sys_questions values(default,1,'Teaching and Learning material','schoolq18');
INSERT INTO tb_sys_questions values(default,1,'Sufficient number of class rooms','schoolq19');
INSERT INTO tb_sys_questions values(default,1,'Were at least 50% of the children enrolled present on the day you visited the school?','schoolq20');
INSERT INTO tb_sys_questions values(default,1,'Were all teachers present on the day you visited the school?','schoolq21');



DROP TABLE IF EXISTS "tb_sys_displayq";
CREATE TABLE "tb_sys_displayq" (
  "id" serial unique, -- 'Question id'
  "hiertype" integer, -- 1 for school, 2 for preschool
  "qtext" varchar(500),
  "qfield" varchar(50),
  "qtype" sys_question_type,
  "options" varchar(500)[][]
);

--Seed data for school questions
INSERT INTO tb_sys_displayq values(default,1,'Check the boxes to indicate whether you observed or found the following in the school (You can check multiple boxes):','schoolq0','checkbox','{{"schoolq1","An All weather (Pucca) building"},{"schoolq2","Boundary wall/ Fencing"},{"schoolq3","Play ground"},{"schoolq7","Separate Toilets for Boys and Girls"},{"schoolq8","Drinking Water facility"},{"schoolq5","Separate office for Headmaster"},{"schoolq6","Separate room as Kitchen / Store for Mid day meals"},{"schoolq4","Accessibility to students with disabilities"}}');
INSERT INTO tb_sys_displayq values(default,1,'Check the boxes to indicate whether you observed or found the following in the school (You can check multiple boxes):','schoolq0','checkbox','{{"schoolq9","Library"},{"schoolq16","Designated Librarian/Teacher"},{"schoolq17","Class-wise timetable for the Library"},{"schoolq10","Play Material or Sports Equipment"},{"schoolq18","Teaching and Learning material"},{"schoolq19","Sufficient number of class rooms"},{"schoolq13","Teachers sharing a single class room"}}');
INSERT INTO tb_sys_displayq values(default,1,'Did you see any evidence of mid day meal being served (food being cooked,food waste etc.) on the day of your visit?','schoolq11','radio','{"Yes","No"}');
INSERT INTO tb_sys_displayq values(default,1,'Were at least 50% of the children enrolled present on the day you visited the school?','schoolq20','radio','{"Yes","No"}');
INSERT INTO tb_sys_displayq values(default,1,'Were all teachers present on the day you visited the school?','schoolq21','radio','{"Yes","No"}');


--Seed data for preschool questions
INSERT INTO tb_sys_displayq values(default,2,'Check the boxes to indicate whether you observed or found the following in the school (You can check multiple boxes). About Infrastructure:','schoolq0','checkbox','{{"angq2","A proper building (designated for running Anganwadi)"},{"angq13","Boundary Wall, Doors, windows for security"},{"angq14","Colourful Wall paintings"},{"angq5","Spacious enough premises for children"},{"angq6","Space for the Children to Play"},{"angq11","Well maintained floor"},{"angq12","Roof well maintained - without damage /leakage"}}');
INSERT INTO tb_sys_displayq values(default,2,'About Health and Hygiene','schoolq0','checkbox','{{"angq10","Evidence of Food served on time"},{"angq7","Designated area for storing and cooking food"},{"angq9","Hygeinic measures for storing and cooking food"},{"angq15","Use of a Waste Basket"},{"angq16","Drinking Water facility"},{"angq17","Hand Wash facility"},{"angq18","Toilet"}}');
INSERT INTO tb_sys_displayq values(default,2,'About Administration','schoolq0','checkbox','{{"angq1","Anganwadi opened on time (10 A.M)"},{"angq4","Attendance being recorded"},{"angq22","Blackboard"},{"angq23","Teaching and Learning Material"},{"angq24","Play material"}}');
INSERT INTO tb_sys_displayq values(default,2,'Were at least 50% of the children enrolled present on the day you visitedthe school?','angq3','radio','{"Yes","No"}');
INSERT INTO tb_sys_displayq values(default,2,'Is the teacher trained to teach physically challenged or disabled children?','angq19','radio','{"Yes","No"}');



DROP TABLE IF EXISTS "tb_sys_images";
CREATE TABLE "tb_sys_images" (
  "schoolid" integer,
  "original_file" varchar(100),
  "hash_file" varchar(100),
  "verified" varchar(1) default 'N',
  "sysid" integer NOT NULL references "tb_sys_data" ("id") on delete cascade
);


GRANT SELECT ON tb_sys_data,
                tb_sys_displayq,
                tb_sys_questions,
                tb_sys_images
TO web;

GRANT UPDATE ON tb_sys_data,tb_sys_data_id_seq,tb_sys_images TO web;
GRANT INSERT ON tb_sys_data,tb_sys_images,tb_sys_qans TO web;
