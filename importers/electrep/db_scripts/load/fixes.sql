update tb_electedrep_master set status='inactive' where const_ward_name in ('SANTHEMARAHALLI','BHARATHINAGAR','JAYAMAHAL','BINNYPET');
update tb_electedrep_master set status='inactive' where const_ward_name in ('MANGALORE','CHIKMAGALUR','KANARA','KANAKAPURA','DHARWAD NORTH','DHARWAD SOUTH');
update tb_electedrep_master set parent=4 where const_ward_type='MLA Constituency' and elec_comm_code in (150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176);
update tb_electedrep_master set parent=4 where const_ward_type='MP Constituency' and elec_comm_code in (23,24,25,26,27);
update tb_electedrep_master set parent=5 where const_ward_type='MLA Constituency' and const_ward_name in ('RAMANAGARAM','ANEKAL','HOSAKOTE','DEVANAHALLI','NELAMANGALA');
update tb_electedrep_master set current_elected_rep='Krishna J Palemar' where const_ward_name='SURATHKAL';
update tb_electedrep_master set status='inactive' where const_ward_name='SURATHKAL';
insert into tb_electedrep_master (parent,elec_comm_code,const_ward_name,const_ward_type) values (5,null,'GP Update','Gram Panchayat');
