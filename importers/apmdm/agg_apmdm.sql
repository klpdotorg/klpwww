DROP TABLE IF EXISTS "tb_mdm_agg";
CREATE TABLE "tb_mdm_agg" (
   "id" integer,
   "mon" varchar(15),
   "wk" integer,
   "indent" integer,
   "attend" integer
);


CREATE OR REPLACE function agg_mdm() returns void as $$
  declare
     sch RECORD;
     date RECORD;
     agg RECORD;
  begin
     for sch in 
       select distinct id as id from tb_middaymeal
     loop
       for date in
         select distinct mon as mon from tb_middaymeal where id=sch.id
       loop
         for agg in
           select avg(coalesce(indent_onetofive,0)) + avg(coalesce(indent_sixtoseven,0)) + avg(coalesce(indent_eight,0)) + avg(coalesce(indent_ninetoten,0)) as i_avg,
                  avg(coalesce(attend_onetofive,0)) + avg(coalesce(attend_sixtoseven,0)) + avg(coalesce(attend_eight,0)) + avg(coalesce(attend_ninetoten,0)) as a_avg
                  from tb_middaymeal where to_number(dy,'99') between 1 and 8 and mon=date.mon and id=sch.id
         loop
           insert into tb_mdm_agg (id,mon,wk,indent,attend) values (sch.id,date.mon,1,agg.i_avg,agg.a_avg);
         end loop;
         for agg in
           select avg(coalesce(indent_onetofive,0)) + avg(coalesce(indent_sixtoseven,0)) + avg(coalesce(indent_eight,0)) + avg(coalesce(indent_ninetoten,0)) as i_avg,
                  avg(coalesce(attend_onetofive,0)) + avg(coalesce(attend_sixtoseven,0)) + avg(coalesce(attend_eight,0)) + avg(coalesce(attend_ninetoten,0)) as a_avg
                  from tb_middaymeal where to_number(dy,'99') between 8 and 15 and mon=date.mon and id=sch.id
         loop
           insert into tb_mdm_agg (id,mon,wk,indent,attend) values (sch.id,date.mon,2,agg.i_avg,agg.a_avg);
         end loop;
         for agg in
           select avg(coalesce(indent_onetofive,0)) + avg(coalesce(indent_sixtoseven,0)) + avg(coalesce(indent_eight,0)) + avg(coalesce(indent_ninetoten,0)) as i_avg,
                  avg(coalesce(attend_onetofive,0)) + avg(coalesce(attend_sixtoseven,0)) + avg(coalesce(attend_eight,0)) + avg(coalesce(attend_ninetoten,0)) as a_avg
                  from tb_middaymeal where to_number(dy,'99') between 15 and 22 and mon=date.mon and id=sch.id
         loop
           insert into tb_mdm_agg (id,mon,wk,indent,attend) values (sch.id,date.mon,3,agg.i_avg,agg.a_avg);
         end loop;
         for agg in
           select avg(coalesce(indent_onetofive,0)) + avg(coalesce(indent_sixtoseven,0)) + avg(coalesce(indent_eight,0)) + avg(coalesce(indent_ninetoten,0)) as i_avg,
                  avg(coalesce(attend_onetofive,0)) + avg(coalesce(attend_sixtoseven,0)) + avg(coalesce(attend_eight,0)) + avg(coalesce(attend_ninetoten,0)) as a_avg
                  from tb_middaymeal where to_number(dy,'99') between 22 and 32 and mon=date.mon and id=sch.id
         loop
           insert into tb_mdm_agg (id,mon,wk,indent,attend) values (sch.id,date.mon,4,agg.i_avg,agg.a_avg);
         end loop;
       end loop;
     end loop;
  end;
$$ language plpgsql;

select agg_mdm() ;
