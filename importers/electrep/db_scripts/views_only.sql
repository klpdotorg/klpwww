CREATE OR REPLACE VIEW vw_electoral_coord as
       select * from dblink('host=localhost dbname=klp-coord user=klp password=1q2w3e4r', 'select * from electoral_coord')
       as t1 (id_bndry integer,
              type varchar(20),
              coord geometry);


CREATE OR REPLACE VIEW vw_paisa_data as
       select * from dblink('host=localhost dbname=dise_2012 user=klp password=1q2w3e4r', 'select * from tb_paisa_data')
       as t1 (
  grant_type character varying(32),
  grant_amount integer,
  criteria character varying(32),
  operator character varying(3),
  factor character varying(32)
 );

CREATE OR REPLACE VIEW vw_dise_info as
select * from dblink('host=localhost dbname=dise_2012 user=klp password=1q2w3e4r', 'select df.school_code, to_number(df.tot_clrooms,''999''), to_number(df.male_tch,''999'') + to_number(df.female_tch,''999'') - to_number(df.noresp_tch,''999''),
 to_number(de.class1_total_enr_boys,''999'') +
 to_number(de. class2_total_enr_boys,''999'') +
 to_number(de. class3_total_enr_boys,''999'') +
 to_number(de. class4_total_enr_boys,''999'') +
 to_number(de. class5_total_enr_boys,''999'') +
 to_number(de. class6_total_enr_boys,''999'') +
 to_number(de. class7_total_enr_boys,''999'') +
 to_number(de. class8_total_enr_boys,''999'') ,
 to_number(de. class1_total_enr_girls,''999'') +
 to_number(de. class2_total_enr_girls,''999'') +
 to_number(de. class3_total_enr_girls,''999'') +
 to_number(de. class4_total_enr_girls,''999'') +
 to_number(de. class5_total_enr_girls,''999'') +
 to_number(de. class6_total_enr_girls,''999'') +
 to_number(de. class7_total_enr_girls,''999'') +
 to_number(de. class8_total_enr_girl,''999''),
 to_number(dg.lowest_class,''999''),
 to_number(dg.highest_class,''999''),
 de.acyear,
 to_number(dg.school_dev_grant_recd,''99999''),
 to_number(dg.school_dev_grant_expnd,''99999''),
 to_number(dg.tlm_grant_recd,''99999''),
 to_number(dg.tlm_grant_expnd,''99999''),
 to_number(dg.funds_from_students_recd,''999999''),
 to_number(dg.funds_from_students_expnd,''999999''),
 to_number(df.books_in_library,''999999'')
from tb_dise_facility df,tb_dise_enrol de,tb_dise_general dg where de.school_code=df.school_code and de.school_code=dg.school_code')
as t1 (
  dise_code character varying(32),
  classroom_count integer,
  teacher_count integer,
  boys_count integer,
  girls_count integer,
  lowest_class integer,
  highest_class integer,
  acyear character varying(15),
  sg_recd integer,
  sg_expnd integer,
  tlm_recd integer,
  tlm_expnd integer,
  ffs_recd integer,
  ffs_expnd integer,
  books_in_library integer
);

CREATE OR REPLACE VIEW vw_school_dise as
       select * from dblink('host=localhost dbname=klpwww_ver4 user=klp password=1q2w3e4r', 'select d.id as dist_id, d.name as district,b.id as blck_id, b.name as block,c.id as clst.id, c.name as clus,s.id,s.name,s.dise_code,s.cat,s.moi,d.type from tb_school s,tb_boundary c, tb_boundary b, tb_boundary d where s.bid=c.id and c.parent=b.id and b.parent=d.id')
       as t1 (
  dist_id integer,
  district character varying(100),
  blck_id integer,
  block character varying(100),
  clst_id integer,
  clust character varying(100),
  sid integer,
  name character varying(100),
  dise_code character varying(32),
  cat school_category,
  moi school_moi,
  type integer
 );


CREATE OR REPLACE VIEW vw_libinfra as
select * from dblink('host=localhost dbname=libinfra user=klp password=1q2w3e4r', 'select * from tb_libinfra')
as t1 (
  sid integer,
  libstatus  character varying(300),
  handoveryear integer ,
  libtype character varying(300),
  numbooks integer,
  numracks integer,
  numtables integer,
  numchairs integer,
  numcomputers integer,
  numups integer
);

CREATE OR REPLACE VIEW vw_ang_infra_agg as
select * from dblink('host=localhost dbname=ang_infra user=klp password=1q2w3e4r', 'select * from tb_ang_infra_agg')
as t1 (
   sid integer,
   ai_metric character varying(30),
   perc_score numeric(5,0),
   ai_group character varying(30)
);

CREATE OR REPLACE VIEW vw_ai_questions as
select * from dblink('host=localhost dbname=ang_infra user=klp password=1q2w3e4r', 'select * from tb_ai_questions')
as t1 (
  id integer,
  question character varying(200)
);

CREATE OR REPLACE VIEW vw_dise_facility_agg as
select * from dblink('host=localhost dbname=dise_2012 user=klp password=1q2w3e4r', 'select * from tb_dise_facility_agg')
as t1 (
   dise_code character varying(32),
   df_metric character varying(30),
   score numeric(5,0),
   df_group character varying(30)
);

CREATE OR REPLACE VIEW vw_lib_lang_agg as
select * from dblink('host=localhost dbname=library user=klp password=1q2w3e4r', 'select * from lang_agg')
as t1 (
   sid integer,
   class integer,
   month character varying(10),
   year character varying(10),
   book_lang character varying(50),
   child_count integer
);

CREATE OR REPLACE VIEW vw_lib_level_agg as
select * from dblink('host=localhost dbname=library user=klp password=1q2w3e4r', 'select * from level_agg')
as t1 (
   sid integer,
   class integer,
   month character varying(10),
   year character varying(10),
   book_level character varying(50),
   child_count integer
);

CREATE OR REPLACE VIEW vw_mdm_agg as
select * from dblink('host=localhost dbname=apmdm user=klp password=1q2w3e4r', 'select * from tb_mdm_agg')
as t1 (
   id integer,
   mon character varying(15), 
   wk integer,
   indent integer,
   attend integer 
);

CREATE OR REPLACE VIEW vw_angpre_2011_agg as
select * from dblink('host=localhost dbname=klpwww_ver4 user=klp password=1q2w3e4r', 'select * from tb_angpre_2011_agg')
as t1 (
    sid integer,
    gender varchar(8),
    stucount integer,
    min_score integer,
    max_score integer,
    median_score integer,
    avg_score integer
);

CREATE OR REPLACE VIEW vw_reading_2011_agg as
select * from dblink('host=localhost dbname=libreading user=klp password=1q2w3e4r', 'select * from tb_assess_agg') as t1 (
    sid integer,
    acyear character varying(12),
    gender character varying(4),
    class  integer,
    grade  character varying(12),
    stucount integer
); 
