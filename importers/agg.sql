-- Aggregation tables

DROP TABLE IF EXISTS "tb_institution_agg";
CREATE TABLE "tb_institution_agg" (
  "id" integer REFERENCES "tb_school" ("id") ON DELETE CASCADE,
  "name" varchar(300),
  "bid" integer REFERENCES "tb_boundary" ("id") ON DELETE CASCADE,
  "sex" sex,
  "mt" school_moi,
  "num" integer
);


DROP TABLE IF EXISTS "tb_institution_basic_assessment_info";
CREATE TABLE "tb_institution_basic_assessment_info" (
  "sid" integer REFERENCES "tb_school" ("id") ON DELETE CASCADE,
  "assid" integer REFERENCES "tb_assessment" ("id") ON DELETE CASCADE,
  "studentgroup" varchar(50),
  "sex" sex,
  "mt" school_moi,
  "num" integer
);


DROP TABLE IF EXISTS "tb_institution_assessment_agg";
CREATE TABLE "tb_institution_assessment_agg" (
  "sid" integer REFERENCES "tb_school" ("id") ON DELETE CASCADE,
  "assid" integer REFERENCES "tb_assessment" ("id") ON DELETE CASCADE,
  "studentgroup" varchar(50),
  "sex" sex,
  "mt" school_moi,
  "domain" varchar(100),
  "domain_order" integer,
  "aggtext" varchar(100) NOT NULL,
  "aggtext_order" integer NOT NULL,
  "aggval" numeric(6,2) DEFAULT 0
);


drop function agg_institution(int);
CREATE OR REPLACE function agg_institution(int) returns void as $$
declare
        schs RECORD;
begin
        for schs in SELECT s.id as id, s.name as name, s.bid as bid, c.sex as sex, c.mt as mt, count(stu.id) AS count
                 FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s
                 WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND sc.status=1 AND stu.cid = c.id AND sc.ayid = $1
                 GROUP BY s.id, s.name, s.bid, c.sex, c.mt 
        loop
                insert into tb_institution_agg values (schs.id, schs.name, schs.bid, schs.sex, schs.mt, schs.count);
        end loop;
end;
$$ language plpgsql;


DROP FUNCTION basic_assess_school(int,int);
CREATE OR REPLACE function basic_assess_school(int,int) returns void as $$
declare
        schs RECORD;
begin
        for schs in SELECT s.id as id,ass.id as assid,cl.name as clname,c.sex as sex, c.mt as mt, count(distinct stu.id) AS count
                 FROM tb_student_eval se,tb_question q,tb_assessment ass,tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s,tb_programme p,tb_boundary b 
                 WHERE se.stuid=stu.id and se.qid=q.id and q.assid=ass.id and ass.pid=p.id and sc.stuid=stu.id and sc.clid=cl.id AND cl.sid = s.id AND stu.cid = c.id AND sc.ayid = $1 and ass.id=$2 and sc.ayid=p.ayid and s.bid=b.id and p.type=b.type and (se.grade is not null or se.mark is not null)
                 GROUP BY s.id, ass.id,cl.id,c.sex,c.mt
        loop
                insert into tb_institution_basic_assessment_info values (schs.id, schs.assid, schs.clname ,schs.sex, schs.mt, schs.count);
        end loop;
end;
$$ language plpgsql;


DROP FUNCTION basic_assess_preschool_morethan(inayid int,inassid int,inage int,intext text,intimestamp timestamp);
CREATE OR REPLACE function basic_assess_preschool_morethan(inayid int,inassid int,inage int,intext text,intimestamp timestamp) returns void as $$
declare
        schs RECORD;
