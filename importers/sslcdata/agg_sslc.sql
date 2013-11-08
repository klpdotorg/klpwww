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
        moi character varying(3),
        sch_count integer,
        tot_stu_count integer,
        pass_stu_count integer
);


CREATE OR REPLACE function agg_sslc_counts() returns void as $$
declare
  district RECORD;
begin
      for district in
        select distinct dist_code, cast(ayid as int),case when schoolname like '%GOVT%' then 'G' when schoolname like '%CORPORATION%' then 'G' when schoolname like '%GOVERNMENT%' then 'G' else 'N' end as is_govt,case when medium in ('e','E') then 'E' when medium in ('K','EK') then 'K' when medium = 'U' then 'U' else 'O' end as moi, count(distinct schoolname) as sch_count, count(distinct reg_no) as tot_stu_count, sum(case when result='P' then 1 else 0 end) as pass_stu_count from tb_sslcresults group by dist_code,is_govt,ayid, moi
        loop
          insert into tb_sslc_sch_agg values (district.dist_code,district.ayid,district.is_govt,district.moi,district.sch_count,district.tot_stu_count,district.pass_stu_count);
        end loop;
end;
$$ language plpgsql;

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


-- Aggregating to have 34 rows per criteria for charting reading from the first aggregate table

DROP TABLE tb_agg_mgmt_acadyr;
CREATE TABLE tb_agg_mgmt_acadyr (
dist_code character varying(3),
"04_05g" numeric(3),
"04_05n" numeric(3),
"05_06g" numeric(3),
"05_06n" numeric(3),
"06_07g" numeric(3),
"06_07n" numeric(3),
"07_08g" numeric(3),
"07_08n" numeric(3),
"08_09g" numeric(3),
"08_09n" numeric(3),
"09_10g" numeric(3),
"09_10n" numeric(3),
"10_11g" numeric(3),
"10_11n" numeric(3),
"11_12g" numeric(3),
"11_12n" numeric(3),
"12_13g" numeric(3),
"12_13n" numeric(3)
);

CREATE OR REPLACE function agg_mgmt_by_acad_yr() returns void as $$
declare
		datarecord RECORD;
