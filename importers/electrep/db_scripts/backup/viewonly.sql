CREATE OR REPLACE VIEW vw_school_chart_agg as
       select * from dblink('host=localhost dbname=klpwww0 user=klp password=1q2w3e4r', 'select * from tb_school_chart_agg')
       as t1 (
  sid integer,
  assid integer,
  clid integer,
  sex sex,
  mt school_moi,
  aggtext varchar(100),
  aggval numeric(6,2),
  aggmax numeric(6,2)
);
