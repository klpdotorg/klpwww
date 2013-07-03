CREATE OR REPLACE function agg_libreading() returns void as $$
  declare
       agg RECORD;
  begin
       for agg in
         select distinct klpid,acadyear,class,gender,grade,count(distinct studentid) as stucount from tb_assessment group by klpid,class,grade,gender,acadyear
       loop
         insert into tb_assess_agg (sid,acyear,class,gender,grade,stucount) values (agg.klpid,agg.acadyear,agg.class,agg.gender,agg.grade,agg.stucount);
       end loop;
  end;
$$ language plpgsql;

select agg_libreading() ;
