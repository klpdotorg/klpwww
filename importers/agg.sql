-- Aggregation tables

DROP TABLE IF EXISTS "tb_school_agg";
CREATE TABLE "tb_school_agg" (
  "id" integer,
  "name" varchar(300),
  "bid" integer,
  "sex" sex,
  "mt" school_moi,
  "num" integer
);

DROP TABLE IF EXISTS "tb_school_assessment_agg";
CREATE TABLE "tb_school_assessment_agg" (
  "sid" integer REFERENCES "tb_school" ("id") ON DELETE CASCADE,
  "assid" integer REFERENCES "tb_assessment" ("id") ON DELETE CASCADE,
  "clid" integer REFERENCES "tb_class" ("id") ON DELETE CASCADE,
  "sex" sex,
  "mt" school_moi,
  "aggtext" varchar(100) NOT NULL,
  "aggval" numeric(6,2) DEFAULT 0
);

DROP TABLE IF EXISTS "tb_school_weighted_assessment_agg";
CREATE TABLE "tb_school_weighted_assessment_agg" (
  "sid" integer REFERENCES "tb_school" ("id") ON DELETE CASCADE,
  "assid" integer REFERENCES "tb_assessment" ("id") ON DELETE CASCADE,
  "clid" integer REFERENCES "tb_class" ("id") ON DELETE CASCADE,
  "sex" sex,
  "mt" school_moi,
  "numstudents" numeric(6,2) DEFAULT 0,
  "asstotalmarks" numeric(6,2),
  "ass_weightedtotalmarks" numeric(6,2),
  "aggmarks" numeric(6,2),
  "percentagemarks" numeric(6,2),
  "weighted_aggmarks" numeric(6,2),
  "weighted_percentagemarks" numeric(6,2)
);

CREATE OR REPLACE FUNCTION get_total_marks(int) returns numeric as
  'select sum(maxmarks) as summarks from tb_question where assid=$1 group by assid;'
  LANGUAGE SQL
  IMMUTABLE
  RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION get_num_qs(int) returns bigint AS
  'select count(id) from tb_question where assid=$1;'
  LANGUAGE SQL
  IMMUTABLE
  RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION get_weighted_total(int) returns numeric as
  'select sum(q.maxmarks/marks.maxmarks * q.maxmarks) as marks from (select sum(maxmarks) as maxmarks from tb_question where assid=$1)marks, tb_question q where q.assid=$1;'
  LANGUAGE SQL
  IMMUTABLE
  RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION get_weightedmarks(numeric,numeric,numeric) returns numeric AS
   $$
        BEGIN
                RETURN ($1*$2)/$3;
        END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_average(numeric,numeric) returns numeric AS
   $$
        BEGIN
                RETURN ($1)/$2;
        END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_percentage(numeric,numeric) returns numeric AS
   $$
        BEGIN
                RETURN ($1)/$2*100;
        END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE function assessment_agg(int) returns void as $$
declare
   assagg RECORD;
