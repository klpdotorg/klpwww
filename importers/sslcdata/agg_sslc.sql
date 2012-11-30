drop table tb_subject;
create table tb_subject (
	subject_code character varying(3),
	subject_name character varying(100)
);

insert into tb_subject values ('01','KANNADA');
insert into tb_subject values ('04','TELUGU');
insert into tb_subject values ('06','HINDI');
insert into tb_subject values ('08','MARATHI');
insert into tb_subject values ('10','TAMIL');
insert into tb_subject values ('12','URDU');
insert into tb_subject values ('14','ENGLISH');
insert into tb_subject values ('16','SANSKRIT');
insert into tb_subject values ('31','ENGLISH');
insert into tb_subject values ('33','KANNADA');
insert into tb_subject values ('55','ALTERNATIVE ENGLISH');
insert into tb_subject values ('61','HINDI');
insert into tb_subject values ('62','KANNADA');
insert into tb_subject values ('63','ENGLISH');
insert into tb_subject values ('64','ARABIC');
insert into tb_subject values ('65','PERSIAN');
insert into tb_subject values ('67','SANSKRIT');
insert into tb_subject values ('81','MATHEMATICS');
insert into tb_subject values ('83','SCIENCE');
insert into tb_subject values ('85','SOCIAL SCIENCE');
insert into tb_subject values ('91','INDIAN SOCIOLOGY');
insert into tb_subject values ('92','INDIAN ECONOMICS');
insert into tb_subject values ('93','INDIAN POLITICS & CIVICS');
insert into tb_subject values ('94','MUSIC');
insert into tb_subject values ('71','ELEMENTS OF ENGINEERING');
insert into tb_subject values ('72','ENGINEERING DRAWING');
insert into tb_subject values ('73','ELEMENTS OF ELECTRONIC ENGINEERING');
insert into tb_subject values ('74','ELEMENTS OF COMPUTER SCIENCE');

drop table tb_district;
create table tb_district (
	dist_code character varying(3),
	dist_name character varying(32)
);

insert into tb_district values ('GA','UDUPI');
insert into tb_district values ('PA','SIRSI');
insert into tb_district values ('LL','HASSAN');
insert into tb_district values ('DD','TUMKUR');
insert into tb_district values ('NA','CHIKODI');
insert into tb_district values ('PP','UTTARA KANNADA');
insert into tb_district values ('GG','MANGALORE');
insert into tb_district values ('FF','MANDYA');
insert into tb_district values ('BA','RAMNAGARA');
insert into tb_district values ('MA','HAVERI');
insert into tb_district values ('JJ','CHICKAMAGALUR');
insert into tb_district values ('EE','MYSORE');
insert into tb_district values ('HH','KODAGU');
insert into tb_district values ('NN','BELGAUM');
insert into tb_district values ('II','CHITRADURGA');
insert into tb_district values ('OA','BAGALKOTE');
insert into tb_district values ('IA','DAVANAGERE');
insert into tb_district values ('BB','BANGALORE RURAL');
insert into tb_district values ('KK','SHIMOGA');
insert into tb_district values ('MM','DHARWAD');
insert into tb_district values ('CC','KOLAR');
insert into tb_district values ('MB','GADAG');
insert into tb_district values ('RR','RAICHUR');
insert into tb_district values ('AS','BANGALORE SOUTH');
insert into tb_district values ('TT','BELLARY');
insert into tb_district values ('RA','KOPPAL');
insert into tb_district values ('AN','BANGALORE NORTH');
insert into tb_district values ('EA','CHAMARAJANAGAR');
insert into tb_district values ('DA','MADHUGIRI');
insert into tb_district values ('QQ','GULBARGA');
insert into tb_district values ('CA','CHIKKABALLAPUR');
insert into tb_district values ('OO','BIJAPUR');
insert into tb_district values ('QA','YADGIR');
insert into tb_district values ('SS','BIDAR');

update tb_sslcresults set s1_marks = '94E50' where reg_no ='20050714599' and s1_marks='094E50';
update tb_sslcresults set s1_marks = '81K45' where reg_no ='20050231862' and s1_marks='81EK45';
update tb_sslcresults set s2_marks = '83K42' where reg_no ='20050231862' and s2_marks='83EK42';
update tb_sslcresults set s3_marks = '85K38' where reg_no ='20050231862' and s3_marks='85EK38';