begin
        for schs in SELECT s.id as id,ass.id as assid,c.sex as sex, c.mt as mt, count(distinct stu.id) AS count
                 FROM tb_student_eval se,tb_question q,tb_assessment ass,tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s,tb_programme p,tb_boundary b 
                 WHERE se.stuid=stu.id and se.qid=q.id and q.assid=ass.id and ass.pid=p.id and sc.stuid=stu.id and sc.clid=cl.id AND cl.sid = s.id AND stu.cid = c.id AND sc.ayid = inayid and ass.id=inassid and sc.ayid=p.ayid and s.bid=b.id and p.type=b.type and (extract(year from age(intimestamp,c.dob))*12+extract(month from age(intimestamp,c.dob)))>=inage
                 GROUP BY s.id, ass.id,c.sex,c.mt
        loop
                insert into tb_institution_basic_assessment_info values (schs.id, schs.assid,intext,schs.sex, schs.mt, schs.count);
        end loop;
end;
$$ language plpgsql;


DROP FUNCTION basic_assess_preschool_between(inayid int,inassid int,inlowerage int,inupperage int,intext text,intimestamp timestamp);
CREATE OR REPLACE function basic_assess_preschool_between(inayid int,inassid int,inlowerage int,inupperage int,intext text,intimestamp timestamp) returns void as $$
declare
        schs RECORD;
begin
        for schs in SELECT s.id as id,ass.id as assid,c.sex as sex, c.mt as mt, count(distinct stu.id) AS count
                 FROM tb_student_eval se,tb_question q,tb_assessment ass,tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s,tb_programme p,tb_boundary b 
                 WHERE se.stuid=stu.id and se.qid=q.id and q.assid=ass.id and ass.pid=p.id and sc.stuid=stu.id and sc.clid=cl.id AND cl.sid = s.id AND stu.cid = c.id AND sc.ayid = inayid and ass.id=inassid and sc.ayid=p.ayid and s.bid=b.id and p.type=b.type and (extract(year from age(intimestamp,c.dob))*12+extract(month from age(intimestamp,c.dob)))<inupperage and (extract(year from age(intimestamp,c.dob))*12+extract(month from age(intimestamp,c.dob)))>=inlowerage
                 GROUP BY s.id, ass.id,c.sex,c.mt
        loop
                insert into tb_institution_basic_assessment_info values (schs.id, schs.assid,intext,schs.sex, schs.mt, schs.count);
        end loop;
end;
$$ language plpgsql;


DROP FUNCTION agg_school_reading(inassessid int, inayid int);
CREATE OR REPLACE function agg_school_reading(inassessid int, inayid int) returns void as $$
declare
        stueval RECORD;
begin
        for stueval in SELECT s.id as id, ass.id as assid, cl.name as clname, c.sex as sex, c.mt as mt, 
        count(case when se.grade='O' then stu.id else null end) as Ocount,
        count(case when se.grade='L' then stu.id else null end) as Lcount,
        count(case when se.grade='W' then stu.id else null end) as Wcount,
        count(case when se.grade='S' then stu.id else null end) as Scount,
        count(case when se.grade='P' then stu.id else null end) as Pcount,
        cast(count(distinct stu.id) as float) as cnt
                       FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se,tb_question q, tb_assessment ass, tb_programme p,tb_boundary b
                       WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid= ass.id AND ass.pid=p.id AND  sc.ayid=p.ayid AND ass.id = inassessid AND sc.ayid = inayid
                        AND se.grade IS NOT NULL AND s.bid=b.id and p.type=b.type
                       GROUP BY s.id, ass.id, cl.name, c.sex, c.mt, se.grade
        loop
                insert into tb_institution_assessment_agg values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'O',0,stueval.Ocount);
                insert into tb_institution_assessment_agg values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'L',1,stueval.Lcount);
                insert into tb_institution_assessment_agg values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'W',2,stueval.Wcount);
                insert into tb_institution_assessment_agg values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'S',3,stueval.Scount);
                insert into tb_institution_assessment_agg values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'P',4,stueval.PCount);
        end loop;
end;
$$ language plpgsql;


DROP FUNCTION agg_school_nng(inassessid int, inayid int);
CREATE OR REPLACE function agg_school_nng(inassessid int, inayid int) returns void as $$
declare
        stueval RECORD;
