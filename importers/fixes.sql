delete from tb_boundary where id=8772; -- the hid is set to school for this record
INSERT INTO tb_partner (name,status,info) values ('Akshara Foundation',1,'Bangalore'); -- First partner indormation
ALTER TABLE tb_programme ADD COLUMN partnerid INTEGER default 1;
ALTER TABLE tb_programme ADD FOREIGN KEY (partnerid) REFERENCES tb_partner;
