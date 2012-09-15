DROP TABLE IF EXISTS "tb_dise_facility_agg";
CREATE TABLE "tb_dise_facility_agg" (
   "sid" integer,
   "df_metric" varchar(30),
   "score" numeric(5),
   "df_group" varchar(30)
);

CREATE OR REPLACE function agg_dise_facility() returns void as $$
  declare
     agg_record RECORD;
  begin
     for agg_record in select distinct sd.sid,case  when df.building_status in (2,5,6,7) then 0 else 100 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
          insert into tb_dise_facility_agg values (agg_record.sid, 'building_status' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct sd.sid,case  when df.classroom_major_repair + df.classroom_minor_repair > 0 then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
insert into tb_dise_facility_agg values (agg_record.sid, 'classroom_repair' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct sd.sid,case when toilet_tommon + toilet_boys + toilet_girls > 0 then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'toilet_all' ,agg_record.perc_total,'Toilet Facilities');
     end loop;
     for agg_record in select distinct sd.sid,case when toilet_girls > 0 then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'toilet_girl' ,agg_record.perc_total,'Toilet Facilities');
     end loop;
     for agg_record in select distinct sd.sid,case when status_of_mdm in (0,1) then 0 else 100 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'status_mdm' ,agg_record.perc_total,'Nutrition and Hygiene');
     end loop;
     for agg_record in select distinct sd.sid,case when computer_lab = 1 and no_of_computers > 0 then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'computer_lab' ,agg_record.perc_total,'Learning Environment');
     end loop;
     for agg_record in select distinct sd.sid,case when room_for_hm = 1  then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'room_for_hm' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct sd.sid,case when electricity = 1  then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'electricity' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct sd.sid,case when boundary_wall in (1,4,3)  then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'boundary_wall' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct sd.sid,case when library = 1 and books_in_library > 0 then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'library' ,agg_record.perc_total,'Learning Environment');
     end loop;
     for agg_record in select distinct sd.sid,case when playground = 1 then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'playground' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct sd.sid,case when blackboard >= classroom_count then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'blackboard_sch' ,agg_record.perc_total,'Learning Environment');
     end loop;
     for agg_record in select distinct sd.sid,case when drinking_water = 1 then 100 else 0 end as perc_total from tb_school_dise sd, tb_dise_facility df where sd.dise_code= df.dise_id loop
      insert into tb_dise_facility_agg values (agg_record.sid, 'drinking_water_sch' ,agg_record.perc_total,'Nutrition and Hygiene');
     end loop;
end;
$$ language plpgsql;

select agg_dise_facility() ;