begin

        for stueval in 
        SELECT id, assid,clname,sex,mt,
        count(case when mark < 20 then id else null end) as Rung1, 
        count(case when mark between 20 and 40 then id else null end) as Rung2,
        count(case when mark between 40 and 60 then id else null end) as Rung3,
        count(case when mark between 60 and 80 then id else null end) as Rung4,
        count(case when mark > 80 then id else null end) as Rung5
        FROM ( SELECT se.stuid,s.id as id, ass.id as assid, cl.name as clname, c.sex as sex, c.mt as mt, avg(se.mark/q.maxmarks*100) as mark 
               FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass,tb_question q,tb_programme p,tb_boundary b  
               WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid = ass.id AND ass.pid=p.id AND sc.ayid=p.ayid AND ass.id = inassessid AND sc.ayid =inayid  AND s.bid=b.id and p.type=b.type
               GROUP BY s.id, ass.id, cl.name, c.sex, c.mt,se.stuid ) as output 
        GROUP BY id,assid,clname,sex,mt
        loop
               insert into tb_institution_assessment_agg values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung1',0, stueval.Rung1);
               insert into tb_institution_assessment_agg values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung2',1, stueval.Rung2);
               insert into tb_institution_assessment_agg values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung3',2,stueval.Rung3);
               insert into tb_institution_assessment_agg values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung4',3, stueval.Rung4);
               insert into tb_institution_assessment_agg values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung5',4, stueval.Rung5);
        end loop;

end;
$$ language plpgsql;


DROP FUNCTION agg_school_assess_grade_eng(inyear int,inclass text, inassid int,indomains varchar[] ,indomainsposition integer[], inqset varchar[], inpmarks int[],innum int);
CREATE OR REPLACE function agg_school_assess_grade_eng(inyear int,inclass text, inassid int,indomains varchar[] ,indomainsposition integer[], inqset varchar[], inpmarks int[],innum int) returns void as $$
declare
  stueval RECORD;
  rung1 text;
  rung2 text;
  rung3 text;
  rung4 text;
begin
  for domaincount in 0..innum
    loop
    rung1 :='0-25%';
    rung2 :='25-50%';
    rung3 :='50-75%';
    rung4 :='75-100%';
      for stueval in
        SELECT sid, assid,clname,sex,mt, count(case when percentile<= 25 then stuid else null end) as Rung1,
        count(case when percentile between 26 and 50 then stuid else null end) as Rung2,
        count(case when percentile between 51 and 75 then stuid else null end) as Rung3,
        count(case when percentile between 76 and 100 then stuid else null end) as Rung4
        from
        (          select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clname as clname , c.sex as sex,c.mt as mt,  (domainagg*100/inpmarks[domaincount]) as percentile          from
          (            select se.stuid as stuid,
              q.assid as assid,              sg.name as clname,
              sg.sid as sid,
              sum(cast(se.grade as int))  as domainagg
            from tb_student_eval se,tb_question q,tb_student_class stusg,tb_class sg
            where
              se.qid=q.id
              and q.assid=inassid
              and q.desc= ANY(string_to_array(inqset[domaincount],','))
              and se.stuid=stusg.stuid
              and se.grade is not null
              and stusg.ayid=inyear
              and stusg.clid=sg.id              and sg.name=inclass            group by se.stuid,q.assid,sg.id,sg.sid
          ) aggregates, tb_child c,tb_student stu          where
            aggregates.stuid=stu.id
            and stu.cid=c.id)info          group by sid,assid,clname,sex,mt        loop
          insert into tb_institution_assessment_agg values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,indomains[domaincount],indomainsposition[domaincount],rung1, 0,stueval.Rung1);
          insert into tb_institution_assessment_agg values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,indomains[domaincount],indomainsposition[domaincount],rung2, 1,stueval.Rung2);
          insert into tb_institution_assessment_agg values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,indomains[domaincount],indomainsposition[domaincount],rung3, 2,stueval.Rung3);
          insert into tb_institution_assessment_agg values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,indomains[domaincount],indomainsposition[domaincount],rung4, 3,stueval.Rung4);
        end loop;
   end loop;
