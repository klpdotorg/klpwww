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

DROP TABLE IF EXISTS "tb_institution_basic_assessment_info_cohorts";
CREATE TABLE "tb_institution_basic_assessment_info_cohorts" (
  "sid" integer REFERENCES "tb_school" ("id") ON DELETE CASCADE,
  "assid" integer REFERENCES "tb_assessment" ("id") ON DELETE CASCADE,
  "studentgroup" varchar(50),
  "sex" sex,
  "mt" school_moi,
  "cohortsnum" integer
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


DROP TABLE IF EXISTS "tb_institution_assessment_agg_cohorts";
CREATE TABLE "tb_institution_assessment_agg_cohorts" (
  "sid" integer REFERENCES "tb_school" ("id") ON DELETE CASCADE,
  "assid" integer REFERENCES "tb_assessment" ("id") ON DELETE CASCADE,
  "studentgroup" varchar(50),
  "sex" sex,
  "mt" school_moi,
  "domain" varchar(100),
  "domain_order" integer,
  "aggtext" varchar(100) NOT NULL,
  "aggtext_order" integer NOT NULL,
  "cohortsval" numeric(6,2) DEFAULT 0
);

drop function agg_institution(int);
CREATE OR REPLACE function agg_institution(int) returns void as $$
declare
        schs RECORD;
begin
        for schs in SELECT s.id as id, s.name as name, s.bid as bid, c.sex as sex, c.mt as mt, count(distinct stu.id) AS count
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
        for schs in SELECT s.id as id,ass.id as assid,cl.name as clname,c.sex as sex, c.mt as mt, count(distinct stu.id) AS count FROM tb_student_eval se,tb_question q,tb_assessment ass,tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s,tb_programme p,tb_boundary b WHERE se.stuid=stu.id and se.qid=q.id and q.assid=ass.id and ass.pid=p.id and sc.stuid=stu.id and sc.clid=cl.id AND cl.sid = s.id AND stu.cid = c.id AND sc.ayid = $1 and ass.id=$2 and sc.ayid=p.ayid and s.bid=b.id and p.type=b.type and (se.grade is not null or se.mark is not null) GROUP BY s.id, ass.id,cl.id,c.sex,c.mt 
        loop
                insert into tb_institution_basic_assessment_info values (schs.id, schs.assid, schs.clname ,schs.sex, schs.mt, schs.count);
        end loop;
end;
$$ language plpgsql;


DROP FUNCTION basic_assess_school_cohorts(int,int,int[]);
CREATE OR REPLACE function basic_assess_school_cohorts(int,int,inallassid int[]) returns void as $$
declare
        schs RECORD;
        query text;
begin
        query:='SELECT s.id as id,ass.id as assid,cl.name as clname,c.sex as sex, c.mt as mt, count(distinct stu.id) AS count FROM tb_student_eval se,tb_question q,tb_assessment ass,tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s,tb_programme p,tb_boundary b WHERE se.stuid=stu.id and se.qid=q.id and q.assid=ass.id and ass.pid=p.id and sc.stuid=stu.id and sc.clid=cl.id AND cl.sid = s.id AND stu.cid = c.id AND sc.ayid ='|| $1||' and ass.id='||$2||' and sc.ayid=p.ayid and s.bid=b.id and p.type=b.type and (se.grade is not null or se.mark is not null)';
        FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
        loop
          query:= query||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and (se.grade is not null or se.mark is not null) and q.assid = '||inallassid[i]||')';
        end loop;
        query=query||'GROUP BY s.id, ass.id,cl.id,c.sex,c.mt'; 
        for schs in execute query
        loop
          insert into tb_institution_basic_assessment_info_cohorts values (schs.id, schs.assid, schs.clname ,schs.sex, schs.mt, schs.count);
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


DROP FUNCTION basic_assess_preschool_morethan_cohorts(inayid int,inassid int,inage int,intext text,intimestamp timestamp,inallassid int[]);
CREATE OR REPLACE function basic_assess_preschool_morethan_cohorts(inayid int,inassid int,inage int,intext text,intimestamp timestamp,inallassid int[]) returns void as $$
declare
        schs RECORD;
        query text;
