DROP TABLE IF EXISTS "tb_dise_facility_agg";
CREATE TABLE "tb_dise_facility_agg" (
   "dise_code" varchar(32),
   "df_metric" varchar(30),
   "score" numeric(5),
   "df_group" varchar(30)
);

DROP TABLE IF EXISTS "tb_dise_rte_agg";
CREATE TABLE "tb_dise_rte_agg" (
   "dise_code" varchar(32),
   "rte_metric" varchar(36),
   "status" varchar(30),
   "rte_group" varchar(32)
);

CREATE OR REPLACE function agg_dise_facility() returns void as $$
  declare
     agg_record RECORD;
  begin
     for agg_record in select distinct df.school_code,case  when df.building_status in ('2','5','6','7') then 0 else 100 end as perc_total from tb_dise_facility df loop
          insert into tb_dise_facility_agg values (agg_record.school_code, 'building_status' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct df.school_code,case  when to_number(df.classrooms_require_major_repair,'999') + to_number(df.classrooms_require_minor_repair,'999') > 0 then 100 else 0 end as perc_total from  tb_dise_facility df loop
insert into tb_dise_facility_agg values (agg_record.school_code, 'classroom_repair' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct df.school_code,case when to_number(toilet_common,'999') + to_number(toilet_boys,'999') + to_number(toilet_girls,'999') > 0 then 100 else 0 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'toilet_all' ,agg_record.perc_total,'Toilet Facilities');
     end loop;
     for agg_record in select distinct df.school_code,case when to_number(toilet_girls,'999') > 0 then 100 else 0 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'toilet_girl' ,agg_record.perc_total,'Toilet Facilities');
     end loop;
     for agg_record in select distinct df.school_code,case when status_of_mdm in ('0','1') then 0 else 100 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'status_mdm' ,agg_record.perc_total,'Nutrition and Hygiene');
     end loop;
     for agg_record in select distinct df.school_code,case when computer_aided_learnin_lab = '1' and to_number(no_of_computers,'999') > 0 then 100 else 0 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'computer_lab' ,agg_record.perc_total,'Learning Environment');
     end loop;
     for agg_record in select distinct df.school_code,case when separate_room_for_headmaster = '1'  then 100 else 0 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'room_for_hm' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct df.school_code,case when electricity = '1'  then 100 else 0 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'electricity' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct df.school_code,case when boundary_wall in ('1','4','3')  then 100 else 0 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'boundary_wall' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct df.school_code,case when library_yn = '1' and to_number(books_in_library,'999') > 0 then 100 else 0 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'library' ,agg_record.perc_total,'Learning Environment');
     end loop;
     for agg_record in select distinct df.school_code,case when playground = '1' then 100 else 0 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'playground' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct df.school_code,case when to_number(blackboard,'999') >= to_number(tot_clrooms,'999') then 100 else 0 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'blackboard_sch' ,agg_record.perc_total,'Learning Environment');
     end loop;
     for agg_record in select distinct df.school_code,case when drinking_water = '1' then 100 else 0 end as perc_total from  tb_dise_facility df loop
      insert into tb_dise_facility_agg values (agg_record.school_code, 'drinking_water_sch' ,agg_record.perc_total,'Nutrition and Hygiene');
     end loop;
     for agg_record in select distinct df.school_code,case  when df.ramps in ('2','0') then 0 else 100 end as perc_total from tb_dise_facility df loop
          insert into tb_dise_facility_agg values (agg_record.school_code, 'ramp' ,agg_record.perc_total,'Basic Infrastructure');
     end loop;
     for agg_record in select distinct df.school_code,case  when df.medical_checkup in ('2') then 0 else 100 end as perc_total from tb_dise_facility df loop
          insert into tb_dise_facility_agg values (agg_record.school_code, 'medical' ,agg_record.perc_total,'Nutrition and Hygiene');
     end loop;
end;
$$ language plpgsql;