begin
  for assagg in
    select --stuid,
      schoolid,
      assid,
      classid,
      gender,
      mt,
      numstu,
      totalmarks,
      wtotal,
      summarks as aggmarks,
      get_percentage(summarks,totalmarks*numstu) as permarks,
      wsum as waggmarks,
      get_percentage(wsum,wtotal*numstu) as wpermarks
    from
      (select --weighted.stuid as stuid,
         weighted.assid as assid,
         weighted.schoolid as schoolid,
         weighted.classid as classid,
         weighted.gender as gender,
         weighted.mt as mt,
         count(distinct weighted.stuid) as numstu,
         weighted.totalmarks as totalmarks,
         sum(marks) as summarks,
         weightedtotal as wtotal,
         sum(wmark) as wsum
       from
         (select se.stuid as stuid,
            q.assid as assid,
            sg.sid as schoolid,
            stusg.clid as classid,
            c.sex as gender,
            c.mt as mt,
            se.mark as marks,
            totalmarks as totalmarks,
            get_weightedmarks(se.mark,q.maxmarks,totalmarks) as wmark
          from
            get_total_marks($1) totalmarks,
            tb_student_eval se,
            tb_question q,
            tb_student stu,
            tb_class sg,
            tb_student_class stusg,
            tb_child c
          where
            se.qid=q.id
            and q.assid=$1
            and stu.id=se.stuid
            and stu.id=stusg.stuid
            and stusg.ayid=102
            and stusg.clid=sg.id
            and stu.cid=c.id) weighted,
         get_weighted_total($1) weightedtotal
       group by assid,schoolid,classid,gender,mt,totalmarks,weightedtotal)summed
  loop
    insert into tb_school_weighted_assessment_agg values(assagg.schoolid,assagg.assid,assagg.classid,assagg.gender,assagg.mt,assagg.numstu,assagg.totalmarks,assagg.wtotal,assagg.aggmarks,assagg.permarks,assagg.waggmarks,assagg.wpermarks);
  end loop;
end;
$$ language plpgsql;




CREATE OR REPLACE function agg_school(int) returns void as $$
declare
        schs RECORD;
begin
        for schs in SELECT s.id as id, s.name as name, s.bid as bid, c.sex as sex, c.mt as mt, count(stu.id) AS count
                 FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s
                 WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND sc.status=1 AND stu.cid = c.id AND sc.ayid = $1
                 GROUP BY s.id, s.name, s.bid, c.sex, c.mt 
        loop
                insert into tb_school_agg values (schs.id, schs.name, schs.bid, schs.sex, schs.mt, schs.count);
        end loop;
end;
$$ language plpgsql;

CREATE OR REPLACE function agg_school_reading(int, int) returns void as $$
declare
        stueval RECORD;
begin
        for stueval in SELECT s.id as id, ass.id as assid, sc.clid as clid, c.sex as sex, c.mt as mt, se.grade as grade, cast(count(distinct stu.id) as float) as cnt
                       FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se,tb_question q, tb_assessment ass
                       WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid= ass.id AND ass.id = $1 AND sc.ayid = $2 AND se.grade IS NOT NULL
                       GROUP BY s.id, ass.id, sc.clid, c.sex, c.mt, se.grade
        loop
                insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, stueval.grade, stueval.cnt);
        end loop;
end;
$$ language plpgsql;

CREATE OR REPLACE function agg_school_nng(int, int) returns void as $$
declare
        stueval RECORD;
begin

        for stueval in 
        SELECT id, assid,clid,sex,mt,
        count(case when mark < 20 then id else null end) as Rung1, 
        count(case when mark between 20 and 40 then id else null end) as Rung2,
        count(case when mark between 40 and 60 then id else null end) as Rung3,
        count(case when mark between 60 and 80 then id else null end) as Rung4,
        count(case when mark > 80 then id else null end) as Rung5
        FROM ( SELECT se.stuid,s.id as id, ass.id as assid, sc.clid as clid, c.sex as sex, c.mt as mt, avg(se.mark) as mark 
               FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass,tb_question q 
               WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid = ass.id AND ass.id = $1 AND sc.ayid =$2  
               GROUP BY s.id, ass.id, sc.clid, c.sex, c.mt,se.stuid ) as output 
        GROUP BY id,assid,clid,sex,mt
        loop
               insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Rung1', stueval.Rung1);
               insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Rung2', stueval.Rung2);
               insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Rung3', stueval.Rung3);
               insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Rung4', stueval.Rung4);
               insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Rung5', stueval.Rung5);
        end loop;

end;
$$ language plpgsql;

CREATE OR REPLACE function agg_school_ang(int, int) returns void as $$
declare
        stueval RECORD;
        domains text[7];
        dqmax integer[7];
        dqmin integer := 1;