begin
        query:='SELECT s.id as id,ass.id as assid,c.sex as sex, c.mt as mt, count(distinct stu.id) AS count FROM tb_student_eval se,tb_question q,tb_assessment ass,tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s,tb_programme p,tb_boundary b WHERE se.stuid=stu.id and se.qid=q.id and q.assid=ass.id and ass.pid=p.id and sc.stuid=stu.id and sc.clid=cl.id AND cl.sid = s.id AND stu.cid = c.id AND sc.ayid = '||inayid||' and ass.id='||inassid||' and sc.ayid=p.ayid and s.bid=b.id and p.type=b.type and se.grade is not null and (extract(year from age('''||intimestamp||''',c.dob))*12+extract(month from age('''||intimestamp||''',c.dob)))>='||inage;
        FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
        loop
          query:= query||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and se.grade is not null and q.assid = '||inallassid[i]||')';
        end loop;
         
        query:=query||'GROUP BY s.id, ass.id,c.sex,c.mt';
        for schs in execute query
        loop
          insert into tb_institution_basic_assessment_info_cohorts values (schs.id, schs.assid,intext,schs.sex, schs.mt, schs.count);
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


DROP FUNCTION basic_assess_preschool_between_cohorts(inayid int,inassid int,inlowerage int,inupperage int,intext text,intimestamp timestamp,inallassid int[]);
CREATE OR REPLACE function basic_assess_preschool_between_cohorts(inayid int,inassid int,inlowerage int,inupperage int,intext text,intimestamp timestamp,inallassid int[]) returns void as $$
declare
        schs RECORD;
        query text;
begin
        query:='SELECT s.id as id,ass.id as assid,c.sex as sex, c.mt as mt, count(distinct stu.id) AS count FROM tb_student_eval se,tb_question q,tb_assessment ass,tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s,tb_programme p,tb_boundary b WHERE se.stuid=stu.id and se.qid=q.id and q.assid=ass.id and ass.pid=p.id and sc.stuid=stu.id and sc.clid=cl.id AND cl.sid = s.id AND stu.cid = c.id AND sc.ayid = '||inayid||' and ass.id='||inassid||' and sc.ayid=p.ayid and s.bid=b.id and p.type=b.type and (extract(year from age('''||intimestamp||''',c.dob))*12+extract(month from age('''||intimestamp||''',c.dob)))<'||inupperage||' and se.grade is not null and (extract(year from age('''||intimestamp||''',c.dob))*12+extract(month from age('''||intimestamp||''',c.dob)))>='||inlowerage;
        FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
        loop
          query:= query||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and se.grade is not null and q.assid = '||inallassid[i]||')';
        end loop;
        query:=query||' GROUP BY s.id, ass.id,c.sex,c.mt';
        for schs in execute query
        loop
                insert into tb_institution_basic_assessment_info_cohorts values (schs.id, schs.assid,intext,schs.sex, schs.mt, schs.count);
        end loop;
end;
$$ language plpgsql;


DROP FUNCTION agg_school_reading(inassessid int, inayid int);
CREATE OR REPLACE function agg_school_reading(inassessid int, inayid int) returns void as $$
declare
        stueval RECORD;
begin
        for stueval in SELECT s.id as id, ass.id as assid, cl.name as clname, c.sex as sex, c.mt as mt, 
        count(distinct case when se.grade='O' then stu.id else null end) as Ocount,
        count(distinct case when se.grade='L' then stu.id else null end) as Lcount,
        count(distinct case when se.grade='W' then stu.id else null end) as Wcount,
        count(distinct case when se.grade='S' then stu.id else null end) as Scount,
        count(distinct case when se.grade='P' then stu.id else null end) as Pcount,
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

DROP FUNCTION agg_school_reading_cohorts(inassessid int, inayid int,inallassid int[]);
CREATE OR REPLACE function agg_school_reading_cohorts(inassessid int, inayid int,inallassid int[]) returns void as $$
declare
        stueval RECORD;
        andcondition text;
begin
        andcondition:='SELECT s.id as id, ass.id as assid, cl.name as clname, c.sex as sex, c.mt as mt, count(distinct case when se.grade=''O'' then stu.id else null end) as Ocount, count(distinct case when se.grade=''L'' then stu.id else null end) as Lcount, count(distinct case when se.grade=''W'' then stu.id else null end) as Wcount, count(distinct case when se.grade=''S'' then stu.id else null end) as Scount, count(distinct case when se.grade=''P'' then stu.id else null end) as Pcount, cast(count(distinct stu.id) as float) as cnt FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se,tb_question q, tb_assessment ass, tb_programme p,tb_boundary b WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid= ass.id AND ass.pid=p.id AND  sc.ayid=p.ayid AND ass.id ='||inassessid||' AND sc.ayid = '||inayid||' AND se.grade IS NOT NULL AND s.bid=b.id and p.type=b.type';
        FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
        loop
          andcondition := andcondition||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and se.grade is not null and q.assid = '||inallassid[i]||')';
        end loop;
        andcondition:= andcondition||'GROUP BY s.id, ass.id, cl.name, c.sex, c.mt, se.grade';
        for stueval in execute andcondition
        loop
                insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'O',0,stueval.Ocount);
                insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'L',1,stueval.Lcount);
                insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'W',2,stueval.Wcount);
                insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'S',3,stueval.Scount);
                insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'P',4,stueval.PCount);
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
        count(distinct case when mark <= 20 then stuid else null end) as Rung1, 
        count(distinct case when mark>20 and mark<=40 then stuid else null end) as Rung2,
        count(distinct case when mark>40 and mark<=60 then stuid else null end) as Rung3,
        count(distinct case when mark>60 and mark<=80 then stuid else null end) as Rung4,
        count(distinct case when mark>80 then stuid else null end) as Rung5
        FROM ( SELECT se.stuid as stuid,s.id as id, ass.id as assid, cl.name as clname, c.sex as sex, c.mt as mt, avg(se.mark/q.maxmarks*100) as mark 
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



DROP FUNCTION agg_school_nng_grade(inassessid int, inayid int,inmaxmarks int);
CREATE OR REPLACE function agg_school_nng_grade(inassessid int, inayid int,inmaxmarks int) returns void as $$
declare
        stueval RECORD;
begin

        for stueval in 
        SELECT id, assid,clname,sex,mt,
        count(distinct case when mark < 21 then stuid else null end) as Rung1, 
        count(distinct case when mark between 21 and 40 then stuid else null end) as Rung2,
        count(distinct case when mark between 41 and 60 then stuid else null end) as Rung3,
        count(distinct case when mark between 61 and 80 then stuid else null end) as Rung4,
        count(distinct case when mark > 80 then stuid else null end) as Rung5
        FROM ( SELECT se.stuid as stuid,s.id as id, ass.id as assid, cl.name as clname, c.sex as sex, c.mt as mt, sum(cast(se.grade as integer))*100/inmaxmarks as mark 
               FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass,tb_question q,tb_programme p,tb_boundary b  
               WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid = ass.id AND ass.pid=p.id AND sc.ayid=p.ayid AND ass.id = inassessid AND sc.ayid =inayid  AND s.bid=b.id and p.type=b.type and se.grade is not null
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

DROP FUNCTION agg_school_nng_cohorts(inassessid int, inayid int,inallassid int[]);
CREATE OR REPLACE function agg_school_nng_cohorts(inassessid int, inayid int,inallassid int[]) returns void as $$
declare
        stueval RECORD;
        andcondition text;
begin
        andcondition:='SELECT id, assid,clname,sex,mt,
        count(distinct case when mark < 21 then stuid else null end) as Rung1, 
        count(distinct case when mark between 21 and 40 then stuid else null end) as Rung2,
        count(distinct case when mark between 41 and 60 then stuid else null end) as Rung3,
        count(distinct case when mark between 61 and 80 then stuid else null end) as Rung4,
        count(distinct case when mark > 80 then stuid else null end) as Rung5
        FROM ( SELECT se.stuid as stuid,s.id as id, ass.id as assid, cl.name as clname, c.sex as sex, c.mt as mt, avg(se.mark*100/q.maxmarks) as mark 
               FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass,tb_question q,tb_programme p,tb_boundary b  
               WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid = ass.id AND ass.pid=p.id AND sc.ayid=p.ayid AND ass.id ='||inassessid||' AND sc.ayid ='||inayid||'  AND s.bid=b.id and p.type=b.type
';
        FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
        loop
          andcondition := andcondition||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and q.assid = '||inallassid[i]||')';
        end loop;
        andcondition:= andcondition||'GROUP BY s.id, ass.id, cl.name, c.sex, c.mt,se.stuid ) as output GROUP BY id,assid,clname,sex,mt';
        for stueval in execute andcondition
        loop
               insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung1',0, stueval.Rung1);
               insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung2',1, stueval.Rung2);
               insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung3',2,stueval.Rung3);
               insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung4',3, stueval.Rung4);
               insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung5',4, stueval.Rung5);
        end loop;

end;
$$ language plpgsql;



DROP FUNCTION agg_school_nng_grade_cohorts(inassessid int, inayid int,inallassid int[],inmaxmarks int);
CREATE OR REPLACE function agg_school_nng_grade_cohorts(inassessid int, inayid int,inallassid int[],inmaxmarks int) returns void as $$
declare
        stueval RECORD;
        andcondition text;
begin
        andcondition:='SELECT id, assid,clname,sex,mt,
        count(distinct case when mark < 21 then stuid else null end) as Rung1, 
        count(distinct case when mark between 21 and 40 then stuid else null end) as Rung2,
        count(distinct case when mark between 41 and 60 then stuid else null end) as Rung3,
        count(distinct case when mark between 61 and 80 then stuid else null end) as Rung4,
        count(distinct case when mark > 80 then stuid else null end) as Rung5
        FROM ( SELECT distinct se.stuid as stuid,s.id as id, ass.id as assid, cl.name as clname, c.sex as sex, c.mt as mt, sum(cast(se.grade as integer))*100/'||inmaxmarks||' as mark 
               FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass,tb_question q,tb_programme p,tb_boundary b  
               WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid = ass.id AND ass.pid=p.id AND sc.ayid=p.ayid AND ass.id ='||inassessid||' AND sc.ayid ='||inayid||'  AND s.bid=b.id and p.type=b.type and se.grade is not null
';
        FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
        loop
          andcondition := andcondition||' and se.stuid in (select distinct se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and se.grade is not null and q.assid = '||inallassid[i]||')';
        end loop;
        andcondition:= andcondition||'GROUP BY s.id, ass.id, cl.name, c.sex, c.mt,se.stuid ) as output GROUP BY id,assid,clname,sex,mt';
        for stueval in execute andcondition
        loop
               insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung1',0, stueval.Rung1);
               insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung2',1, stueval.Rung2);
               insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung3',2,stueval.Rung3);
               insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung4',3, stueval.Rung4);
               insert into tb_institution_assessment_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,'Rung5',4, stueval.Rung5);
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
  for domaincount in 1..innum
    loop
    rung1 :='0-25%';
    rung2 :='25-50%';
    rung3 :='50-75%';
    rung4 :='75-100%';
      for stueval in
        SELECT sid, assid,clname,sex,mt, count(distinct case when percentile<= 25 then stuid else null end) as Rung1,
        count(distinct case when percentile between 26 and 50 then stuid else null end) as Rung2,
        count(distinct case when percentile between 51 and 75 then stuid else null end) as Rung3,
        count(distinct case when percentile between 76 and 100 then stuid else null end) as Rung4
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



DROP FUNCTION agg_school_assess_grade_eng_cohorts(inyear int,inclass text, inassid int,indomains varchar[] ,indomainsposition integer[], inqset varchar[], inpmarks int[],innum int,inallassid int[]);
CREATE OR REPLACE function agg_school_assess_grade_eng_cohorts(inyear int,inclass text, inassid int,indomains varchar[] ,indomainsposition integer[], inqset varchar[], inpmarks int[],innum int,inallassid int[]) returns void as $$
declare
  stueval RECORD;
  rung1 text;
  rung2 text;
  rung3 text;
  rung4 text;
  andcondition text;
begin
  for domaincount in 1..innum
  loop
  andcondition:='SELECT sid, assid,clname,sex,mt, count(distinct case when percentile<= 25 then stuid else null end) as Rung1, count(distinct case when percentile between 26 and 50 then stuid else null end) as Rung2, count(distinct case when percentile between 51 and 75 then stuid else null end) as Rung3, count(distinct case when percentile between 76 and 100 then stuid else null end) as Rung4 from (          select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clname as clname , c.sex as sex,c.mt as mt,  (domainagg*100/'||inpmarks[domaincount]||') as percentile from (   select se.stuid as stuid, q.assid as assid,sg.name as clname, sg.sid as sid, sum(cast(se.grade as int))  as domainagg from tb_student_eval se,tb_question q,tb_student_class stusg,tb_class sg where se.qid=q.id and q.assid='||inassid||' and q.desc= ANY(string_to_array('''||inqset[domaincount]||''','','')) and se.stuid=stusg.stuid and se.grade is not null and stusg.ayid='||inyear||' and stusg.clid=sg.id and sg.name='''||inclass||'''';
  FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
  loop
    andcondition := andcondition||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and se.grade is not null and q.assid = '||inallassid[i]||')';
  end loop;
  andcondition:= andcondition||'group by se.stuid,q.assid,sg.id,sg.sid) aggregates, tb_child c,tb_student stu where aggregates.stuid=stu.id and stu.cid=c.id)info group by sid,assid,clname,sex,mt';
    rung1 :='0-25%';
    rung2 :='25-50%';
    rung3 :='50-75%';
    rung4 :='75-100%';
      for stueval in execute andcondition
              loop
          insert into tb_institution_assessment_agg_cohorts values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,indomains[domaincount],indomainsposition[domaincount],rung1, 0,stueval.Rung1);
          insert into tb_institution_assessment_agg_cohorts values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,indomains[domaincount],indomainsposition[domaincount],rung2, 1,stueval.Rung2);
          insert into tb_institution_assessment_agg_cohorts values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,indomains[domaincount],indomainsposition[domaincount],rung3, 2,stueval.Rung3);
          insert into tb_institution_assessment_agg_cohorts values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,indomains[domaincount],indomainsposition[domaincount],rung4, 3,stueval.Rung4);
        end loop;
   end loop;
end;
$$ language plpgsql;


DROP FUNCTION agg_school_ang_agemorethan(inyear int,inage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp);
CREATE OR REPLACE function agg_school_ang_agemorethan(inyear int,inage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 1..innum loop
      for stueval in
        SELECT sid, assid,sex,mt, count(distinct case when domainskillcount =1 then stuid else null end) as stucount
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
              and se.grade is not null 
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


DROP FUNCTION agg_school_ang_agemorethan_cohorts(inyear int,inage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp,inallassid int[]);
CREATE OR REPLACE function agg_school_ang_agemorethan_cohorts(inyear int,inage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp,inallassid int[]) returns void as $$
declare
  stueval RECORD;
  andcondition text;
begin
  for domaincount in 1..innum loop
  andcondition:='SELECT sid, assid,sex,mt, count(distinct case when domainskillcount =1 then stuid else null end) as stucount from ( select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clid as clid, aggregates.sex as sex,aggregates.mt as mt,  case when domainagg <'||inpmarks[domaincount]||' then 0 else 1 end as domainskillcount from (  select se.stuid as stuid, q.assid as assid, sg.id as clid, sg.sid as sid, c.sex as sex, c.mt as mt, sum(cast(se.grade as int))  as domainagg from tb_student_eval se,tb_question q,tb_student stu,tb_student_class stusg,tb_class sg,tb_child c where se.qid=q.id and q.assid='||inassid||' and q.desc= ANY(string_to_array('''||inqset[domaincount]||''','','')) and se.stuid=stusg.stuid and stusg.ayid='||inyear||' and stusg.clid=sg.id and stu.id=se.stuid and stu.cid=c.id and  se.grade is not null and  (extract(year from age('''||intimestamp||''',c.dob))*12+extract(month from age('''||intimestamp||''',c.dob)))>='||inage;
  FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
  loop
    andcondition := andcondition||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and se.grade is not null and q.assid = '||inallassid[i]||')';
  end loop;
  andcondition:= andcondition||' group by se.stuid,q.assid,sg.id,sg.sid,c.sex,c.mt) aggregates group by sid,assid,clid,sex,mt,stuid,domainagg)info group by sid, assid,sex,mt';
      for stueval in execute andcondition
        loop
          insert into tb_institution_assessment_agg_cohorts values (stueval.sid, stueval.assid,intext, stueval.sex, stueval.mt,'',0,indomains[domaincount],domaincount-1, stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;


DROP FUNCTION agg_school_ang_agebetween(inyear int,inlowerage int,inupperage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp);
CREATE OR REPLACE function agg_school_ang_agebetween(inyear int,inlowerage int,inupperage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 1..innum loop
      for stueval in
        SELECT sid, assid,sex,mt, count(distinct case when domainskillcount =1 then stuid else null end) as stucount
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
              and se.grade is not null
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


DROP FUNCTION agg_school_ang_agebetween_cohorts(inyear int,inlowerage int,inupperage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp,inallassid int[]);
CREATE OR REPLACE function agg_school_ang_agebetween_cohorts(inyear int,inlowerage int,inupperage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp,inallassid int[]) returns void as $$
declare
  stueval RECORD;
  andcondition text;
begin
  for domaincount in 1..innum loop
  andcondition:='SELECT sid, assid,sex,mt, count(distinct case when domainskillcount =1 then stuid else null end) as stucount from ( select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clid as clid, aggregates.sex as sex,aggregates.mt as mt,  case when domainagg <'||inpmarks[domaincount]||' then 0 else 1 end as domainskillcount from (  select se.stuid as stuid, q.assid as assid, sg.id as clid, sg.sid as sid, c.sex as sex, c.mt as mt, sum(cast(se.grade as int))  as domainagg from tb_student_eval se,tb_question q,tb_student stu,tb_student_class stusg,tb_class sg,tb_child c where se.qid=q.id and q.assid='||inassid||' and q.desc= ANY(string_to_array('''||inqset[domaincount]||''','','')) and se.stuid=stusg.stuid and stusg.ayid='||inyear||' and stusg.clid=sg.id and stu.id=se.stuid and stu.cid=c.id and se.grade is not null and (extract(year from age('''||intimestamp||''',c.dob))*12+extract(month from age('''||intimestamp||''',c.dob)))<'||inupperage||' and (extract(year from age('''||intimestamp||''',c.dob))*12+extract(month from age('''||intimestamp||''',c.dob)))>='||inlowerage;
  FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
  loop
    andcondition := andcondition||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and se.grade is not null and q.assid = '||inallassid[i]||')';
  end loop;
  andcondition:= andcondition||'group by se.stuid,q.assid,sg.id,sg.sid,c.sex,c.mt) aggregates group by sid,assid,clid,sex,mt,stuid,domainagg)info group by sid,assid,sex,mt ';
    for stueval in execute andcondition
    loop
          insert into tb_institution_assessment_agg_cohorts values (stueval.sid, stueval.assid,intext, stueval.sex, stueval.mt,'',0,indomains[domaincount],domaincount-1, stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;


DROP FUNCTION agg_school_assess_mark(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int);
CREATE OR REPLACE function agg_school_assess_mark(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 1..innum
    loop
      for stueval in
        SELECT sid, assid,clname,sex,mt, count(distinct case when domainskillcount =1 then stuid else null end) as stucount
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


DROP FUNCTION agg_school_assess_mark_cohorts(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,inallassid int[]);
CREATE OR REPLACE function agg_school_assess_mark_cohorts(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,inallassid int[]) returns void as $$
declare
  stueval RECORD;
  andcondition text;
begin
  for domaincount in 1..innum
  loop
    andcondition:='SELECT sid, assid,clname,sex,mt, count(distinct case when domainskillcount =1 then stuid else null end) as stucount from ( select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clname as clname, c.sex as sex,c.mt as mt,  case when domainagg <'||inpmarks[domaincount]||' then 0 else 1 end as domainskillcount from (  select se.stuid as stuid, q.assid as assid, sg.name as clname, sg.sid as sid, sum(cast(se.mark as int))  as domainagg from tb_student_eval se,tb_question q,tb_student_class stusg,tb_class sg where se.qid=q.id and q.assid='||inassid||' and q.desc= ANY(string_to_array('''||inqset[domaincount]||''','','')) and se.stuid=stusg.stuid and stusg.ayid='||inyear||' and stusg.clid=sg.id and sg.name='''||inclass||'''';
  FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
  loop
    andcondition := andcondition||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and q.assid = '||inallassid[i]||')';
  end loop;
  andcondition:= andcondition||' group by se.stuid,q.assid,sg.id,sg.sid) aggregates, tb_child c,tb_student stu where aggregates.stuid=stu.id and stu.cid=c.id)info           group by sid,assid,clname,sex,mt';
      for stueval in execute andcondition
        loop
          insert into tb_institution_assessment_agg_cohorts values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,indomains[domaincount],domaincount, stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;



DROP FUNCTION agg_school_assess_grade(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int);
CREATE OR REPLACE function agg_school_assess_grade(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 1..innum
    loop
      for stueval in
        SELECT sid, assid,clname,sex,mt, count(distinct case when domainskillcount =1 then stuid else null end) as stucount
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
              and se.grade is not null
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


DROP FUNCTION agg_school_assess_grade_cohorts(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,inallassid int[]);
CREATE OR REPLACE function agg_school_assess_grade_cohorts(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,inallassid int[]) returns void as $$
declare
  stueval RECORD;
  andcondition text;
begin
  for domaincount in 1..innum
  loop
   andcondition:='SELECT sid, assid,clname,sex,mt, count(distinct case when domainskillcount =1 then stuid else null end) as stucount from ( select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clname as clname, c.sex as sex,c.mt as mt,  case when domainagg <'||inpmarks[domaincount]||' then 0 else 1 end as domainskillcount from (  select se.stuid as stuid, q.assid as assid, sg.name as clname, sg.sid as sid, sum(cast(se.grade as int))  as domainagg from tb_student_eval se,tb_question q,tb_student_class stusg,tb_class sg where se.qid=q.id and q.assid='||inassid||' and q.desc= ANY(string_to_array('''||inqset[domaincount]||''','','')) and se.stuid=stusg.stuid and stusg.ayid='||inyear||' and stusg.clid=sg.id and se.grade is not null and sg.name='''||inclass||'''';
   FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
   loop
     andcondition := andcondition||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and se.grade is not null and q.assid = '||inallassid[i]||')';
   end loop;
   andcondition:= andcondition||' group by se.stuid,q.assid,sg.id,sg.sid) aggregates, tb_child c,tb_student stu where aggregates.stuid=stu.id and stu.cid=c.id)info           group by sid,assid,clname,sex,mt';
      for stueval in execute andcondition
        loop
          insert into tb_institution_assessment_agg_cohorts values (stueval.sid, stueval.assid, stueval.clname, stueval.sex, stueval.mt,'',0,indomains[domaincount],domaincount, stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;


-- Populate tb_school_agg for the current academic year
select agg_institution(102);

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
select basic_assess_school(102,73);
select basic_assess_school(102,74);
select basic_assess_school(102,75);
select basic_assess_school(102,76);
select basic_assess_school(102,77);

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

select basic_assess_school_cohorts(90,1,ARRAY[1,2,3,4]);
select basic_assess_school_cohorts(90,2,ARRAY[1,2,3,4]);
select basic_assess_school_cohorts(90,3,ARRAY[1,2,3,4]);
select basic_assess_school_cohorts(90,4,ARRAY[1,2,3,4]);
select basic_assess_school_cohorts(1,5,ARRAY[5,9]);
select basic_assess_school_cohorts(1,6,ARRAY[6,10]);
select basic_assess_school_cohorts(1,7,ARRAY[7,11]);
select basic_assess_school_cohorts(1,8,ARRAY[8,12]);
select basic_assess_school_cohorts(1,9,ARRAY[5,9]);
select basic_assess_school_cohorts(1,10,ARRAY[6,10]);
select basic_assess_school_cohorts(1,11,ARRAY[7,11]);
select basic_assess_school_cohorts(1,12,ARRAY[8,12]);
select basic_assess_school_cohorts(2,13,ARRAY[13,17]);
select basic_assess_school_cohorts(2,14,ARRAY[14,18]);
select basic_assess_school_cohorts(2,15,ARRAY[15,19]);
select basic_assess_school_cohorts(2,16,ARRAY[16,20]);
select basic_assess_school_cohorts(2,17,ARRAY[13,17]);
select basic_assess_school_cohorts(2,18,ARRAY[14,18]);
select basic_assess_school_cohorts(2,19,ARRAY[15,19]);
select basic_assess_school_cohorts(2,20,ARRAY[16,20]);
select basic_assess_school_cohorts(119,25,ARRAY[25,26]);
select basic_assess_school_cohorts(119,26,ARRAY[25,26]);
select basic_assess_school_cohorts(119,27,ARRAY[27,28,29]);
select basic_assess_school_cohorts(119,28,ARRAY[27,28,29]);
select basic_assess_school_cohorts(119,29,ARRAY[27,28,29]);
select basic_assess_school_cohorts(119,30,ARRAY[30,31,32]);
select basic_assess_school_cohorts(119,31,ARRAY[30,31,32]);
select basic_assess_school_cohorts(119,32,ARRAY[30,31,32]);
select basic_assess_school_cohorts(119,33,ARRAY[33,34]);
select basic_assess_school_cohorts(119,34,ARRAY[33,34]);
select basic_assess_school_cohorts(101,41,ARRAY[41,42]);
select basic_assess_school_cohorts(101,42,ARRAY[41,42]);
select basic_assess_school_cohorts(101,43,ARRAY[43,44]);
select basic_assess_school_cohorts(101,44,ARRAY[43,44]);
select basic_assess_school_cohorts(101,45,ARRAY[45,46]);
select basic_assess_school_cohorts(101,46,ARRAY[45,46]);
select basic_assess_school_cohorts(101,47,ARRAY[47,48]);
select basic_assess_school_cohorts(101,48,ARRAY[47,48]);
select basic_assess_school_cohorts(101,49,ARRAY[49,50]);
select basic_assess_school_cohorts(101,50,ARRAY[49,50]);
select basic_assess_school_cohorts(101,59,ARRAY[59,60,61]);
select basic_assess_school_cohorts(101,60,ARRAY[59,60,61]);
select basic_assess_school_cohorts(101,61,ARRAY[59,60,61]);
select basic_assess_school_cohorts(102,65,ARRAY[65,75]);
select basic_assess_school_cohorts(102,66,ARRAY[66,76]);
select basic_assess_school_cohorts(102,67,ARRAY[67,77]);
select basic_assess_school_cohorts(102,68,ARRAY[68,73]);
select basic_assess_school_cohorts(102,69,ARRAY[69,74]);
select basic_assess_school_cohorts(102,73,ARRAY[68,73]);
select basic_assess_school_cohorts(102,74,ARRAY[69,74]);
select basic_assess_school_cohorts(102,75,ARRAY[65,75]);
select basic_assess_school_cohorts(102,76,ARRAY[66,76]);
select basic_assess_school_cohorts(102,77,ARRAY[67,77]);

select basic_assess_school_cohorts(102,81,ARRAY[81,82,83]);
select basic_assess_school_cohorts(102,82,ARRAY[81,82,83]);
select basic_assess_school_cohorts(102,83,ARRAY[81,82,83]);
select basic_assess_school_cohorts(102,84,ARRAY[84,85,86]);
select basic_assess_school_cohorts(102,85,ARRAY[84,85,86]);
select basic_assess_school_cohorts(102,86,ARRAY[84,85,86]);
select basic_assess_school_cohorts(102,87,ARRAY[87,88,89]);
select basic_assess_school_cohorts(102,88,ARRAY[87,88,89]);
select basic_assess_school_cohorts(102,89,ARRAY[87,88,89]);
select basic_assess_school_cohorts(102,90,ARRAY[90,91,92]);
select basic_assess_school_cohorts(102,91,ARRAY[90,91,92]);
select basic_assess_school_cohorts(102,92,ARRAY[90,91,92]);
select basic_assess_school_cohorts(102,93,ARRAY[93,94,95]);
select basic_assess_school_cohorts(102,94,ARRAY[93,94,95]);
select basic_assess_school_cohorts(102,95,ARRAY[93,94,95]);
select basic_assess_school_cohorts(102,96,ARRAY[96,97,98]);
select basic_assess_school_cohorts(102,97,ARRAY[96,97,98]);
select basic_assess_school_cohorts(102,98,ARRAY[96,97,98]);
select basic_assess_school_cohorts(102,99,ARRAY[99,100,101]);
select basic_assess_school_cohorts(102,100,ARRAY[99,100,101]);
select basic_assess_school_cohorts(102,101,ARRAY[99,100,101]);
select basic_assess_school_cohorts(102,102,ARRAY[102,103,104]);
select basic_assess_school_cohorts(102,103,ARRAY[102,103,104]);
select basic_assess_school_cohorts(102,104,ARRAY[102,103,104]);
select basic_assess_school_cohorts(102,105,ARRAY[105,106,107]);
select basic_assess_school_cohorts(102,106,ARRAY[105,106,107]);
select basic_assess_school_cohorts(102,107,ARRAY[105,106,107]);
select basic_assess_school_cohorts(102,108,ARRAY[108,109,110]);
select basic_assess_school_cohorts(102,109,ARRAY[108,109,110]);
select basic_assess_school_cohorts(102,110,ARRAY[108,109,110]);



--Preschool basic assessessment
--2009-2010
select basic_assess_preschool_between(119,23,36,60,'Age between 3-5',cast('2009-04-30' as timestamp));
select basic_assess_preschool_morethan(119,23,60,'Age >=5',cast('2009-04-30'as timestamp));
select basic_assess_preschool_between(119,24,36,60,'Age between 3-5',cast('2009-04-30' as timestamp));
select basic_assess_preschool_morethan(119,24,60,'Age >=5',cast('2009-04-30' as timestamp));

--2010-2011
select basic_assess_preschool_between(101,56,36,60,'Age between 3-5',cast('2010-04-30' as timestamp));
select basic_assess_preschool_morethan(101,56,60,'Age >=5',cast('2010-04-30' as timestamp));
select basic_assess_preschool_between(101,57,36,60,'Age between 3-5',cast('2010-04-30' as timestamp));
select basic_assess_preschool_morethan(101,57,60,'Age >=5',cast('2010-04-30' as timestamp));

--2011-2012
select basic_assess_preschool_between(102,70,36,60,'Age between 3-5',cast('2011-04-30' as timestamp));
select basic_assess_preschool_morethan(102,70,60,'Age >=5',cast('2011-04-30' as timestamp));
select basic_assess_preschool_between(102,79,36,60,'Age between 3-5',cast('2011-04-30' as timestamp));
select basic_assess_preschool_morethan(102,79,60,'Age >=5',cast('2011-04-30' as timestamp));

select basic_assess_preschool_between(102,71,36,60,'Age between 3-5',cast('2011-04-30' as timestamp));
select basic_assess_preschool_morethan(102,71,60,'Age >=5',cast('2011-04-30' as timestamp));
select basic_assess_preschool_between(102,78,36,60,'Age between 3-5',cast('2011-04-30' as timestamp));
select basic_assess_preschool_morethan(102,78,60,'Age >=5',cast('2011-04-30' as timestamp));

--2009-2010 cohorts
select basic_assess_preschool_between_cohorts(119,23,36,60,'Age between 3-5',cast('2009-04-30' as timestamp),ARRAY[23,24]);
select basic_assess_preschool_morethan_cohorts(119,23,60,'Age >=5',cast('2009-04-30'as timestamp),ARRAY[23,24]);
select basic_assess_preschool_between_cohorts(119,24,36,60,'Age between 3-5',cast('2009-04-30' as timestamp),ARRAY[23,24]);
select basic_assess_preschool_morethan_cohorts(119,24,60,'Age >=5',cast('2009-04-30' as timestamp),ARRAY[23,24]);

--2010-2011 cohorts
select basic_assess_preschool_between_cohorts(101,56,36,60,'Age between 3-5',cast('2010-04-30' as timestamp),ARRAY[56,57]);
select basic_assess_preschool_morethan_cohorts(101,56,60,'Age >=5',cast('2010-04-30' as timestamp),ARRAY[56,57]);
select basic_assess_preschool_between_cohorts(101,57,36,60,'Age between 3-5',cast('2010-04-30' as timestamp),ARRAY[56,57]);
select basic_assess_preschool_morethan_cohorts(101,57,60,'Age >=5',cast('2010-04-30' as timestamp),ARRAY[56,57]);

--2011-2012 cohorts
select basic_assess_preschool_between_cohorts(102,70,36,60,'Age between 3-5',cast('2011-04-30' as timestamp),ARRAY[70,79]);
select basic_assess_preschool_morethan_cohorts(102,70,60,'Age >=5',cast('2011-04-30' as timestamp),ARRAY[70,79]);
select basic_assess_preschool_between_cohorts(102,79,36,60,'Age between 3-5',cast('2011-04-30' as timestamp),ARRAY[70,79]);
select basic_assess_preschool_morethan_cohorts(102,79,60,'Age >=5',cast('2011-04-30' as timestamp),ARRAY[70,79]);

select basic_assess_preschool_between_cohorts(102,71,36,60,'Age between 3-5',cast('2011-04-30' as timestamp),ARRAY[71,78]);
select basic_assess_preschool_morethan_cohorts(102,71,60,'Age >=5',cast('2011-04-30' as timestamp),ARRAY[71,78]);
select basic_assess_preschool_between_cohorts(102,78,36,60,'Age between 3-5',cast('2011-04-30' as timestamp),ARRAY[71,78]);
select basic_assess_preschool_morethan_cohorts(102,78,60,'Age >=5',cast('2011-04-30' as timestamp),ARRAY[71,78]);

-- 2006 Reading
select agg_school_reading(1, 90);
select agg_school_reading(2, 90);
select agg_school_reading(3, 90);
select agg_school_reading(4, 90);

select agg_school_reading_cohorts(1, 90,ARRAY[1,2,3,4]);
select agg_school_reading_cohorts(2, 90,ARRAY[1,2,3,4]);
select agg_school_reading_cohorts(3, 90,ARRAY[1,2,3,4]);
select agg_school_reading_cohorts(4, 90,ARRAY[1,2,3,4]);

-- 2009 Reading
select agg_school_reading(27, 119);
select agg_school_reading(28, 119);
select agg_school_reading(29, 119);
select agg_school_reading(30, 119);
select agg_school_reading(31, 119);
select agg_school_reading(32, 119);


select agg_school_reading_cohorts(27, 119,ARRAY[27,28,29]);
select agg_school_reading_cohorts(28, 119,ARRAY[27,29,29]);
select agg_school_reading_cohorts(29, 119,ARRAY[27,28,29]);
select agg_school_reading_cohorts(30, 119,ARRAY[30,31,32]);
select agg_school_reading_cohorts(31, 119,ARRAY[30,31,32]);
select agg_school_reading_cohorts(32, 119,ARRAY[30,31,32]);


--2010 Reading
select agg_school_reading(59, 101);
select agg_school_reading(60, 101);
select agg_school_reading(61, 101);

select agg_school_reading_cohorts(59, 101,ARRAY[59,60,61]);
select agg_school_reading_cohorts(60, 101,ARRAY[59,60,61]);
select agg_school_reading_cohorts(61, 101,ARRAY[59,60,61]);

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

select agg_school_nng_cohorts(5, 1,ARRAY[5,9]);
select agg_school_nng_cohorts(6, 1,ARRAY[6,10]);
select agg_school_nng_cohorts(7, 1,ARRAY[7,11]);
select agg_school_nng_cohorts(8, 1,ARRAY[8,12]);
select agg_school_nng_cohorts(9, 1,ARRAY[5,9]);
select agg_school_nng_cohorts(10, 1,ARRAY[6,10]);
select agg_school_nng_cohorts(11, 1,ARRAY[7,11]);
select agg_school_nng_cohorts(12, 1,ARRAY[8,12]);

-- 2008 NNG
select agg_school_nng(13, 2);
select agg_school_nng(14, 2);
select agg_school_nng(15, 2);
select agg_school_nng(16, 2);
select agg_school_nng(17, 2);
select agg_school_nng(18, 2);
select agg_school_nng(19, 2);
select agg_school_nng(20, 2);

select agg_school_nng_cohorts(13, 2,ARRAY[13,17]);
select agg_school_nng_cohorts(14, 2,ARRAY[14,18]);
select agg_school_nng_cohorts(15, 2,ARRAY[15,19]);
select agg_school_nng_cohorts(16, 2,ARRAY[16,20]);
select agg_school_nng_cohorts(17, 2,ARRAY[13,17]);
select agg_school_nng_cohorts(18, 2,ARRAY[14,18]);
select agg_school_nng_cohorts(19, 2,ARRAY[15,19]);
select agg_school_nng_cohorts(20, 2,ARRAY[16,20]);


-- 2009 NNG
select agg_school_nng(33, 119);
select agg_school_nng(34, 119);

select agg_school_nng_cohorts(33, 119,ARRAY[33,34]);
select agg_school_nng_cohorts(34, 119,ARRAY[33,34]);


--2010 NNG
select agg_school_nng(41,101);
select agg_school_nng(42,101);
select agg_school_nng(43,101);
select agg_school_nng(44,101);
select agg_school_nng(45,101);
select agg_school_nng(46,101);
select agg_school_nng(47,101);
select agg_school_nng(48,101);

select agg_school_nng_cohorts(41,101,ARRAY[41,42]);
select agg_school_nng_cohorts(42,101,ARRAY[41,42]);
select agg_school_nng_cohorts(43,101,ARRAY[43,44]);
select agg_school_nng_cohorts(44,101,ARRAY[43,44]);
select agg_school_nng_cohorts(45,101,ARRAY[45,46]);
select agg_school_nng_cohorts(46,101,ARRAY[45,46]);
select agg_school_nng_cohorts(47,101,ARRAY[47,48]);
select agg_school_nng_cohorts(48,101,ARRAY[47,48]);


--2011
select agg_school_nng(68,102);
select agg_school_nng(69,102);
select agg_school_nng(73,102);
select agg_school_nng(74,102);

select agg_school_nng_cohorts(68,102,ARRAY[68,73]);
select agg_school_nng_cohorts(69,102,ARRAY[69,74]);
select agg_school_nng_cohorts(73,102,ARRAY[68,73]);
select agg_school_nng_cohorts(74,102,ARRAY[69,74]);



--Control Math 2011
select agg_school_nng_grade(81,102,49);
select agg_school_nng_grade(82,102,49);
select agg_school_nng_grade(83,102,49);
select agg_school_nng_grade(84,102,56);
select agg_school_nng_grade(85,102,56);
select agg_school_nng_grade(86,102,56);

select agg_school_nng_grade_cohorts(81,102,ARRAY[81,82,83],49);
select agg_school_nng_grade_cohorts(82,102,ARRAY[81,82,83],49);
select agg_school_nng_grade_cohorts(83,102,ARRAY[81,82,83],49);
select agg_school_nng_grade_cohorts(84,102,ARRAY[84,85,86],56);
select agg_school_nng_grade_cohorts(85,102,ARRAY[84,85,86],56);
select agg_school_nng_grade_cohorts(86,102,ARRAY[84,85,86],56);

--Treatment Math 2011
select agg_school_nng_grade(96,102,49);
select agg_school_nng_grade(97,102,49);
select agg_school_nng_grade(98,102,49);
select agg_school_nng_grade(99,102,56);
select agg_school_nng_grade(100,102,56);
select agg_school_nng_grade(101,102,56);

select agg_school_nng_grade_cohorts(96,102,ARRAY[96,97,98],49);
select agg_school_nng_grade_cohorts(97,102,ARRAY[96,97,98],49);
select agg_school_nng_grade_cohorts(98,102,ARRAY[96,97,98],49);
select agg_school_nng_grade_cohorts(99,102,ARRAY[99,100,101],56);
select agg_school_nng_grade_cohorts(100,102,ARRAY[99,100,101],56);
select agg_school_nng_grade_cohorts(101,102,ARRAY[99,100,101],56);

--Anganwadi
-- 2009 Anganwadi
--Pretest

select agg_school_ang_agebetween(119,36,60,23,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2009-04-30' as timestamp));
select agg_school_ang_agemorethan(119,60,23,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2009-04-30' as timestamp));

select agg_school_ang_agebetween_cohorts(119,36,60,23,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2009-04-30' as timestamp),ARRAY[23,24]);
select agg_school_ang_agemorethan_cohorts(119,60,23,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2009-04-30' as timestamp),ARRAY[23,24]);

--Posttest
select agg_school_ang_agebetween(119,36,60,24,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2009-04-30' as timestamp));
select agg_school_ang_agemorethan(119,60,24,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2009-04-30' as timestamp));

select agg_school_ang_agebetween_cohorts(119,36,60,24,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2009-04-30' as timestamp),ARRAY[23,24]);
select agg_school_ang_agemorethan_cohorts(119,60,24,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2009-04-30' as timestamp),ARRAY[23,24]);

-- 2010 Anganwadi
--Pretest
select agg_school_ang_agebetween(101,36,60,56,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2010-04-30' as timestamp));
select agg_school_ang_agemorethan(101,60,56,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2010-04-30' as timestamp));

select agg_school_ang_agebetween_cohorts(101,36,60,56,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2010-04-30' as timestamp),ARRAY[56,57]);
select agg_school_ang_agemorethan_cohorts(101,60,56,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2010-04-30' as timestamp),ARRAY[56,57]);

--Posttest
select agg_school_ang_agebetween(101,36,60,57,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2010-04-30' as timestamp));
select agg_school_ang_agemorethan(101,60,57,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2010-04-30' as timestamp));

select agg_school_ang_agebetween_cohorts(101,36,60,57,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2010-04-30' as timestamp),ARRAY[56,57]);
select agg_school_ang_agemorethan_cohorts(101,60,57,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2010-04-30' as timestamp),ARRAY[56,57]);


-- 2011 Anganwadi
--Pretest
select agg_school_ang_agebetween(102,36,60,70,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2011-04-30' as timestamp));
select agg_school_ang_agemorethan(102,60,70,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2011-04-30' as timestamp));

select agg_school_ang_agebetween_cohorts(102,36,60,70,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2011-04-30' as timestamp),ARRAY[70,79]);
select agg_school_ang_agemorethan_cohorts(102,60,70,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2011-04-30' as timestamp),ARRAY[70,79]);

--Posttest
select agg_school_ang_agebetween(102,36,60,79,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2011-04-30' as timestamp));
select agg_school_ang_agemorethan(102,60,79,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2011-04-30' as timestamp));

select agg_school_ang_agebetween_cohorts(102,36,60,79,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],4,'Age between 3-5',cast('2011-04-30' as timestamp),ARRAY[70,79]);
select agg_school_ang_agemorethan_cohorts(102,60,79,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],4,'Age >=5',cast('2011-04-30' as timestamp),ARRAY[70,79]);

-- 2011 Anganwadi Dharwad
--Pretest
select agg_school_ang_agebetween(102,36,60,71,ARRAY['Language','Socio-Emotional','Pre-Academic'],ARRAY['4,5,6','9,10','11'],ARRAY[3,2,1],3,'Age between 3-5',cast('2011-04-30' as timestamp));
select agg_school_ang_agemorethan(102,60,71,ARRAY['Language','Socio-Emotional','Pre-Academic Reading','Pre-Academic Writing','Pre-Academic Math'],ARRAY['4,5,6,7,8','9,10','11,12,13,14','15,16,17,18,19,20,21,22,23,24','25,26,27,28,29,30'],ARRAY[5,2,4,10,6],5,'Age >=5',cast('2011-04-30' as timestamp));

select agg_school_ang_agebetween_cohorts(102,36,60,71,ARRAY['Language','Socio-Emotional','Pre-Academic'],ARRAY['4,5,6','9,10','11'],ARRAY[3,2,1],3,'Age between 3-5',cast('2011-04-30' as timestamp),ARRAY[71,78]);
select agg_school_ang_agemorethan_cohorts(102,60,71,ARRAY['Language','Socio-Emotional','Pre-Academic Reading','Pre-Academic Writing','Pre-Academic Math'],ARRAY['4,5,6,7,8','9,10','11,12,13,14','15,16,17,18,19,20,21,22,23,24','25,26,27,28,29,30'],ARRAY[5,2,4,10,6],5,'Age >=5',cast('2011-04-30' as timestamp),ARRAY[71,78]);

--Posttest

select agg_school_ang_agebetween(102,36,60,78,ARRAY['Language','Socio-Emotional','Pre-Academic'],ARRAY['4,5,6','9,10','11'],ARRAY[3,2,1],3,'Age between 3-5',cast('2011-04-30' as timestamp));
select agg_school_ang_agemorethan(102,60,78,ARRAY['Language','Socio-Emotional','Pre-Academic Reading','Pre-Academic Writing','Pre-Academic Math'],ARRAY['4,5,6,7,8','9,10','11,12,13,14','15,16,17,18,19,20,21,22,23,24','25,26,27,28,29,30'],ARRAY[5,2,4,10,6],5,'Age >=5',cast('2011-04-30' as timestamp));

select agg_school_ang_agebetween_cohorts(102,36,60,78,ARRAY['Language','Socio-Emotional','Pre-Academic'],ARRAY['4,5,6','9,10','11'],ARRAY[3,2,1],3,'Age between 3-5',cast('2011-04-30' as timestamp),ARRAY[71,78]);
select agg_school_ang_agemorethan_cohorts(102,60,78,ARRAY['Language','Socio-Emotional','Pre-Academic Reading','Pre-Academic Writing','Pre-Academic Math'],ARRAY['4,5,6,7,8','9,10','11,12,13,14','15,16,17,18,19,20,21,22,23,24','25,26,27,28,29,30'],ARRAY[5,2,4,10,6],5,'Age >=5',cast('2011-04-30' as timestamp),ARRAY[71,78]);

--English
--2009 English
--Pretest 5
select agg_school_assess_mark(119,'5',25,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2);
select agg_school_assess_grade(119,'5',25,ARRAY['Can read simple passage','Can give one word  answer orally'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1);
select agg_school_assess_mark_cohorts(119,'5',25,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2,ARRAY[25,26]);
select agg_school_assess_grade_cohorts(119,'5',25,ARRAY['Can read simple passage','Can give one word  answer orally'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1,ARRAY[25,26]);
--Posttest 5
select agg_school_assess_mark(119,'5',26,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2);
select agg_school_assess_grade(119,'5',26,ARRAY['Can read simple passage','Can give one word  answer orally'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1);

select agg_school_assess_mark_cohorts(119,'5',26,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2,ARRAY[25,26]);
select agg_school_assess_grade_cohorts(119,'5',26,ARRAY['Can read simple passage','Can give one word  answer orally'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1,ARRAY[25,26]);


--Pretest 6
select agg_school_assess_mark(119,'6',25,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2);
select agg_school_assess_grade(119,'6',25,ARRAY['Can read simple passage','Can write one word  answers'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1);

select agg_school_assess_mark_cohorts(119,'6',25,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2,ARRAY[25,26]);
select agg_school_assess_grade_cohorts(119,'6',25,ARRAY['Can read simple passage','Can write one word  answers'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1,ARRAY[25,26]);

--Posttest 6
select agg_school_assess_mark(119,'6',26,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2);
select agg_school_assess_grade(119,'6',26,ARRAY['Can read simple passage','Can write one word  answers'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1);

select agg_school_assess_mark_cohorts(119,'6',26,ARRAY['Can recognizes the objects in picture','Picture Reading-Can construct  simple sentences','Can read words'],ARRAY['EngPilot1','EngPilot2','EngPilot3,EngPilot4,EngPilot5,EngPilot6'],ARRAY[3,3,8],2,ARRAY[25,26]);
select agg_school_assess_grade_cohorts(119,'6',26,ARRAY['Can read simple passage','Can write one word  answers'],ARRAY['EngPilot7','EngPilot8,EngPilot9,EngPilot10'],ARRAY[1,3],1,ARRAY[25,26]);

--2010 English
--Pretest 3
select agg_school_assess_grade(101,'3',49,ARRAY['Can write alphabets','Can follow simple instruction','Can give one word answer'],ARRAY['Eng1,Eng2','Eng6','Eng7'],ARRAY[2,1,1],2);

select agg_school_assess_grade_cohorts(101,'3',49,ARRAY['Can write alphabets','Can follow simple instruction','Can give one word answer'],ARRAY['Eng1,Eng2','Eng6','Eng7'],ARRAY[2,1,1],2,ARRAY[49,50]);
--Posttest 3
select agg_school_assess_grade(101,'3',50,ARRAY['Can write alphabets','Can follow simple instruction','Can give one word answer'],ARRAY['Eng1,Eng2','Eng6','Eng7'],ARRAY[2,1,1],2);

select agg_school_assess_grade_cohorts(101,'3',50,ARRAY['Can write alphabets','Can follow simple instruction','Can give one word answer'],ARRAY['Eng1,Eng2','Eng6','Eng7'],ARRAY[2,1,1],2,ARRAY[49,50]);

--Pretest 4
select agg_school_assess_grade(101,'4',49,ARRAY['Picture reading','Can answer in sentence','Can read a simple sentence'],ARRAY['Eng10','Eng8','Eng9'],ARRAY[1,1,1],2);
select agg_school_assess_grade_cohorts(101,'4',49,ARRAY['Picture reading','Can answer in sentence','Can read a simple sentence'],ARRAY['Eng10','Eng8','Eng9'],ARRAY[1,1,1],2,ARRAY[49,50]);
--Posttest 4
select agg_school_assess_grade(101,'4',50,ARRAY['Picture reading','Can answer in sentence','Can read a simple sentence'],ARRAY['Eng10','Eng8','Eng9'],ARRAY[1,1,1],2);
select agg_school_assess_grade_cohorts(101,'4',50,ARRAY['Picture reading','Can answer in sentence','Can read a simple sentence'],ARRAY['Eng10','Eng8','Eng9'],ARRAY[1,1,1],2,ARRAY[49,50]);



--2011-2012
--English
select agg_school_assess_grade_eng(102,'1',65,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'2',66,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'3',67,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);
select agg_school_assess_grade_eng(102,'1',75,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'2',76,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'3',77,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);

select agg_school_assess_grade_eng_cohorts(102,'1',65,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1,ARRAY[65,75]);
select agg_school_assess_grade_eng_cohorts(102,'2',66,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3,ARRAY[66,76]);
select agg_school_assess_grade_eng_cohorts(102,'3',67,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3,ARRAY[67,77]);
select agg_school_assess_grade_eng_cohorts(102,'1',75,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1,ARRAY[65,75]);
select agg_school_assess_grade_eng_cohorts(102,'2',76,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3,ARRAY[66,76]);
select agg_school_assess_grade_eng_cohorts(102,'3',77,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3,ARRAY[67,77]);

--Control English 2011-2012
select agg_school_assess_grade_eng(102,'1',87,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'1',88,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'1',89,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'2',90,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'2',91,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'2',92,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'3',93,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);
select agg_school_assess_grade_eng(102,'3',94,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);
select agg_school_assess_grade_eng(102,'3',95,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);

select agg_school_assess_grade_eng_cohorts(102,'1',87,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1,ARRAY[87,88,89]);
select agg_school_assess_grade_eng_cohorts(102,'1',88,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1,ARRAY[87,88,89]);
select agg_school_assess_grade_eng_cohorts(102,'1',89,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1,ARRAY[87,88,89]);
select agg_school_assess_grade_eng_cohorts(102,'2',90,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3,ARRAY[90,91,92]);
select agg_school_assess_grade_eng_cohorts(102,'2',91,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3,ARRAY[90,91,92]);
select agg_school_assess_grade_eng_cohorts(102,'2',92,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3,ARRAY[90,91,92]);
select agg_school_assess_grade_eng_cohorts(102,'3',93,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3,ARRAY[93,94,95]);
select agg_school_assess_grade_eng_cohorts(102,'3',94,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3,ARRAY[93,94,95]);
select agg_school_assess_grade_eng_cohorts(102,'3',95,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3,ARRAY[93,94,95]);

--Treatment English 2011-2012
select agg_school_assess_grade_eng(102,'1',102,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'1',103,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'1',104,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'2',105,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'2',106,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'2',107,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'3',108,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);
select agg_school_assess_grade_eng(102,'3',109,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);
select agg_school_assess_grade_eng(102,'3',110,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);

select agg_school_assess_grade_eng_cohorts(102,'1',102,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1,ARRAY[102,103,104]);
select agg_school_assess_grade_eng_cohorts(102,'1',103,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1,ARRAY[102,103,104]);
select agg_school_assess_grade_eng_cohorts(102,'1',104,ARRAY['Oral'],ARRAY[0],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1,ARRAY[102,103,104]);
select agg_school_assess_grade_eng_cohorts(102,'2',105,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3,ARRAY[105,106,107]);
select agg_school_assess_grade_eng_cohorts(102,'2',106,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3,ARRAY[105,106,107]);
select agg_school_assess_grade_eng_cohorts(102,'2',107,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3,ARRAY[105,106,107]);
select agg_school_assess_grade_eng_cohorts(102,'3',108,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3,ARRAY[108,109,110]);
select agg_school_assess_grade_eng_cohorts(102,'3',109,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3,ARRAY[108,109,110]);
select agg_school_assess_grade_eng_cohorts(102,'3',110,ARRAY['Oral','Reading','Writing'],ARRAY[0,1,2],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3,ARRAY[108,109,110]);


GRANT SELECT ON tb_institution_agg,
                tb_institution_assessment_agg,
                tb_institution_basic_assessment_info,
                tb_institution_basic_assessment_info_cohorts,
                tb_institution_assessment_agg_cohorts
TO web;