begin
		for datarecord in
				select ay.name, g.dist_code, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as govt_pass, (cast(sum(n.pass_stu_count) AS float)*100/cast(sum(n.tot_stu_count) AS float))::int as pvt_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg n where g.dist_code=n.dist_code and g.is_govt='G' and n.is_govt='N' and n.ayid = ay.id and g.ayid=121 and n.ayid=121 group by g.dist_code,ay.name order by ay.name,g.dist_code
		loop
				insert into tb_agg_mgmt_acadyr (dist_code, "12_13g", "12_13n") values (datarecord.dist_code, datarecord.govt_pass, datarecord.pvt_pass);         
		end loop;
		for datarecord in
                                select ay.name, g.dist_code, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as govt_pass, (cast(sum(n.pass_stu_count) AS float)*100/cast(sum(n.tot_stu_count) AS float))::int as pvt_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg n where g.dist_code=n.dist_code and g.is_govt='G' and n.is_govt='N' and n.ayid = ay.id and g.ayid=102 and n.ayid=102 group by g.dist_code,ay.name order by ay.name,g.dist_code
                loop            
                                update tb_agg_mgmt_acadyr set "11_12g" = datarecord.govt_pass , "11_12n" = datarecord.pvt_pass where dist_code= datarecord.dist_code;                   
                end loop;
		for datarecord in
				select ay.name, g.dist_code, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as govt_pass, (cast(sum(n.pass_stu_count) AS float)*100/cast(sum(n.tot_stu_count) AS float))::int as pvt_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg n where g.dist_code=n.dist_code and g.is_govt='G' and n.is_govt='N' and n.ayid = ay.id and g.ayid=7 and n.ayid=7 group by g.dist_code,ay.name order by ay.name,g.dist_code
                loop
				update tb_agg_mgmt_acadyr set "04_05g" = datarecord.govt_pass , "04_05n" = datarecord.pvt_pass where dist_code= datarecord.dist_code;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as govt_pass, (cast(sum(n.pass_stu_count) AS float)*100/cast(sum(n.tot_stu_count) AS float))::int as pvt_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg n where g.dist_code=n.dist_code and g.is_govt='G' and n.is_govt='N' and n.ayid = ay.id and g.ayid=6 and n.ayid=6 group by g.dist_code,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_mgmt_acadyr set "05_06g" = datarecord.govt_pass , "05_06n" = datarecord.pvt_pass where dist_code= datarecord.dist_code;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as govt_pass, (cast(sum(n.pass_stu_count) AS float)*100/cast(sum(n.tot_stu_count) AS float))::int as pvt_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg n where g.dist_code=n.dist_code and g.is_govt='G' and n.is_govt='N' and n.ayid = ay.id and g.ayid=90 and n.ayid=90 group by g.dist_code,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_mgmt_acadyr set "06_07g" = datarecord.govt_pass , "06_07n" = datarecord.pvt_pass where dist_code= datarecord.dist_code;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as govt_pass, (cast(sum(n.pass_stu_count) AS float)*100/cast(sum(n.tot_stu_count) AS float))::int as pvt_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg n where g.dist_code=n.dist_code and g.is_govt='G' and n.is_govt='N' and n.ayid = ay.id and g.ayid=1 and n.ayid=1 group by g.dist_code,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_mgmt_acadyr set "07_08g" = datarecord.govt_pass , "07_08n" = datarecord.pvt_pass where dist_code= datarecord.dist_code;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as govt_pass, (cast(sum(n.pass_stu_count) AS float)*100/cast(sum(n.tot_stu_count) AS float))::int as pvt_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg n where g.dist_code=n.dist_code and g.is_govt='G' and n.is_govt='N' and n.ayid = ay.id and g.ayid=2 and n.ayid=2 group by g.dist_code,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_mgmt_acadyr set "08_09g" = datarecord.govt_pass , "08_09n" = datarecord.pvt_pass where dist_code= datarecord.dist_code;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as govt_pass, (cast(sum(n.pass_stu_count) AS float)*100/cast(sum(n.tot_stu_count) AS float))::int as pvt_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg n where g.dist_code=n.dist_code and g.is_govt='G' and n.is_govt='N' and n.ayid = ay.id and g.ayid=119 and n.ayid=119 group by g.dist_code,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_mgmt_acadyr set "09_10g" = datarecord.govt_pass , "09_10n" = datarecord.pvt_pass where dist_code= datarecord.dist_code;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as govt_pass, (cast(sum(n.pass_stu_count) AS float)*100/cast(sum(n.tot_stu_count) AS float))::int as pvt_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg n where g.dist_code=n.dist_code and g.is_govt='G' and n.is_govt='N' and n.ayid = ay.id and g.ayid=101 and n.ayid=101 group by g.dist_code,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_mgmt_acadyr set "10_11g" = datarecord.govt_pass , "10_11n" = datarecord.pvt_pass where dist_code= datarecord.dist_code;         
		end loop;
end;
$$ language plpgsql;

select agg_mgmt_by_acad_yr();

DROP TABLE tb_agg_gender_acadyr;
CREATE TABLE tb_agg_gender_acadyr (
dist_code character varying(3),
is_govt character varying(3),
"04_05g" numeric(3),
"04_05b" numeric(3),
"05_06g" numeric(3),
"05_06b" numeric(3),
"06_07g" numeric(3),
"06_07b" numeric(3),
"07_08g" numeric(3),
"07_08b" numeric(3),
"08_09g" numeric(3),
"08_09b" numeric(3),
"09_10g" numeric(3),
"09_10b" numeric(3),
"10_11g" numeric(3),
"10_11b" numeric(3),
"11_12g" numeric(3),
"11_12b" numeric(3),
"12_13g" numeric(3),
"12_13b" numeric(3)
);

CREATE OR REPLACE function agg_gender_by_acad_yr() returns void as $$
declare
		datarecord RECORD;
