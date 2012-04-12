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