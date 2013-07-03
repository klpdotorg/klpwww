DROP TABLE tb_angpre_2011_agg;
CREATE TABLE tb_angpre_2011_agg
(
    sid integer,
    gender varchar(8),
    stucount integer,
    min_score integer,
    max_score integer,
    median_score integer,
    avg_score integer
);

CREATE OR REPLACE function agg_angpre2011_agg() returns void as $$
  declare
       agg RECORD;
  begin
       for agg in
         select presc.sid as sid ,presc.gender as gender, count(distinct presc.stuid) as stucount, min(presc.totscore)::int as min_score,max(presc.totscore)::int as max_score,median(presc.totscore)::int as median_score,avg(presc.totscore)::int as avg_score from (select distinct s.stuid as stuid, c.sex as gender, sg.sid, sum(s.grade::int) as totscore from tb_student stu, tb_child c, tb_student_eval s, tb_student_class ssg, tb_class sg where s.stuid=ssg.stuid and stu.id=s.stuid and stu.cid=c.id and ssg.clid=sg.id and ssg.ayid=102 and s.qid in (select distinct id from tb_question where assid =70 ) group by c.sex,s.stuid,sg.sid ) as presc group by presc.sid,presc.gender
       loop
         insert into tb_angpre_2011_agg (sid,gender,stucount,min_score,max_score,median_score,avg_score) values (agg.sid,agg.gender,agg.stucount,agg.min_score,agg.max_score,agg.median_score,agg.avg_score);
       end loop;
  end;
$$ language plpgsql;

select agg_angpre2011_agg() ;
