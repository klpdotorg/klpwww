-- Schema creation script for KLP intermediate DB
-- This DB is for populating EMS DB

-- This code is released under the terms of the GNU GPL v3 
-- and is free software
drop table "tb_dise_basic";
create table "tb_dise_basic"
(
  district character varying(32),
  disecode character varying(32),
  schoolname character varying(125),
  block character varying(32),
  clus character varying(32),
  village character varying(125),
  pincode character varying(32)
);


drop table "tb_dise_facility";
create table "tb_dise_facility"
(
  school_code character varying(32), 
  building_status character varying(3), 
  tot_clrooms character varying(3), 
  classrooms_in_good_condition character varying(3), 
  classrooms_require_major_repair character varying(3), 
  classrooms_require_minor_repair character varying(3), 
  other_rooms_in_good_cond character varying(3), 
  other_rooms_need_major_rep character varying(3), 
  other_rooms_need_minor_rep character varying(3), 
  toilet_common character varying(3), 
  toilet_boys character varying(3), 
  toilet_girls character varying(3), 
  kitchen_devices_grant character varying(10), 
  status_of_mdm character varying(3), 
  computer_aided_learnin_lab character varying(3), 
  separate_room_for_headmaster character varying(3), 
  electricity character varying(3), 
  boundary_wall character varying(3), 
  library_yn character varying(3), 
  playground character varying(3), 
  blackboard character varying(3), 
  books_in_library character varying(10), 
  drinking_water character varying(3), 
  medical_checkup character varying(3), 
  ramps character varying(3), 
  no_of_computers character varying(3), 
  male_tch character varying(3), 
  female_tch character varying(3), 
  noresp_tch character varying(3), 
  head_teacher character varying(3), 
  graduate_teachers character varying(3), 
  tch_with_professional_qualification character varying(3), 
  days_involved_in_non_tch_assgn character varying(3), 
  teachers_involved_in_non_tch_assgn character varying(3)
);

drop table "tb_dise_general";
create table "tb_dise_general"
(
  school_code character varying(32), 
  rural_urban character varying(3), 
  medium_of_instruction character varying(3), 
  distance_brc character varying(3), 
  distance_crc character varying(3), 
  yeur_estd character varying(10), 
  pre_pry_yn character varying(3), 
  residential_sch_yn character varying(3), 
  sch_management character varying(3), 
  lowest_class character varying(3), 
  highest_class character varying(3), 
  sch_category character varying(3), 
  pre_pry_students character varying(5), 
  school_type character varying(3), 
  shift_school_yn character varying(3), 
  no_of_working_days character varying(3), 
  no_of_acad_inspection character varying(3), 
  residential_sch_type character varying(3), 
  pre_pry_teachers character varying(323), 
  visits_by_brc character varying(3), 
  visits_by_crc character varying(3), 
  school_dev_grant_recd character varying(5), 
  school_dev_grant_expnd character varying(5), 
  tlm_grant_recd character varying(5), 
  tlm_grant_expnd character varying(5), 
  funds_from_students_recd character varying(5), 
  funds_from_students_expnd character varying(5)
);

drop table "tb_dise_rte";
create table "tb_dise_rte"
(
  schcd character varying(32), 
  acyear character varying(10), 
  working_days_primary character varying(4), 
  working_days_uprimary character varying(4), 
  schoool_hours_children_pri character varying(5), 
  school_hours_children_upri character varying(5), 
  school_hours_tch_p character varying(5), 
  school_hours_tch_upr character varying(5), 
  approachable_by_all_weather_road character varying(3), 
  cce_implemented character varying(3), 
  people_cumilativere_record_maintained character varying(3), 
  pcr_shared_with_parents character varying(3), 
  children_from_weaker_section_applied character varying(5), 
  children_from_weaker_section_enrolled character varying(5), 
  aid_received character varying(3), 
  chilren_admitted_for_free_education character varying(5), 
  smc_constituted character varying(3), 
  smc_members_male character varying(3), 
  smc_members_female character varying(3), 
  smc_members_parents_male character varying(3), 
  smc_members_parents_female character varying(3), 
  smc_members_local_authority_male character varying(3), 
  smc_members_local_authority_female character varying(3), 
  smc_meetings_held character varying(3), 
  school_developmentplan_prepared character varying(3), 
  smc_children_record_maintained character varying(3), 
  chld_enrolled_for_sp_training_current_year_b character varying(3), 
  chld_enrolled_for_sp_training_current_year_g character varying(3), 
  spl_training_provided_current_year_b character varying(3), 
  spl_training_provided_current_year_g character varying(3), 
  spl_training_enrolled_previous_year_b character varying(3), 
  spl_training_enrolled_previous_year_g character varying(3), 
  spl_training_provided_previous_year_b character varying(3), 
  spl_training_provided_previous_year_g character varying(3), 
  spl_training_conducted_by character varying(3), 
  spl_training_place character varying(3), 
  spl_training_type character varying(3), 
  tch_or_evs_for_spl_training character varying(3), 
  spl_training_material character varying(3), 
  textbook_received character varying(5), 
  text_book_received_month character varying(12), 
  text_book_received_year character varying(10), 
  academic_session_start_in character varying(10), 
  mdm_status character varying(3), 
  kitchenshed_status character varying(3), 
  mdm_source character varying(125), 
  days_meals_served character varying(10), 
  meals_served_prev_yr character varying(10), 
  students_opted_mdm_b character varying(5), 
  stdents_opted_mdm_g character varying(5), 
  kitchen_devaices_grant character varying(5), 
  cook_m character varying(3), 
  cook_f character varying(3), 
  inspections_by_so character varying(3), 
  inspections_by_cm character varying(3)
);


