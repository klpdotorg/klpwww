delete from tb_sys_images where hash_file='415a9a03744cc9d47168dd34be8b2030.jpg';
delete from tb_sys_images where hash_file='020b344c67e9252e62375e2e5e0d5b1b.jpg';
delete from tb_sys_images where hash_file='4e41508cf8f1a4d7bec0f946388ed493.jpg';
delete from tb_sys_images where hash_file='33bd4a752728ed9e1bea973422b40151.jpg';
delete from tb_sys_images where hash_file='9105a0a54130b3f4289dd98d4bf08017.jpg';
delete from tb_sys_images where hash_file='73fa2a5fae655698c081c637f7d1cf56.jpg';
delete from tb_sys_images where hash_file='43d772ff4beade58fad6fcf5d9a10179.jpg';
delete from tb_sys_images where hash_file='1ecf2fe213b84a37feae635de05d3cd6.jpg';
delete from tb_sys_images where hash_file='0983909b311f74d139de82d40fd3acdc.jpg';
delete from tb_sys_images where hash_file='87da7c9cbe689e70812890fe67794897.jpg';
-- trac ticket 389 fixing swapped pics 
update tb_sys_images set schoolid=32912 where sysid=2348;
update tb_sys_images set schoolid=32895 where sysid=2365;