begin
		for datarecord in
				select ay.name, g.dist_code, g.is_govt, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as girl_pass, (cast(sum(b.pass_stu_count) AS float)*100/cast(sum(b.tot_stu_count) AS float))::int as boy_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg b where g.dist_code=b.dist_code and g.gender_code='G' and b.gender_code='B' and b.ayid = ay.id and g.ayid=121 and b.ayid=121 group by g.dist_code, g.is_govt,ay.name order by ay.name,g.dist_code
		loop
				insert into tb_agg_gender_acadyr (dist_code,is_govt, "12_13g", "12_13b") values (datarecord.dist_code, datarecord.is_govt,datarecord.girl_pass, datarecord.boy_pass);         
		end loop;
		for datarecord in
                                select ay.name, g.dist_code, g.is_govt, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as girl_pass, (cast(sum(b.pass_stu_count) AS float)*100/cast(sum(b.tot_stu_count) AS float))::int as boy_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg b where g.dist_code=b.dist_code and g.gender_code='G' and b.gender_code='B' and b.ayid = ay.id and g.ayid=102 and b.ayid=102 group by g.dist_code, g.is_govt,ay.name order by ay.name,g.dist_code
                loop
                                update tb_agg_gender_acadyr set "11_12g" = datarecord.girl_pass , "11_12b" = datarecord.boy_pass where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;
                end loop;
		for datarecord in
				select ay.name, g.dist_code, g.is_govt, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as girl_pass, (cast(sum(b.pass_stu_count) AS float)*100/cast(sum(b.tot_stu_count) AS float))::int as boy_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg b where g.dist_code=b.dist_code and g.gender_code='G' and b.gender_code='B' and b.ayid = ay.id and g.ayid=7 and b.ayid=7 group by g.dist_code, g.is_govt,ay.name order by ay.name,g.dist_code
                loop
				update tb_agg_gender_acadyr set "04_05g" = datarecord.girl_pass , "04_05b" = datarecord.boy_pass where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, g.is_govt, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as girl_pass, (cast(sum(b.pass_stu_count) AS float)*100/cast(sum(b.tot_stu_count) AS float))::int as boy_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg b where g.dist_code=b.dist_code and g.gender_code='G' and b.gender_code='B' and b.ayid = ay.id and g.ayid=6 and b.ayid=6 group by g.dist_code, g.is_govt,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_gender_acadyr set "05_06g" = datarecord.girl_pass , "05_06b" = datarecord.boy_pass where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, g.is_govt, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as girl_pass, (cast(sum(b.pass_stu_count) AS float)*100/cast(sum(b.tot_stu_count) AS float))::int as boy_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg b where g.dist_code=b.dist_code and g.gender_code='G' and b.gender_code='B' and b.ayid = ay.id and g.ayid=90 and b.ayid=90 group by g.dist_code, g.is_govt,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_gender_acadyr set "06_07g" = datarecord.girl_pass , "06_07b" = datarecord.boy_pass where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, g.is_govt, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as girl_pass, (cast(sum(b.pass_stu_count) AS float)*100/cast(sum(b.tot_stu_count) AS float))::int as boy_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg b where g.dist_code=b.dist_code and g.gender_code='G' and b.gender_code='B' and b.ayid = ay.id and g.ayid=1 and b.ayid=1 group by g.dist_code, g.is_govt,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_gender_acadyr set "07_08g" = datarecord.girl_pass , "07_08b" = datarecord.boy_pass where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, g.is_govt, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as girl_pass, (cast(sum(b.pass_stu_count) AS float)*100/cast(sum(b.tot_stu_count) AS float))::int as boy_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg b where g.dist_code=b.dist_code and g.gender_code='G' and b.gender_code='B' and b.ayid = ay.id and g.ayid=2 and b.ayid=2 group by g.dist_code, g.is_govt,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_gender_acadyr set "08_09g" = datarecord.girl_pass , "08_09b" = datarecord.boy_pass where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, g.is_govt, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as girl_pass, (cast(sum(b.pass_stu_count) AS float)*100/cast(sum(b.tot_stu_count) AS float))::int as boy_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg b where g.dist_code=b.dist_code and g.gender_code='G' and b.gender_code='B' and b.ayid = ay.id and g.ayid=119 and b.ayid=119 group by g.dist_code, g.is_govt,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_gender_acadyr set "09_10g" = datarecord.girl_pass , "09_10b" = datarecord.boy_pass where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, g.dist_code, g.is_govt, (cast(sum(g.pass_stu_count) AS float)*100/cast(sum(g.tot_stu_count) AS float))::int as girl_pass, (cast(sum(b.pass_stu_count) AS float)*100/cast(sum(b.tot_stu_count) AS float))::int as boy_pass from tb_academic_year ay, tb_sslc_agg g, tb_sslc_agg b where g.dist_code=b.dist_code and g.gender_code='G' and b.gender_code='B' and b.ayid = ay.id and g.ayid=101 and b.ayid=101 group by g.dist_code, g.is_govt,ay.name order by ay.name,g.dist_code
		loop
				update tb_agg_gender_acadyr set "10_11g" = datarecord.girl_pass , "10_11b" = datarecord.boy_pass where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
