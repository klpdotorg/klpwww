select id,const_ward_name,elec_comm_code,const_ward_type from tb_electedrep_master where status='active' \g ../data/tb_elected_rep.lst
select distinct sid from tb_school_electedrep \g ../data/tb_school_rep.lst