begin
        domains[1] = 'General awareness'; dqmax[1] = 5;
        domains[2] = 'Gross motor'; dqmax[2] = 9;
        domains[3] = 'Fine motor'; dqmax[3] = 15;
        domains[4] = 'Language'; dqmax[4] = 28;
        domains[5] = 'Intellectual'; dqmax[5] = 33;
        domains[6] = 'Socio-emotional'; dqmax[6] = 37;
        domains[7] = 'Pre-academic'; dqmax[7] = 56;

        for i in 1..7 loop
            for stueval in SELECT s.id as id, ass.id as assid, sc.clid as clid, c.sex as sex, c.mt as mt, avg(cast(se.grade as integer)) as dmarks
                       FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass, tb_question q
                       WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid = ass.id AND ass.id = $1 AND sc.ayid = $2 AND se.qid = q.id AND ass.id = q.assid AND cast(q.desc as integer) between dqmin and dqmax[i]
                       GROUP BY s.id, ass.id, sc.clid, c.sex, c.mt
                       ORDER BY s.id
            loop
                   insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, domains[i], stueval.dmarks);
            end loop;
            dqmin := dqmax[i] + 1;
        end loop;

end;
$$ language plpgsql;

CREATE OR REPLACE function agg_school_eng_old(int, int) returns void as $$
declare
        stueval RECORD;
begin

        for stueval in 
        SELECT id, assid,clid,sex,mt,
        count(case when mark < 20 then id else null end) as Rung1, 
        count(case when mark between 20 and 40 then id else null end) as Rung2,
        count(case when mark between 40 and 60 then id else null end) as Rung3,
        count(case when mark between 60 and 80 then id else null end) as Rung4,
        count(case when mark > 80 then id else null end) as Rung5
        FROM ( SELECT se.stuid,s.id as id, ass.id as assid, sc.clid as clid, c.sex as sex, c.mt as mt, case when se.qid between 692 and 695 then avg(cast(se.mark as integer) *100) when se.qid between 685 and 692 then avg(se.mark) end as mark
               FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass,tb_question q 
               WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid = ass.id AND ass.id = $1 AND sc.ayid =$2  
               GROUP BY s.id, ass.id, sc.clid, c.sex, c.mt,se.qid,se.stuid ) as output 
        GROUP BY id,assid,clid,sex,mt
        loop
               insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Rung1', stueval.Rung1);
               insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Rung2', stueval.Rung2);
               insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Rung3', stueval.Rung3);
               insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Rung4', stueval.Rung4);
               insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Rung5', stueval.Rung5);
        end loop;

end;
$$ language plpgsql;


CREATE OR REPLACE function agg_school_eng_119(int) returns void as $$
declare
        stueval RECORD;
begin

        for stueval in
        SELECT sid, assid,clid,sex,mt, 
          count(case when wskill=1 then stuid else null end) as write1,
          count(case when wskill=0 then stuid else null end) as write0,
          count(case when sskill=1 then stuid else null end) as speak1,
          count(case when sskill=0 then stuid else null end) as speak0,
          count(case when rskill=1 then stuid else null end) as read1,
          count(case when rskill=0 then stuid else null end) as read0
        from( 
          select aggregates.stuid as stuid,s.id as sid,aggregates.assid as assid,stusg.clid as clid, c.sex as sex,c.mt as mt,  case when wagg <10 then 0 else 1 end as wskill, case when sagg<1 then 0 else 1 end as sskill, case when ragg<1 then 0 else 1 end as rskill 
          from
          (  select se.stuid as stuid,q.assid as assid, 
               sum(case when se.qid in (674,675,676) then case when se.mark is null then 0 else cast(se.mark as int) end end)  as wagg, 
               sum(case when se.qid=680 then  case when se.grade is null then 0 else cast(se.grade as int) end end) as sagg, 
               sum(case when se.qid=681 then case when se.grade is null then 0 else cast(se.grade as int) end end) as ragg 
             from tb_student_eval se,tb_question q 
             where se.qid=q.id and q.assid=$1 group by se.stuid,q.assid
          ) aggregates, tb_school s, tb_child c, tb_student_class stusg, tb_class cl, tb_student stu
          where
            stusg.stuid=aggregates.stuid
            and stu.id=stusg.stuid
            and stusg.clid=cl.id
            and stusg.ayid=119
            and cl.sid=s.id
            and stu.cid=c.id)info
           group by sid,assid,clid,sex,mt 
        loop
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Can Read', stueval.read1);
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Cannot Read', stueval.read0);
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Can Write', stueval.write1);
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Cannot Write', stueval.write0);
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Can Speak', stueval.speak1);
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Cannot Speak', stueval.speak0);
        end loop;