drop table "tb_dise_teacher";
create table "tb_dise_teacher"
(
  school_code character varying(32), 
  male_tch character varying(3), 
  female_tch character varying(3), 
  noresp_tch character varying(3), 
  head_teacher character varying(3), 
  graduate_teachers character varying(3), 
  tch_with_professional_qualification character varying(3), 
  days_invol character varying(5), 
  ved_in_non_tch_assgn character varying(5), 
  teachers_involved_in_non_tch_assgn character varying(3)
);

drop table "tb_dise_enrol";
create table "tb_dise_enrol"
(
  school_code character varying(32),
  acyear character varying(12),
  class1_total_enr_boys character varying(6),
  class2_total_enr_boys character varying(6),
  class3_total_enr_boys character varying(6),
  class4_total_enr_boys character varying(6),
  class5_total_enr_boys character varying(6),
  class6_total_enr_boys character varying(6),
  class7_total_enr_boys character varying(6),
  class8_total_enr_boys character varying(6),
  class1_total_enr_girls character varying(6),
  class2_total_enr_girls character varying(6),
  class3_total_enr_girls character varying(6),
  class4_total_enr_girls character varying(6),
  class5_total_enr_girls character varying(6),
  class6_total_enr_girls character varying(6),
  class7_total_enr_girls character varying(6),
  class8_total_enr_girl character varying(6)
);

DROP TABLE IF EXISTS "tb_paisa_data" cascade;
CREATE TABLE "tb_paisa_data" (
  "grant_type" character varying(32),
  "grant_amount" integer,
  "criteria" character varying(32), -- possible values teacher_count, classroom_count, school_cat
  "operator" character varying(3), -- possible values gt - greater than,eq - equal to, per - multiply, lt - less than
  "factor" character varying(32)
);

insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('maintenance',10000,'classroom_count','gt', '3');
insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('maintenance',5000,'classroom_count','lt', '3');
insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('tlm',500,'teacher_count','per', null);
insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('annual',5000,'school_cat','eq','Lower Primary');
insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('annual',7000,'school_cat','eq','Upper Primary');
insert into tb_paisa_data (grant_type,grant_amount,criteria,operator,factor) values ('annual',7000,'school_cat','eq','Model Primary');
-- Assumption that all model primaries are upper primary

drop table tb_display_master;
create table tb_display_master(
   key varchar(36),
   value varchar(200)
);
insert into tb_display_master values ('library',' Has a Library with Books');
insert into tb_display_master values ('toilet_all',' Has Common Toilets');
insert into tb_display_master values ('building_status',' Is in a Rent-free Pucca Building');
insert into tb_display_master values ('electricity',' Has Electricity Supply');
insert into tb_display_master values ('toilet_girl',' Has Separate Toilets for Girls ');
insert into tb_display_master values ('blackboard_sch',' Has Blackboards for all Classrooms');
insert into tb_display_master values ('boundary_wall',' Has Secure Boundary walls');
insert into tb_display_master values ('room_for_hm',' Has a Separate Room for the Head Master');
insert into tb_display_master values ('playground',' Has a Playground');
insert into tb_display_master values ('drinking_water_sch',' Has Drinking Water Facilities');
insert into tb_display_master values ('classroom_repair',' Has Classrooms That Need No Repairs');
insert into tb_display_master values ('computer_lab',' Has a Computer Lab');
insert into tb_display_master values ('status_mdm',' Has Mid-day Meal facility');
insert into tb_display_master values ('ramp',' Has a ramp for disabled children');
insert into tb_display_master values ('medical',' Had a medical camp in the previous year');
insert into tb_display_master values ('mdm_source','Source of Mid-day meal');
insert into tb_display_master values ('days_meals_served','Number of days meals were served last year');
insert into tb_display_master values ('meals_served_prev_yr','Number of meals served last year');
insert into tb_display_master values ('students_opted_mdm_b','Number of boys opting for meals');
insert into tb_display_master values ('students_opted_mdm_g','Number of girls opting for meals');
insert into tb_display_master values ('smc_constituted','Has the SDMC been constituted?');
insert into tb_display_master values ('smc_members_male','Number of male members');
insert into tb_display_master values ('smc_members_female','Number of female members');
insert into tb_display_master values ('smc_members_parents_male','Number of male parent-members');
insert into tb_display_master values ('smc_members_parents_female','Number of female parent-members');
insert into tb_display_master values ('smc_members_local_authority_male','Number of male Local leaders');
insert into tb_display_master values ('smc_members_local_authority_female','Number of female Local leaders');
insert into tb_display_master values ('smc_meetings_held','Number of meetings held last year');
                                                               
