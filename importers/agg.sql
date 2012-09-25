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


DROP TABLE IF EXISTS "tb_school_basic_assessment_info";
CREATE TABLE "tb_school_basic_assessment_info" (
  "sid" integer REFERENCES "tb_school" ("id") ON DELETE CASCADE,
  "assid" integer REFERENCES "tb_assessment" ("id") ON DELETE CASCADE,
  "clid" integer REFERENCES "tb_class" ("id") ON DELETE CASCADE,
  "sex" sex,
  "mt" school_moi,
  "num" integer
);


DROP TABLE IF EXISTS "tb_preschool_basic_assessment_info";
CREATE TABLE "tb_preschool_basic_assessment_info" (
  "sid" integer REFERENCES "tb_school" ("id") ON DELETE CASCADE,
  "assid" integer REFERENCES "tb_assessment" ("id") ON DELETE CASCADE,
  "agegroup" varchar(50),
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

DROP TABLE IF EXISTS "tb_preschool_assessment_agg";
CREATE TABLE "tb_preschool_assessment_agg" (
  "sid" integer REFERENCES "tb_school" ("id") ON DELETE CASCADE,
  "assid" integer REFERENCES "tb_assessment" ("id") ON DELETE CASCADE,
  "agegroup" varchar(50),
  "sex" sex,
  "mt" school_moi,
  "aggtext" varchar(100) NOT NULL,
  "aggval" numeric(6,2) DEFAULT 0
);



/*
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

*/



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


CREATE OR REPLACE function basic_assess_school(int,int) returns void as $$
declare
        schs RECORD;
begin
        for schs in SELECT s.id as id,ass.id as assid,cl.id as clid,c.sex as sex, c.mt as mt, count(distinct stu.id) AS count
                 FROM tb_student_eval se,tb_question q,tb_assessment ass,tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s,tb_programme p,tb_boundary b 
                 WHERE se.stuid=stu.id and se.qid=q.id and q.assid=ass.id and ass.pid=p.id and sc.stuid=stu.id and sc.clid=cl.id AND cl.sid = s.id AND stu.cid = c.id AND sc.ayid = $1 and ass.id=$2 and sc.ayid=p.ayid and s.bid=b.id and p.type=b.type and (se.grade is not null or se.mark is not null)
                 GROUP BY s.id, ass.id,cl.id,c.sex,c.mt
        loop
                insert into tb_school_basic_assessment_info values (schs.id, schs.assid, schs.clid ,schs.sex, schs.mt, schs.count);
        end loop;
end;
$$ language plpgsql;


CREATE OR REPLACE function basic_assess_preschool_morethan(inayid int,inassid int,inage int,intext text,intimestamp timestamp) returns void as $$
declare
        schs RECORD;
begin
        for schs in SELECT s.id as id,ass.id as assid,c.sex as sex, c.mt as mt, count(distinct stu.id) AS count
                 FROM tb_student_eval se,tb_question q,tb_assessment ass,tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s,tb_programme p,tb_boundary b 
                 WHERE se.stuid=stu.id and se.qid=q.id and q.assid=ass.id and ass.pid=p.id and sc.stuid=stu.id and sc.clid=cl.id AND cl.sid = s.id AND stu.cid = c.id AND sc.ayid = inayid and ass.id=inassid and sc.ayid=p.ayid and s.bid=b.id and p.type=b.type and (extract(year from age(intimestamp,c.dob))*12+extract(month from age(intimestamp,c.dob)))>=inage
                 GROUP BY s.id, ass.id,c.sex,c.mt
        loop
                insert into tb_preschool_basic_assessment_info values (schs.id, schs.assid,intext,schs.sex, schs.mt, schs.count);
        end loop;
end;
$$ language plpgsql;


CREATE OR REPLACE function basic_assess_preschool_between(inayid int,inassid int,inlowerage int,inupperage int,intext text,intimestamp timestamp) returns void as $$
declare
        schs RECORD;
begin
        for schs in SELECT s.id as id,ass.id as assid,c.sex as sex, c.mt as mt, count(distinct stu.id) AS count
                 FROM tb_student_eval se,tb_question q,tb_assessment ass,tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s,tb_programme p,tb_boundary b 
                 WHERE se.stuid=stu.id and se.qid=q.id and q.assid=ass.id and ass.pid=p.id and sc.stuid=stu.id and sc.clid=cl.id AND cl.sid = s.id AND stu.cid = c.id AND sc.ayid = inayid and ass.id=inassid and sc.ayid=p.ayid and s.bid=b.id and p.type=b.type and (extract(year from age(intimestamp,c.dob))*12+extract(month from age(intimestamp,c.dob)))<inupperage and (extract(year from age(intimestamp,c.dob))*12+extract(month from age(intimestamp,c.dob)))>=inlowerage
                 GROUP BY s.id, ass.id,c.sex,c.mt
        loop
                insert into tb_preschool_basic_assessment_info values (schs.id, schs.assid,intext,schs.sex, schs.mt, schs.count);
        end loop;
end;
$$ language plpgsql;


CREATE OR REPLACE function agg_school_reading(int, int) returns void as $$
declare
        stueval RECORD;
begin
        for stueval in SELECT s.id as id, ass.id as assid, sc.clid as clid, c.sex as sex, c.mt as mt, se.grade as grade, cast(count(distinct stu.id) as float) as cnt
                       FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se,tb_question q, tb_assessment ass, tb_programme p,tb_boundary b
                       WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid= ass.id AND ass.pid=p.id AND  sc.ayid=p.ayid AND ass.id = $1 AND sc.ayid = $2 AND se.grade IS NOT NULL AND s.bid=b.id and p.type=b.type
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
        FROM ( SELECT se.stuid,s.id as id, ass.id as assid, sc.clid as clid, c.sex as sex, c.mt as mt, avg(se.mark/q.maxmarks*100) as mark 
               FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass,tb_question q,tb_programme p,tb_boundary b  
               WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid = ass.id AND ass.pid=p.id AND sc.ayid=p.ayid AND ass.id = $1 AND sc.ayid =$2  AND s.bid=b.id and p.type=b.type
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
                       FROM tb_student stu, tb_class cl, tb_student_class sc, tb_child c, tb_school s, tb_student_eval se, tb_assessment ass, tb_question q,tb_programme p,tb_boundary b 
                       WHERE cl.sid = s.id AND sc.clid = cl.id AND sc.stuid = stu.id AND stu.cid = c.id AND stu.id = se.stuid AND se.qid=q.id and q.assid = ass.id AND ass.pid=p.id AND sc.ayid=p.ayid AND ass.id = $1 AND sc.ayid = $2 AND se.qid = q.id AND ass.id = q.assid AND cast(q.desc as integer) between dqmin and dqmax[i] AND s.bid=b.id and p.type=b.type
                       GROUP BY s.id, ass.id, sc.clid, c.sex, c.mt
                       ORDER BY s.id
            loop
                   insert into tb_school_assessment_agg values (stueval.id, stueval.assid, stueval.clid, stueval.sex, stueval.mt, domains[i], stueval.dmarks);
            end loop;
            dqmin := dqmax[i] + 1;
        end loop;

end;
$$ language plpgsql;


CREATE OR REPLACE function agg_school_assess_grade_eng(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int) returns void as $$
declare
  stueval RECORD;
  rung1 text;
  rung2 text;
  rung3 text;
  rung4 text;
begin
  for domaincount in 0..innum
    loop
    rung1 :=indomains[domaincount]||' (0-25%)';
    rung2 :=indomains[domaincount]||' (25-50%)';
    rung3 :=indomains[domaincount]||' (50-75%)';
    rung4 :=indomains[domaincount]||' (75-100%)';
      for stueval in
        SELECT sid, assid,clid,sex,mt, count(case when percentile<= 25 then stuid else null end) as Rung1,
        count(case when percentile between 26 and 50 then stuid else null end) as Rung2,
        count(case when percentile between 51 and 75 then stuid else null end) as Rung3,
        count(case when percentile between 76 and 100 then stuid else null end) as Rung4
        from
        (          select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clid as clid, c.sex as sex,c.mt as mt,  (domainagg*100/inpmarks[domaincount]) as percentile          from
          (            select se.stuid as stuid,
              q.assid as assid,              sg.id as clid,
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
            and stu.cid=c.id)info          group by sid,assid,clid,sex,mt        loop
          insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt,rung1, stueval.Rung1);
          insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt,rung2, stueval.Rung2);
          insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt,rung3, stueval.Rung3);
          insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt,rung4, stueval.Rung4);
        end loop;
   end loop;