drop table tb_sslc_sch_agg;
create table tb_sslc_sch_agg (
	dist_code character varying(3),
	ayid integer,
	is_govt character varying(3),
        sch_count integer,
        tot_stu_count integer,
        pass_stu_count integer
);

drop table tb_sslc_agg;
create table tb_sslc_agg (
	dist_code character varying(3),
	ayid integer,
	gender_code character varying(3),
	medium character varying(3),
	is_govt character varying(3),
        tot_stu_count integer,
        pass_stu_count integer,
	sub_code character varying(5),
	sub_avg_marks integer
);

CREATE OR REPLACE function agg_sslc_counts() returns void as $$
declare
  district RECORD;
begin
      for district in
        select distinct dist_code, cast(ayid as int),case when schoolname like '%GOVT%' then 'G' when schoolname like '%CORPORATION%' then 'G' when schoolname like '%GOVERNMENT%' then 'G' else 'N' end as is_govt, count(distinct schoolname) as sch_count, count(distinct reg_no) as tot_stu_count, sum(case when result='P' then 1 else 0 end) as pass_stu_count from tb_sslcresults group by dist_code,is_govt,ayid
        loop
          insert into tb_sslc_sch_agg values (district.dist_code,district.ayid,district.is_govt,district.sch_count,district.tot_stu_count,district.pass_stu_count);
        end loop;
end;
$$ language plpgsql;

CREATE OR REPLACE function agg_sslc_results(marks_col_name text, res_col_name text) returns void as $$
declare
  in_marks_col alias for $1;
  in_res_col alias for $2;
  district RECORD;
begin
      for district in
        execute 'select distinct dist_code, cast(ayid as int), gender_code, medium, case when schoolname like ''%GOVT%'' then ''G'' when schoolname like ''%CORPORATION%'' then ''G'' when schoolname like ''%GOVERNMENT%'' then ''G'' else ''N'' end as is_govt,
				count(distinct reg_no) as tot_stu_count, 
				sum(case when ' || quote_ident(in_res_col) || '= ''P'' then 1 else 0 end) as pass_stu_count,
				substring(' || quote_ident(in_marks_col) || ' from 1 for 2) as sub_code ,
				avg(cast (nullif(nullif(trim(leading ''*'' from substring(' || quote_ident(in_marks_col) || ' from 4)),''888''),'''') as int)) as sub_avg_marks
				from tb_sslcresults 
				group by dist_code, sub_code, ayid,gender_code,medium,is_govt'
      loop
          insert into tb_sslc_agg values (district.dist_code, district.ayid, 
          district.gender_code, district.medium, district.is_govt,district.tot_stu_count,district.pass_stu_count,
          district.sub_code,district.sub_avg_marks);
      end loop;
end;
$$ language plpgsql;

CREATE OR REPLACE function agg_sslc_results_s2() returns void as $$
declare
  district RECORD;
begin
      for district in
              select distinct dist_code, cast(ayid as int), gender_code, medium, case when schoolname like '%GOVT%' then 'G' when schoolname like '%CORPORATION%' then 'G' when schoolname like '%GOVERNMENT%' then 'G' else 'N' end as is_govt,
      				count(distinct reg_no) as tot_stu_count, 
      				sum(case when s2_result = 'P' then 1 else 0 end) as pass_stu_count,
      				trim(leading '0' from substring(s2_marks from 1 for 2)) as sub_code ,
      				avg(cast (nullif(nullif(trim(leading '*' from substring(trim(leading '0' from s2_marks) from 4)),'888'),'') as int)) as sub_avg_marks
      				from tb_sslcresults 
      				group by dist_code, sub_code, ayid,gender_code,medium,is_govt
      loop
                insert into tb_sslc_agg values (district.dist_code, district.ayid, 
                district.gender_code, district.medium, district.is_govt,district.tot_stu_count,district.pass_stu_count,
                district.sub_code,district.sub_avg_marks);
      end loop;
end;
$$ language plpgsql;

select agg_sslc_counts();
select agg_sslc_results('l1_marks','l1_result');
select agg_sslc_results('l2_marks','l2_result');
select agg_sslc_results('l3_marks','l3_result');
select agg_sslc_results('s1_marks','s1_result');
select agg_sslc_results_s2();
select agg_sslc_results('s3_marks','s3_result');
