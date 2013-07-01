select id,elec_comm_code,const_ward_name,current_elected_rep,current_elected_party from tb_electedrep_master where status='active' and const_ward_type='MLA Constituency' \g ../data/tb_mla_2012.lst