end;
$$ language plpgsql;

/*
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
 
*/

CREATE OR REPLACE function agg_school_ang_agemorethan(inyear int,inage int, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int,intext text,intimestamp timestamp) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 0..innum loop
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
          insert into tb_preschool_assessment_agg values (stueval.sid, stueval.assid,intext, stueval.sex, stueval.mt,indomains[domaincount], stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;



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
          insert into tb_preschool_assessment_agg values (stueval.sid, stueval.assid,intext, stueval.sex, stueval.mt,indomains[domaincount], stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;


CREATE OR REPLACE function agg_school_assess_mark(inyear int,inclass text, inassid int,indomains varchar[] ,         inqset varchar[], inpmarks int[],innum int) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 0..innum
    loop
      for stueval in
        SELECT sid, assid,clid,sex,mt, count(case when domainskillcount =1 then stuid else null end) as stucount
        from
        (
          select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clid as clid, c.sex as sex,c.mt as mt,  case when domainagg <inpmarks[domaincount] then 0 else 1 end as domainskillcount
          from
          (  
            select se.stuid as stuid,
              q.assid as assid,
              sg.id as clid,
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
          group by sid,assid,clid,sex,mt
        loop
          insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt,indomains[domaincount], stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;



CREATE OR REPLACE function agg_school_assess_grade(inyear int,inclass text, inassid int,indomains varchar[] , inqset varchar[], inpmarks int[],innum int) returns void as $$
declare
  stueval RECORD;
begin
  for domaincount in 0..innum
    loop
      for stueval in
        SELECT sid, assid,clid,sex,mt, count(case when domainskillcount =1 then stuid else null end) as stucount
        from
        (
          select aggregates.stuid as stuid,aggregates.sid as sid,aggregates.assid as assid,aggregates.clid as clid, c.sex as sex,c.mt as mt,  case when domainagg <inpmarks[domaincount] then 0 else 1 end as domainskillcount
          from
          (  
            select se.stuid as stuid,
              q.assid as assid,
              sg.id as clid,
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
          group by sid,assid,clid,sex,mt
        loop
          insert into tb_school_assessment_agg values (stueval.sid, stueval.assid, stueval.clid, stueval.sex, stueval.mt,indomains[domaincount], stueval.stucount);
        end loop;
   end loop;
end;
$$ language plpgsql;


-- Populate tb_school_agg for the current academic year
select agg_school(101);

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

/*
--Anganwadi
-- 2009 Anganwadi
select agg_school_ang(23, 119);
select agg_school_ang(24, 119);

--2010 Anganwadi
select agg_school_ang(56, 101);
select agg_school_ang(57, 101);
select agg_school_ang(58, 101);
select agg_school_ang(62, 101);
*/
--Anganwadi
-- 2009 Anganwadi
--Pretest
select agg_school_ang_agebetween(119,36,60,23,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],3,'Age between 3-5',cast('2009-04-30' as timestamp));
select agg_school_ang_agemorethan(119,60,23,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],3,'Age >=5',cast('2009-04-30' as timestamp));

--Posttest
select agg_school_ang_agebetween(119,36,60,24,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],3,'Age between 3-5',cast('2009-04-30' as timestamp));
select agg_school_ang_agemorethan(119,60,24,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],3,'Age >=5',cast('2009-04-30' as timestamp));

-- 2010 Anganwadi
--Pretest
select agg_school_ang_agebetween(101,36,60,56,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],3,'Age between 3-5',cast('2010-04-30' as timestamp));
select agg_school_ang_agemorethan(101,60,56,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],3,'Age >=5',cast('2010-04-30' as timestamp));