end;
$$ language plpgsql;

select agg_gender_by_acad_yr();

DROP TABLE tb_agg_sub_acadyr;
CREATE TABLE tb_agg_sub_acadyr (
dist_code character varying(3),
is_govt character varying(3),
"04_05m" numeric(3),
"04_05k" numeric(3),
"04_05e" numeric(3),
"05_06m" numeric(3),
"05_06k" numeric(3),
"05_06e" numeric(3),
"06_07m" numeric(3),
"06_07k" numeric(3),
"06_07e" numeric(3),
"07_08m" numeric(3),
"07_08k" numeric(3),
"07_08e" numeric(3),
"08_09m" numeric(3),
"08_09k" numeric(3),
"08_09e" numeric(3),
"09_10m" numeric(3),
"09_10k" numeric(3),
"09_10e" numeric(3),
"10_11m" numeric(3),
"10_11k" numeric(3),
"10_11e" numeric(3),
"11_12m" numeric(3),
"11_12k" numeric(3),
"11_12e" numeric(3),
"12_13m" numeric(3),
"12_13k" numeric(3),
"12_13e" numeric(3)
);

CREATE OR REPLACE function agg_sub_by_acad_yr() returns void as $$
declare
		datarecord RECORD;
begin
		for datarecord in
				select ay.name, m.dist_code, m.is_govt, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=121 and k.ayid=ay.id and k.ayid=121 and e.ayid=ay.id and e.ayid=121 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.is_govt=k.is_govt and k.is_govt=e.is_govt and e.is_govt=m.is_govt group by m.dist_code, m.is_govt, ay.name order by ay.name,m.dist_code
		loop
				insert into tb_agg_sub_acadyr (dist_code,is_govt, "12_13m", "12_13k","12_13e") values (datarecord.dist_code, datarecord.is_govt,datarecord.math_avg, datarecord.kan_avg, datarecord.eng_avg);         
		end loop;
		for datarecord in
                                select ay.name, m.dist_code, m.is_govt, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=102 and k.ayid=102 and e.ayid = 102 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.is_govt=k.is_govt and k.is_govt=e.is_govt and e.is_govt=m.is_govt group by m.dist_code, m.is_govt, ay.name order by ay.name,m.dist_code
                loop
                                update tb_agg_sub_acadyr set "11_12m" = datarecord.math_avg , "11_12k" = datarecord.kan_avg, "11_12e" = datarecord.eng_avg where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;
                end loop;
		for datarecord in
				select ay.name, m.dist_code, m.is_govt, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=7 and k.ayid=7 and e.ayid = 7 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.is_govt=k.is_govt and k.is_govt=e.is_govt and e.is_govt=m.is_govt group by m.dist_code, m.is_govt, ay.name order by ay.name,m.dist_code
                loop
				update tb_agg_sub_acadyr set "04_05m" = datarecord.math_avg , "04_05k" = datarecord.kan_avg, "04_05e" = datarecord.eng_avg where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, m.is_govt, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=6 and k.ayid=6 and e.ayid = 6 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.is_govt=k.is_govt and k.is_govt=e.is_govt and e.is_govt=m.is_govt group by m.dist_code, m.is_govt, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_sub_acadyr set "05_06m" = datarecord.math_avg , "05_06k" = datarecord.kan_avg, "05_06e" = datarecord.eng_avg where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, m.is_govt, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=90 and k.ayid=90 and e.ayid = 90 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.is_govt=k.is_govt and k.is_govt=e.is_govt and e.is_govt=m.is_govt group by m.dist_code, m.is_govt, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_sub_acadyr set "06_07m" = datarecord.math_avg , "06_07k" = datarecord.kan_avg, "06_07e" = datarecord.eng_avg where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, m.is_govt, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=1 and k.ayid=1 and e.ayid = 1 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.is_govt=k.is_govt and k.is_govt=e.is_govt and e.is_govt=m.is_govt group by m.dist_code, m.is_govt, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_sub_acadyr set "07_08m" = datarecord.math_avg , "07_08k" = datarecord.kan_avg, "07_08e" = datarecord.eng_avg where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, m.is_govt, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=2 and k.ayid=2 and e.ayid = 2 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.is_govt=k.is_govt and k.is_govt=e.is_govt and e.is_govt=m.is_govt group by m.dist_code, m.is_govt, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_sub_acadyr set "08_09m" = datarecord.math_avg , "08_09k" = datarecord.kan_avg, "08_09e" = datarecord.eng_avg where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, m.is_govt, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=119 and k.ayid=119 and e.ayid = 119 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.is_govt=k.is_govt and k.is_govt=e.is_govt and e.is_govt=m.is_govt group by m.dist_code, m.is_govt, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_sub_acadyr set "09_10m" = datarecord.math_avg , "09_10k" = datarecord.kan_avg, "09_10e" = datarecord.eng_avg where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, m.is_govt, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=101 and k.ayid=ay.id and k.ayid=101 and e.ayid=ay.id and e.ayid=101 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.is_govt=k.is_govt and k.is_govt=e.is_govt and e.is_govt=m.is_govt group by m.dist_code, m.is_govt, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_sub_acadyr set "10_11m" = datarecord.math_avg , "10_11k" = datarecord.kan_avg, "10_11e" = datarecord.eng_avg where dist_code= datarecord.dist_code and is_govt=datarecord.is_govt;         
		end loop;
