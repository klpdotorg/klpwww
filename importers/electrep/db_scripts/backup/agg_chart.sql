-- Aggregation tables

DROP TABLE IF EXISTS "tb_school_chart_agg";
CREATE TABLE "tb_school_chart_agg" (
  "sid" integer,
  "assid" integer,
  "clid" integer,
  "sex" sex,
  "mt" school_moi,
  "aggtext" varchar(100) NOT NULL,
  "aggval" numeric(6,2) DEFAULT 0,
  "aggmax" numeric(6,2) DEFAULT 0
);


CREATE OR REPLACE function agg_reading(int, int) returns void as $$
declare
        stueval RECORD;
begin
        for stueval in SELECT s.id as id, ass.id as assid, sc.clid as clid, c.sex as sex, c.mt as mt, se.grade as grade, cast(count(distinct stu.id) as float) as cnt
                       FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass
                       WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.assid = ass.id AND ass.id = $1 AND sc.ayid = $2 AND se.grade IS NOT NULL
                       GROUP BY s.id, ass.id, sc.clid, c.sex, c.mt, se.grade
        loop
                insert into tb_school_chart_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, stueval.grade, stueval.cnt);
        end loop;
end;
$$ language plpgsql;

CREATE OR REPLACE function agg_ang(int, int) returns void as $$
declare
        stueval RECORD;
        domains text[6];
        qset varchar[6];
begin
        domains[1] = 'General awareness'; qset[1]='5';
        domains[2] = 'Intellectual'; qset[2]='33';
        domains[3] = 'Language'; qset[3]='26,28,29,30,31';
        domains[4] = 'Pre-academic Writing'; qset[4]='40,41,46'; 
        domains[5] = 'Pre-academic Reading'; qset[5]='55';
        domains[6] = 'Pre-academic Math'; qset[6]='47,48,49,53'; 

        for i in 1..6 loop
            for stueval in SELECT s.id as id, ass.id as assid, sc.clid as clid, c.sex as sex, c.mt as mt, 
                       avg(cast(se.grade as integer)) as dmarks, 1 as mmarks
                       FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass, tb_question q
                       WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.assid = ass.id AND 
                       ass.id = $1 AND sc.ayid = $2 AND se.qid = q.id AND ass.id = q.assid AND 
                       cast(q.desc as integer) = ANY( CAST( string_to_array(qset[i],',') AS INTEGER[]))  
                       GROUP BY s.id, ass.id, sc.clid, c.sex, c.mt
                       ORDER BY s.id
            loop
                   insert into tb_school_chart_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, domains[i], stueval.dmarks, stueval.mmarks);
            end loop;
        end loop;

end;
$$ language plpgsql;

CREATE OR REPLACE function agg_eng(int, int) returns void as $$
declare
        stueval RECORD;
        domains text[3];
        qset varchar[3];
        pmarks integer[3];
begin
        domains[1] = 'Writing Skill'; qset[1]='Eng2,Eng3,Eng4'; pmarks[1] = 2;
        domains[2] = 'Speaking Skill'; qset[2]='Eng8'; pmarks[2] = 1;
        domains[3] = 'Reading Skill'; qset[3]='Eng9'; pmarks[3] = 1;

        for i in 1..3 loop
            for stueval in SELECT s.id as id, ass.id as assid, sc.clid as clid, c.sex as sex, c.mt as mt, 
                       avg(cast(se.grade as integer)) as dmarks, pmarks[i] as mmarks
                       FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass, tb_question q
                       WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.assid = ass.id AND
                       ass.id = $1 AND sc.ayid = $2 AND se.qid = q.id AND ass.id = q.assid AND
                       q.desc = ANY( CAST( string_to_array(qset[i],',') AS varchar[]))
                       GROUP BY s.id, ass.id, sc.clid, c.sex, c.mt
                       ORDER BY s.id
            loop
                   insert into tb_school_chart_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex,stueval.mt, domains[i], stueval.dmarks, stueval.mmarks);
            end loop;
        end loop;

end;
$$ language plpgsql;

CREATE OR REPLACE function agg_nng(int, int) returns void as $$
declare
        stueval RECORD;
        domains text[5];
        qset varchar[5];
begin
        domains[1] = 'Number Concepts'; qset[1]='NNGSC1';
        domains[2] = 'Addition and Subtraction'; qset[2]='NNGSC2';
        domains[3] = 'Division and Multiplication'; qset[3]='NNGSC3';
        domains[4] = 'Mental Maths'; qset[4]='NNGSC4';
        domains[5] = 'Fractions'; qset[5]='NNGSC5';

        for i in 1..3 loop
            for stueval in SELECT s.id as id, ass.id as assid, sc.clid as clid, c.sex as sex, c.mt as mt, 
                       avg(cast(se.mark as integer)) as dmarks, q.markorgrade as mmarks 
                       FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass, tb_question q
                       WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.assid = ass.id AND
                       ass.id = $1 AND sc.ayid = $2 AND se.qid = q.id AND ass.id = q.assid AND
                       q.desc = ANY( CAST( string_to_array(qset[i],',') AS varchar[]))
                       GROUP BY s.id, ass.id, sc.clid, c.sex, c.mt, q.markorgrade
                       ORDER BY s.id
            loop
                   insert into tb_school_chart_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, domains[i], stueval.dmarks,stueval.mmarks);
            end loop;
        end loop;

end;
$$ language plpgsql;

select agg_nng(29,101);
select agg_ang(37,101);
select agg_eng(31,101);

GRANT SELECT ON tb_school_chart_agg 
TO klp;