end;
$$ language plpgsql;


DROP FUNCTION agg_school_ang_agemorethan(inyear int,inage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp);
CREATE OR REPLACE function agg_school_ang_agemorethan(inyear int,inage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 0..innum loop
      raise notice 'domaincount is %',domaincount;
      for stueval in
        SELECT sid, assid,sex,mt, count(case when domainskillcount =1 then stuid else null end) as stucount
        from
        (
          select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clid as clid, 
          aggregates.sex as sex,aggregates.mt as mt,  case when domainagg <inpmarks[domaincount] then 0 else 1 end as domainskillcount
          from
          (  
            select se.stuid as stuid,
              q.assid as assid,
              sg.id as clid,
              sg.sid as sid,
              c.sex as sex,
              c.mt as mt,
              sum(cast(se.grade as int))  as domainagg
            from tb_student_eval se,tb_question q,tb_student stu,tb_student_class stusg,tb_class sg,tb_child c
            where
              se.qid=q.id
              and q.assid=inassid
              and q.desc= ANY(string_to_array(inqset[domaincount],','))
              and se.stuid=stusg.stuid
              and stusg.ayid=inyear
              and stusg.clid=sg.id
              and stu.id=se.stuid
              and stu.cid=c.id
              and (extract(year from age(intimestamp,c.dob))*12+extract(month from age(intimestamp,c.dob)))>=inage
            group by se.stuid,q.assid,sg.id,sg.sid,c.sex,c.mt
          ) aggregates
          group by sid,assid,clid,sex,mt,stuid,domainagg
        )info group by sid, assid,sex,mt
        loop
          insert into tb_institution_assessment_agg values (stueval.sid, stueval.assid,intext, stueval.sex, stueval.mt,'',0,indomains[domaincount],domaincount-1, stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;


DROP FUNCTION agg_school_ang_agebetween(inyear int,inlowerage int,inupperage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp);
CREATE OR REPLACE function agg_school_ang_agebetween(inyear int,inlowerage int,inupperage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 0..innum loop
      for stueval in
        SELECT sid, assid,sex,mt, count(case when domainskillcount =1 then stuid else null end) as stucount
        from
        (
          select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clid as clid, aggregates.sex as sex,aggregates.mt as mt,  case when domainagg <inpmarks[domaincount] then 0 else 1 end as domainskillcount
          from
          (  
            select se.stuid as stuid,
              q.assid as assid,
              sg.id as clid,
              sg.sid as sid,
              c.sex as sex,
              c.mt as mt,
              sum(cast(se.grade as int))  as domainagg
            from tb_student_eval se,tb_question q,tb_student stu,tb_student_class stusg,tb_class sg,tb_child c
            where
              se.qid=q.id
              and q.assid=inassid
              and q.desc= ANY(string_to_array(inqset[domaincount],','))
              and se.stuid=stusg.stuid
              and stusg.ayid=inyear
              and stusg.clid=sg.id
              and stu.id=se.stuid
              and stu.cid=c.id
              and (extract(year from age(intimestamp,c.dob))*12+extract(month from age(intimestamp,c.dob)))<inupperage
              and (extract(year from age(intimestamp,c.dob))*12+extract(month from age(intimestamp,c.dob)))>=inlowerage
            group by se.stuid,q.assid,sg.id,sg.sid,c.sex,c.mt
          ) aggregates
          group by sid,assid,clid,sex,mt,stuid,domainagg
        )info group by sid,assid,sex,mt
        loop
          insert into tb_institution_assessment_agg values (stueval.sid, stueval.assid,intext, stueval.sex, stueval.mt,'',0,indomains[domaincount],domaincount-1, stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;


DROP FUNCTION agg_school_assess_mark(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int);
CREATE OR REPLACE function agg_school_assess_mark(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 0..innum
    loop
      for stueval in
        SELECT sid, assid,clname,sex,mt, count(case when domainskillcount =1 then stuid else null end) as stucount
        from
        (
          select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clname as clname, c.sex as sex,c.mt as mt,  case when domainagg <inpmarks[domaincount] then 0 else 1 end as domainskillcount
          from
          (  
            select se.stuid as stuid,
              q.assid as assid,
              sg.name as clname,
              sg.sid as sid,
              sum(cast(se.mark as int))  as domainagg
            from tb_student_eval se,tb_question q,tb_student_class stusg,tb_class sg
            where
              se.qid=q.id
              and q.assid=inassid
              and q.desc= ANY(string_to_array(inqset[domaincount],','))
              and se.stuid=stusg.stuid
              and stusg.ayid=inyear
              and stusg.clid=sg.id
              and sg.name=inclass
            group by se.stuid,q.assid,sg.id,sg.sid
          ) aggregates, tb_child c,tb_student stu
          where
            aggregates.stuid=stu.id
            and stu.cid=c.id)info           
          group by sid,assid,clname,sex,mt
        loop
          insert into tb_institution_assessment_agg values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,indomains[domaincount],domaincount, stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;



DROP FUNCTION agg_school_assess_grade(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int);
CREATE OR REPLACE function agg_school_assess_grade(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 0..innum
    loop
      for stueval in
        SELECT sid, assid,clname,sex,mt, count(case when domainskillcount =1 then stuid else null end) as stucount
        from
        (
          select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clname as clname, c.sex as sex,c.mt as mt,  case when domainagg <inpmarks[domaincount] then 0 else 1 end as domainskillcount
          from
          (  
            select se.stuid as stuid,
              q.assid as assid,
              sg.name as clname,
              sg.sid as sid,
              sum(cast(se.grade as int))  as domainagg
            from tb_student_eval se,tb_question q,tb_student_class stusg,tb_class sg
            where
              se.qid=q.id
              and q.assid=inassid
              and q.desc= ANY(string_to_array(inqset[domaincount],','))
              and se.stuid=stusg.stuid
              and stusg.ayid=inyear
              and stusg.clid=sg.id
              and sg.name=inclass
            group by se.stuid,q.assid,sg.id,sg.sid
          ) aggregates, tb_child c,tb_student stu
          where
            aggregates.stuid=stu.id
            and stu.cid=c.id)info           
          group by sid,assid,clname,sex,mt
        loop
          insert into tb_institution_assessment_agg values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,indomains[domaincount],domaincount, stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;


-- Populate tb_school_agg for the current academic year
select agg_institution(101);

--Populate all years basic info
select basic_assess_school(90,1);
select basic_assess_school(90,2);
select basic_assess_school(90,3);
select basic_assess_school(90,4);
select basic_assess_school(1,5);
select basic_assess_school(1,6);
select basic_assess_school(1,7);
select basic_assess_school(1,8);
select basic_assess_school(1,9);
select basic_assess_school(1,10);
select basic_assess_school(1,11);
select basic_assess_school(1,12);
select basic_assess_school(2,13);
select basic_assess_school(2,14);
select basic_assess_school(2,15);
select basic_assess_school(2,16);
select basic_assess_school(2,17);
select basic_assess_school(2,18);
select basic_assess_school(2,19);
select basic_assess_school(2,20);
select basic_assess_school(2,21);
select basic_assess_school(2,22);
select basic_assess_school(119,25);
select basic_assess_school(119,26);
select basic_assess_school(119,27);
select basic_assess_school(119,28);
select basic_assess_school(119,29);
select basic_assess_school(119,30);
select basic_assess_school(119,31);
select basic_assess_school(119,32);
select basic_assess_school(119,33);
select basic_assess_school(119,34);
select basic_assess_school(119,35);
select basic_assess_school(119,36);
select basic_assess_school(119,37);
select basic_assess_school(119,38);
select basic_assess_school(119,39);
select basic_assess_school(119,40);
select basic_assess_school(101,41);
select basic_assess_school(101,42);
select basic_assess_school(101,43);
select basic_assess_school(101,44);
select basic_assess_school(101,45);
select basic_assess_school(101,46);
select basic_assess_school(101,47);
select basic_assess_school(101,48);
select basic_assess_school(101,49);
select basic_assess_school(101,50);
select basic_assess_school(101,59);
select basic_assess_school(101,60);
select basic_assess_school(101,61);
select basic_assess_school(102,65);
select basic_assess_school(102,66);
select basic_assess_school(102,67);
select basic_assess_school(102,68);
select basic_assess_school(102,69);
select basic_assess_school(102,71);
select basic_assess_school(102,73);
select basic_assess_school(102,74);
select basic_assess_school(102,75);
select basic_assess_school(102,76);
select basic_assess_school(102,77);
select basic_assess_school(102,78);
select basic_assess_school(102,81);
select basic_assess_school(102,82);
select basic_assess_school(102,83);
select basic_assess_school(102,84);
select basic_assess_school(102,85);
select basic_assess_school(102,86);
select basic_assess_school(102,87);
select basic_assess_school(102,88);
select basic_assess_school(102,89);
select basic_assess_school(102,90);
select basic_assess_school(102,91);
select basic_assess_school(102,92);
select basic_assess_school(102,93);
select basic_assess_school(102,94);
select basic_assess_school(102,95);
select basic_assess_school(102,96);
select basic_assess_school(102,97);
select basic_assess_school(102,98);
select basic_assess_school(102,99);
select basic_assess_school(102,100);
select basic_assess_school(102,101);
select basic_assess_school(102,102);
select basic_assess_school(102,103);
select basic_assess_school(102,104);
select basic_assess_school(102,105);
select basic_assess_school(102,106);
select basic_assess_school(102,107);
select basic_assess_school(102,108);
select basic_assess_school(102,109);
select basic_assess_school(102,110);


--Preschool basic assessessment
select basic_assess_preschool_between(119,23,36,60,'Age between 3-5',cast('2009-04-30' as timestamp));
select basic_assess_preschool_morethan(119,23,60,'Age >=5',cast('2009-04-30'as timestamp));
select basic_assess_preschool_between(119,24,36,60,'Age between 3-5',cast('2009-04-30' as timestamp));
select basic_assess_preschool_morethan(119,24,60,'Age >=5',cast('2009-04-30' as timestamp));
select basic_assess_preschool_between(101,56,36,60,'Age between 3-5',cast('2010-04-30' as timestamp));
select basic_assess_preschool_morethan(101,56,60,'Age >=5',cast('2010-04-30' as timestamp));
select basic_assess_preschool_between(101,57,36,60,'Age between 3-5',cast('2010-04-30' as timestamp));
select basic_assess_preschool_morethan(101,57,60,'Age >=5',cast('2010-04-30' as timestamp));
select basic_assess_preschool_between(102,70,36,60,'Age between 3-5',cast('2011-04-30' as timestamp));
select basic_assess_preschool_morethan(102,70,60,'Age >=5',cast('2011-04-30' as timestamp));
select basic_assess_preschool_between(102,79,36,60,'Age between 3-5',cast('2011-04-30' as timestamp));
select basic_assess_preschool_morethan(102,79,60,'Age >=5',cast('2011-04-30' as timestamp));

-- 2006 Reading
select agg_school_reading(1, 90);
select agg_school_reading(2, 90);
select agg_school_reading(3, 90);
select agg_school_reading(4, 90);

-- 2009 Reading
select agg_school_reading(27, 119);
select agg_school_reading(28, 119);
select agg_school_reading(29, 119);
select agg_school_reading(30, 119);
select agg_school_reading(31, 119);
select agg_school_reading(32, 119);


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


--2010 NNG
select agg_school_nng(41,101);
select agg_school_nng(42,101);
select agg_school_nng(43,101);
select agg_school_nng(44,101);
select agg_school_nng(45,101);
select agg_school_nng(46,101);
select agg_school_nng(47,101);
select agg_school_nng(48,101);

--Anganwadi
-- 2009 Anganwadi
--Pretest
select agg_school_ang_agebetween(119,36,60,23,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2009-04-30' as timestamp));
select agg_school_ang_agemorethan(119,60,23,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2009-04-30' as timestamp));

--Posttest
select agg_school_ang_agebetween(119,36,60,24,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2009-04-30' as timestamp));
select agg_school_ang_agemorethan(119,60,24,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2009-04-30' as timestamp));

-- 2010 Anganwadi
--Pretest
select agg_school_ang_agebetween(101,36,60,56,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2010-04-30' as timestamp));
select agg_school_ang_agemorethan(101,60,56,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2010-04-30' as timestamp));

--Posttest
select agg_school_ang_agebetween(101,36,60,57,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2010-04-30' as timestamp));
select agg_school_ang_agemorethan(101,60,57,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2010-04-30' as timestamp));


-- 2011 Anganwadi
--Pretest
select agg_school_ang_agebetween(102,36,60,70,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2010-04-30' as timestamp));
select agg_school_ang_agemorethan(102,60,70,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2010-04-30' as timestamp));

--Posttest
select agg_school_ang_agebetween(102,36,60,79,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2010-04-30' as timestamp));
select agg_school_ang_agemorethan(102,60,79,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2010-04-30' as timestamp));

--English
--2009 English
--Pretest 5
select agg_school_assess_mark(119,'5',25,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2);
select agg_school_assess_grade(119,'5',25,ARRAY['Can read simple passage','Can give one word  answer orally'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1);
--Posttest 5
select agg_school_assess_mark(119,'5',26,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2);
select agg_school_assess_grade(119,'5',26,ARRAY['Can read simple passage','Can give one word  answer orally'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1);


--Pretest 6
select agg_school_assess_mark(119,'6',25,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2);
select agg_school_assess_grade(119,'6',25,ARRAY['Can read simple passage','Can write one word  answers'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1);
--Posttest 6
select agg_school_assess_mark(119,'6',26,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2);
select agg_school_assess_grade(119,'6',26,ARRAY['Can read simple passage','Can write one word  answers'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1);


--2010 English
--Pretest 3
select agg_school_assess_grade(101,'3',49,ARRAY['Can write alphabets','Can follow simple instruction','Can give one word answer'],ARRAY['Eng1,Eng2','Eng6','Eng7'],ARRAY[2,1,1],2);
--Posttest 3
select agg_school_assess_grade(101,'3',50,ARRAY['Can write alphabets','Can follow simple instruction','Can give one word answer'],ARRAY['Eng1,Eng2','Eng6','Eng7'],ARRAY[2,1,1],2);

--Pretest 4
select agg_school_assess_grade(101,'4',49,ARRAY['Picture reading','Can answer in sentence','Can read a simple sentence'],ARRAY['Eng10','Eng8','Eng9'],ARRAY[1,1,1],2);
--Posttest 4
select agg_school_assess_grade(101,'4',50,ARRAY['Picture reading','Can answer in sentence','Can read a simple sentence'],ARRAY['Eng10','Eng8','Eng9'],ARRAY[1,1,1],2);



--2011-2012
--English
select agg_school_assess_grade_eng(102,'1',65,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'2',66,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'3',67,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);
select agg_school_assess_grade_eng(102,'1',75,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'2',76,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'3',77,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);



GRANT SELECT ON tb_institution_agg,
                tb_institution_assessment_agg,
                tb_institution_basic_assessment_info
TO web;