end;
$$ language plpgsql;
 

CREATE OR REPLACE function agg_school_eng(int,int) returns void as $$
declare
        stueval RECORD;
begin

        for stueval in
        SELECT sid, assid,clid,sex,mt, 
          count(case when wskill=1 then stuid else null end) as write1,
          count(case when wskill=0 then stuid else null end) as write0,
          count(case when sskill=1 then stuid else null end) as speak1,
          count(case when sskill=0 then stuid else null end) as speak0,
          count(case when rskill=1 then stuid else null end) as read1,
          count(case when rskill=0 then stuid else null end) as read0
        from( 
          select aggregates.stuid as stuid,s.id as sid,aggregates.assid as assid,stusg.clid as clid, c.sex as sex,c.mt as mt,  case when wagg <10 then 0 else 1 end as wskill, case when sagg<1 then 0 else 1 end as sskill, case when ragg<1 then 0 else 1 end as rskill 
          from
          (  select se.stuid as stuid,q.assid as assid, 
               sum(case when se.qid in (246,247,248) then  case when se.grade is null then 0 else cast(se.grade as int) end end) as wagg, 
               sum(case when se.qid=251 then  case when se.grade is null then 0 else cast(se.grade as int) end end) as sagg, 
               sum(case when se.qid=252 then case when se.grade is null then 0 else cast(se.grade as int) end end) as ragg 
             from tb_student_eval se,tb_question q 
             where se.qid=q.id and q.assid=$1 group by se.stuid,q.assid
          ) aggregates, tb_school s, tb_child c, tb_student_class stusg, tb_class cl, tb_student stu
          where
            stusg.stuid=aggregates.stuid
            and stu.id=stusg.stuid
            and stusg.clid=cl.id
            and stusg.ayid=$2
            and cl.sid=s.id
            and stu.cid=c.id)info
           group by sid,assid,clid,sex,mt 
        loop
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Can Read', stueval.read1);
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Cannot Read', stueval.read0);
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Can Write', stueval.write1);
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Cannot Write', stueval.write0);
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Can Speak', stueval.speak1);
            insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt, 'Cannot Speak', stueval.speak0);
        end loop;

end;
$$ language plpgsql;
 

-- Populate tb_school_agg for the current academic year
select agg_school(101);
-- 2006 Reading
select agg_school_reading(1, 90);
select agg_school_reading(2, 90);
select agg_school_reading(3, 90);
select agg_school_reading(4, 90);

--2008 Reading
select agg_school_reading(21,2);
select agg_school_reading(22,2);

-- 2009 Reading
select agg_school_reading(27, 119);
select agg_school_reading(28, 119);
select agg_school_reading(29, 119);
select agg_school_reading(31, 119);
select agg_school_reading(32, 119);

-- 2009 Target reading
select agg_school_reading(40, 119);

--2010 Reading
select agg_school_reading(59, 101);
select agg_school_reading(60, 101);
select agg_school_reading(61, 101);

--Marks
-- 2007 NNG
select agg_school_nng(5, 1);
select agg_school_nng(6, 1);
select agg_school_nng(7, 1);
select agg_school_nng(8, 1);
select agg_school_nng(9, 1);
select agg_school_nng(10, 1);
select agg_school_nng(11, 1);
select agg_school_nng(12, 1);

