DROP TABLE IF EXISTS "tb_institution_assessment_reading_agg_cohorts";
CREATE TABLE "tb_institution_assessment_reading_agg_cohorts" (
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

DROP FUNCTION agg_school_reading_2006_cohorts(inassessid int, inayid int,inallassid int[]);
CREATE OR REPLACE function agg_school_reading_2006_cohorts(inassessid int, inayid int,inallassid int[]) returns void as $$
declare
        stueval RECORD;
        andcondition text;
begin
        andcondition:='SELECT s.id as id, ass.id as assid, cl.name as clname, c.sex as sex, c.mt as mt, count(distinct case when se.grade=''0'' then stu.id else null end) as Ocount, count(distinct case when se.grade=''L'' then stu.id else null end) as Lcount, count(distinct case when se.grade=''W'' then stu.id else null end) as Wcount, count(distinct case when se.grade=''S'' then stu.id else null end) as Scount, count(distinct case when se.grade=''P'' then stu.id else null end) as Pcount, cast(count(distinct stu.id) as float) as cnt FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se,tb_question q, tb_assessment ass, tb_programme p,tb_boundary b WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid= ass.id AND ass.pid=p.id AND  sc.ayid=p.ayid AND ass.id ='||inassessid||' AND sc.ayid = '||inayid||' AND se.grade IS NOT NULL AND s.bid=b.id and p.type=b.type';
        FOR i in array_lower(inallassid,1)..array_upper(inallassid,1)
        loop
          andcondition := andcondition||' and se.stuid in (select se.stuid from tb_student_eval se,tb_question q where se.qid=q.id and se.grade is not null and q.assid = '||inallassid[i]||')';
        end loop;
        andcondition:= andcondition||'GROUP BY s.id, ass.id, cl.name, c.sex, c.mt, se.grade';
        for stueval in execute andcondition
        loop
                insert into tb_institution_assessment_reading_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'O',0,stueval.Ocount);
                insert into tb_institution_assessment_reading_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'L',1,stueval.Lcount);
                insert into tb_institution_assessment_reading_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'W',2,stueval.Wcount);
                insert into tb_institution_assessment_reading_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'S',3,stueval.Scount);
                insert into tb_institution_assessment_reading_agg_cohorts values (stueval.id, stueval.assid, stueval.clname, stueval.sex, stueval.mt, '',0,'P',4,stueval.PCount);
        end loop;
end;
$$ language plpgsql;



select agg_school_reading_2006_cohorts(1, 90,ARRAY[1,2,3,4]);
select agg_school_reading_2006_cohorts(2, 90,ARRAY[1,2,3,4]);
select agg_school_reading_2006_cohorts(3, 90,ARRAY[1,2,3,4]);
select agg_school_reading_2006_cohorts(4, 90,ARRAY[1,2,3,4]);