end;
$$ language plpgsql;

select agg_sub_by_acad_yr();

DROP TABLE tb_agg_moi_acadyr;
CREATE TABLE tb_agg_moi_acadyr (
dist_code character varying(3),
moi character varying(3),
"04_05m" numeric(3),
"04_05k" numeric(3),
"04_05e" numeric(3),
"05_06m" numeric(3),
"05_06k" numeric(3),
"05_06e" numeric(3),
"06_07m" numeric(3),
"06_07k" numeric(3),
"06_07e" numeric(3),
"07_08m" numeric(3),
"07_08k" numeric(3),
"07_08e" numeric(3),
"08_09m" numeric(3),
"08_09k" numeric(3),
"08_09e" numeric(3),
"09_10m" numeric(3),
"09_10k" numeric(3),
"09_10e" numeric(3),
"10_11m" numeric(3),
"10_11k" numeric(3),
"10_11e" numeric(3),
"11_12m" numeric(3),
"11_12k" numeric(3),
"11_12e" numeric(3),
"12_13m" numeric(3),
"12_13k" numeric(3),
"12_13e" numeric(3)
);

CREATE OR REPLACE function agg_moi_by_acad_yr() returns void as $$
declare
		datarecord RECORD;
begin
		for datarecord in
				select ay.name, m.dist_code, case when m.medium in ('e','E') then 'E' when m.medium in ('K','EK') then 'K' when m.medium = 'U' then 'U' else 'O' end as moi, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=121 and k.ayid=ay.id and k.ayid=121 and e.ayid=ay.id and e.ayid=121 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.medium=k.medium and k.medium=e.medium and e.medium=m.medium group by m.dist_code, moi, ay.name order by ay.name,m.dist_code
		loop
				insert into tb_agg_moi_acadyr (dist_code,moi, "12_13m", "12_13k","12_13e") values (datarecord.dist_code, datarecord.moi,datarecord.math_avg, datarecord.kan_avg, datarecord.eng_avg);         
		end loop;
		 for datarecord in
                                select ay.name, m.dist_code, case when m.medium in ('e','E') then 'E' when m.medium in ('K','EK') then 'K' when m.medium = 'U' then 'U' else 'O' end as moi, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=102 and k.ayid=102 and e.ayid = 102 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.medium=k.medium and k.medium=e.medium and e.medium=m.medium group by m.dist_code, moi, ay.name order by ay.name,m.dist_code
                loop
                                update tb_agg_moi_acadyr set "11_12m" = datarecord.math_avg , "11_12k" = datarecord.kan_avg, "11_12e" = datarecord.eng_avg where dist_code= datarecord.dist_code and moi=datarecord.moi;
                end loop;
		for datarecord in
				select ay.name, m.dist_code, case when m.medium in ('e','E') then 'E' when m.medium in ('K','EK') then 'K' when m.medium = 'U' then 'U' else 'O' end as moi, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=7 and k.ayid=7 and e.ayid = 7 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.medium=k.medium and k.medium=e.medium and e.medium=m.medium group by m.dist_code, moi, ay.name order by ay.name,m.dist_code
                loop
				update tb_agg_moi_acadyr set "04_05m" = datarecord.math_avg , "04_05k" = datarecord.kan_avg, "04_05e" = datarecord.eng_avg where dist_code= datarecord.dist_code and moi=datarecord.moi;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, case when m.medium in ('e','E') then 'E' when m.medium in ('K','EK') then 'K' when m.medium = 'U' then 'U' else 'O' end as moi, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=6 and k.ayid=6 and e.ayid = 6 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.medium=k.medium and k.medium=e.medium and e.medium=m.medium group by m.dist_code, moi, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_moi_acadyr set "05_06m" = datarecord.math_avg , "05_06k" = datarecord.kan_avg, "05_06e" = datarecord.eng_avg where dist_code= datarecord.dist_code and moi=datarecord.moi;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, case when m.medium in ('e','E') then 'E' when m.medium in ('K','EK') then 'K' when m.medium = 'U' then 'U' else 'O' end as moi, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=90 and k.ayid=90 and e.ayid = 90 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.medium=k.medium and k.medium=e.medium and e.medium=m.medium group by m.dist_code, moi, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_moi_acadyr set "06_07m" = datarecord.math_avg , "06_07k" = datarecord.kan_avg, "06_07e" = datarecord.eng_avg where dist_code= datarecord.dist_code and moi=datarecord.moi;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, case when m.medium in ('e','E') then 'E' when m.medium in ('K','EK') then 'K' when m.medium = 'U' then 'U' else 'O' end as moi, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=1 and k.ayid=1 and e.ayid = 1 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.medium=k.medium and k.medium=e.medium and e.medium=m.medium group by m.dist_code, moi, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_moi_acadyr set "07_08m" = datarecord.math_avg , "07_08k" = datarecord.kan_avg, "07_08e" = datarecord.eng_avg where dist_code= datarecord.dist_code and moi=datarecord.moi;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, case when m.medium in ('e','E') then 'E' when m.medium in ('K','EK') then 'K' when m.medium = 'U' then 'U' else 'O' end as moi, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=2 and k.ayid=2 and e.ayid = 2 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.medium=k.medium and k.medium=e.medium and e.medium=m.medium group by m.dist_code, moi, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_moi_acadyr set "08_09m" = datarecord.math_avg , "08_09k" = datarecord.kan_avg, "08_09e" = datarecord.eng_avg where dist_code= datarecord.dist_code and moi=datarecord.moi;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, case when m.medium in ('e','E') then 'E' when m.medium in ('K','EK') then 'K' when m.medium = 'U' then 'U' else 'O' end as moi, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=119 and k.ayid=119 and e.ayid = 119 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.medium=k.medium and k.medium=e.medium and e.medium=m.medium group by m.dist_code, moi, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_moi_acadyr set "09_10m" = datarecord.math_avg , "09_10k" = datarecord.kan_avg, "09_10e" = datarecord.eng_avg where dist_code= datarecord.dist_code and moi=datarecord.moi;         
		end loop;
		for datarecord in
				select ay.name, m.dist_code, case when m.medium in ('e','E') then 'E' when m.medium in ('K','EK') then 'K' when m.medium = 'U' then 'U' else 'O' end as moi, avg(m.sub_avg_marks)::int as math_avg, avg(k.sub_avg_marks)::int as kan_avg, avg(e.sub_avg_marks)::int as eng_avg from tb_academic_year ay, tb_sslc_agg m, tb_sslc_agg k, tb_sslc_agg e where m.dist_code = e.dist_code and e.dist_code = k.dist_code and m.dist_code = k.dist_code and m.ayid = ay.id and m.ayid=101 and k.ayid=ay.id and k.ayid=101 and e.ayid=ay.id and e.ayid=101 and m.sub_code = '81' and e.sub_code in ('14','31','63') and k.sub_code in ('01','33','62')  and m.medium=k.medium and k.medium=e.medium and e.medium=m.medium group by m.dist_code, moi, ay.name order by ay.name,m.dist_code
		loop
				update tb_agg_moi_acadyr set "10_11m" = datarecord.math_avg , "10_11k" = datarecord.kan_avg, "10_11e" = datarecord.eng_avg where dist_code= datarecord.dist_code and moi=datarecord.moi;         
		end loop;
end;
$$ language plpgsql;

select agg_moi_by_acad_yr();