-- 2008 NNG
select agg_school_nng(13, 2);
select agg_school_nng(14, 2);
select agg_school_nng(15, 2);
select agg_school_nng(16, 2);
select agg_school_nng(17, 2);
select agg_school_nng(18, 2);
select agg_school_nng(19, 2);
select agg_school_nng(20, 2);

-- 2009 NNG
select agg_school_nng(33, 119);
select agg_school_nng(34, 119);

-- 2009 Ramanagra NNG1
select agg_school_nng(35, 119);
select agg_school_nng(36, 119);

-- 2009 Ramanagra NNG2
select agg_school_nng(37, 119);
select agg_school_nng(38, 119);

-- 2009 Target NNG
select agg_school_nng(39,119);


--2010 NNG
select agg_school_nng(41,101);
select agg_school_nng(42,101);
select agg_school_nng(43,101);
select agg_school_nng(44,101);
select agg_school_nng(45,101);
select agg_school_nng(46,101);
select agg_school_nng(47,101);
select agg_school_nng(48,101);

select agg_school_nng(51,101);
select agg_school_nng(52,101);
select agg_school_nng(53,101);
select agg_school_nng(54,101);


--Anganwadi
-- 2009 Anganwadi
select agg_school_ang(23, 119);
select agg_school_ang(24, 119);

--2010 Anganwadi
select agg_school_ang(56, 101);
select agg_school_ang(57, 101);
select agg_school_ang(58, 101);
select agg_school_ang(62, 101);


--English
--2009 English
select agg_school_eng_119(25);
select agg_school_eng_119(26);

--2010 English
select agg_school_eng(49,101);
select agg_school_eng(50,101);




--For weighted assessment
--For assessment with marks
--NNG 2007-08
select assessment_agg(5); --2nd 20th day
select assessment_agg(6);--3rd 20th day
select assessment_agg(7);--4th 20th day
select assessment_agg(8);--5th 20th day
select assessment_agg(9);--2nd 60th day
select assessment_agg(10);--3rd 60th day
select assessment_agg(11);--4th 60th day
select assessment_agg(12);--5th 60th day


--NNG 2008-09
select assessment_agg(13);--2nd 20th day
select assessment_agg(14);--3rd 20th day
select assessment_agg(15);--4th 20th day
select assessment_agg(16);--5th 20th day
select assessment_agg(17);--2nd 60th day
select assessment_agg(18);--3rd 60th day
select assessment_agg(19);--4th 60th day
select assessment_agg(20);--5th 60th day

--English 2009-2010
select assessment_agg(25);--Pre test
select assessment_agg(26);--Post test

--NNG3 2009-2010
select assessment_agg(33);--Pre test
select assessment_agg(34);--Post test

--Ramnagara NNG1 2009-2010
select assessment_agg(35);--Pre test
select assessment_agg(36);--Post test

--Ramnagara NNG2 2009-2010
select assessment_agg(37);--Pre test
select assessment_agg(38);--Post test

--Target NNG 2009-2010
select assessment_agg(39);--NNG2

--NNGSupport 2010-2011
select assessment_agg(41);--4th blore pre test
select assessment_agg(42);--4th blore post test
select assessment_agg(43);--5th blore pre test
select assessment_agg(44);--5th blore post test
select assessment_agg(45);--4th gul pre test
select assessment_agg(46);--4th gul post test
select assessment_agg(47);--5th gul pre test
select assessment_agg(48);--5th gul post test


--NNG10by10 2010-2011
select assessment_agg(51);--4th pre test
select assessment_agg(52);--4th post test
select assessment_agg(53);--5th pre test
select assessment_agg(54);--5th post test


GRANT SELECT ON tb_school_agg,
                tb_school_assessment_agg,
                tb_school_weighted_assessment_agg
TO web;