CREATE OR REPLACE function agg_dise_rte() returns void as $$
  declare
     agg_record RECORD;
  begin
     for agg_record in select distinct dr.schcd,case  when dr.mdm_source='1' then 'Kitchen within School' when mdm_source='2' then 'NGO' when mdm_source='3' then 'Self Help Group' when mdm_source='4' then 'PTA/MTA' when mdm_source='6' then 'Gram Panchayat' else 'Other source' end as value from tb_dise_rte dr loop
          insert into tb_dise_rte_agg values (agg_record.schcd, 'mdm_source' ,agg_record.value,'Mid-day Meal Facilities');
     end loop;
     for agg_record in select distinct dr.schcd, dr.days_meals_served  as value from tb_dise_rte dr loop
          insert into tb_dise_rte_agg values (agg_record.schcd, 'days_meals_served' ,agg_record.value,'Mid-day Meal Facilities');
     end loop;
     for agg_record in select distinct dr.schcd, dr.meals_served_prev_yr as value from tb_dise_rte dr loop
          insert into tb_dise_rte_agg values (agg_record.schcd, 'meals_served_prev_yr' ,agg_record.value,'Mid-day Meal Facilities');
     end loop;
     for agg_record in select distinct dr.schcd, dr.students_opted_mdm_b as value from tb_dise_rte dr loop
          insert into tb_dise_rte_agg values (agg_record.schcd, 'students_opted_mdm_b' ,agg_record.value,'Mid-day Meal Facilities');
     end loop;
     for agg_record in select distinct dr.schcd, dr.stdents_opted_mdm_g as value from tb_dise_rte dr loop
          insert into tb_dise_rte_agg values (agg_record.schcd, 'students_opted_mdm_g' ,agg_record.value,'Mid-day Meal Facilities');
     end loop;
     for agg_record in select distinct dr.schcd,case  when dr.smc_constituted='1' then 'Yes' else 'No' end as value from tb_dise_rte dr loop
          insert into tb_dise_rte_agg values (agg_record.schcd, 'smc_constituted' ,agg_record.value,'SDMC Details');
     end loop;
     for agg_record in select distinct dr.schcd, dr.smc_members_male as value from tb_dise_rte dr loop
		           insert into tb_dise_rte_agg values (agg_record.schcd, 'smc_members_male' ,agg_record.value,'SDMC Details');
     end loop;
     for agg_record in select distinct dr.schcd, dr.smc_members_female as value from tb_dise_rte dr loop
		           insert into tb_dise_rte_agg values (agg_record.schcd, 'smc_members_female' ,agg_record.value,'SDMC Details');
     end loop;
     for agg_record in select distinct dr.schcd, dr.smc_members_parents_male as value from tb_dise_rte dr loop
		           insert into tb_dise_rte_agg values (agg_record.schcd, 'smc_members_parents_male' ,agg_record.value,'SDMC Details');
     end loop;
     for agg_record in select distinct dr.schcd, dr.smc_members_parents_female as value from tb_dise_rte dr loop
		           insert into tb_dise_rte_agg values (agg_record.schcd, 'smc_members_parents_female' ,agg_record.value,'SDMC Details');
     end loop;
     for agg_record in select distinct dr.schcd, dr.smc_members_local_authority_male as value from tb_dise_rte dr loop
		           insert into tb_dise_rte_agg values (agg_record.schcd, 'smc_members_local_authority_male' ,agg_record.value,'SDMC Details');
     end loop;
     for agg_record in select distinct dr.schcd, dr.smc_members_local_authority_female as value from tb_dise_rte dr loop
		           insert into tb_dise_rte_agg values (agg_record.schcd, 'smc_members_local_authority_female' ,agg_record.value,'SDMC Details');
     end loop;
     for agg_record in select distinct dr.schcd, dr.smc_meetings_held as value from tb_dise_rte dr loop
		           insert into tb_dise_rte_agg values (agg_record.schcd, 'smc_meetings_held' ,agg_record.value,'SDMC Details');
     end loop;
  end;
$$ language plpgsql;

select agg_dise_facility() ;
select agg_dise_rte() ;
