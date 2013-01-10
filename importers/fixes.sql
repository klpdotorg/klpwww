delete from tb_boundary where id=8772; -- the hid is set to school for this record
INSERT INTO tb_partner (name,status,info) values ('Akshara Foundation',1,'Bangalore'); -- First partner indormation
ALTER TABLE tb_programme ADD COLUMN partnerid INTEGER default 1;
ALTER TABLE tb_programme ADD FOREIGN KEY (partnerid) REFERENCES tb_partner;


--change program names
UPDATE tb_programme set name='Remedial_Math-Level1' where id=2;
UPDATE tb_programme set name='Remedial_Math-Level2' where id=3;
UPDATE tb_programme set name='Remedial_Math-Level3' where id=9;
UPDATE tb_programme set name='Akshara Ganitha' where id=14;
UPDATE tb_programme set name='English' where id=15;
update tb_assessment set start='2010-10-01' where id=43;
update tb_assessment set start='2010-10-01' where id=45;
update tb_assessment set start='2010-10-01' where id=47;

update tb_student_eval set grade='O' where grade='0' and qid in (select distinct q.id from tb_question q,tb_assessment ass where qid=q.id and q.assid=ass.id and ass.pid=1);

update tb_student_eval set grade='0' where grade='0`';
update tb_student_eval set grade='1' where grade='01';
update tb_student_eval set grade='0' where grade='00';
update tb_student_eval set grade='N' where grade='n';
update tb_student_eval set grade='1' where grade='11';
update tb_student_eval set grade='0' where grade='000000';
update tb_student_eval set grade='1' where grade like '% 1 %';
update tb_student_eval set grade='0' where grade like '% 0 %';