--Posttest
select agg_school_ang_agebetween(101,36,60,57,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],3,'Age between 3-5',cast('2010-04-30' as timestamp));
select agg_school_ang_agemorethan(101,60,57,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],3,'Age >=5',cast('2010-04-30' as timestamp));


-- 2011 Anganwadi
--Pretest
select agg_school_ang_agebetween(102,36,60,70,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],3,'Age between 3-5',cast('2010-04-30' as timestamp));
select agg_school_ang_agemorethan(102,60,70,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],3,'Age >=5',cast('2010-04-30' as timestamp));

--Posttest
select agg_school_ang_agebetween(102,36,60,79,ARRAY['Gross Motor','Fine Motor','Socio-Emotional','General Awareness'],ARRAY['6,7,8,9','10,11,12,13,14,15','53,54,55,56','1,2,3,4'],ARRAY[4,6,4,4],3,'Age between 3-5',cast('2010-04-30' as timestamp));
select agg_school_ang_agemorethan(102,60,79,ARRAY['Language','Intellectual Development','Socio-Emotional','Pre-Academic'],ARRAY['16,17,18,19,20,21,22,23,24,25,26,27,28','29,30,31,32,33','53,54,55,56','34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52'],ARRAY[13,5,4,19],3,'Age >=5',cast('2010-04-30' as timestamp));

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
select agg_school_assess_grade_eng(102,'1',65,ARRAY['Oral'],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'2',66,ARRAY['Oral','Reading','Writing'],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'3',67,ARRAY['Oral','Reading','Writing'],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);
select agg_school_assess_grade_eng(102,'1',75,ARRAY['Oral'],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a'],ARRAY[11],1);
select agg_school_assess_grade_eng(102,'2',76,ARRAY['Oral','Reading','Writing'],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a','5a,5b,5c','6a,6b,6c,6d,6e,7a,7b,7c'],ARRAY[11,3,8],3);
select agg_school_assess_grade_eng(102,'3',77,ARRAY['Oral','Reading','Writing'],ARRAY['1a,1b,1c,2a,2b,2c,2d,3a,3b,3c,4a,4b,4c,5a,5b,5c,6a','7a,7b,7c,8a,8b,8c','9a,9b,9c,9d,10a,10b,10c'],ARRAY[17,6,7],3);


/*
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
*/

GRANT SELECT ON tb_school_agg,
                tb_school_assessment_agg,
                tb_school_basic_assessment_info
TO web;
