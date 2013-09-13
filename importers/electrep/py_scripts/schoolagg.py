#!/usr/bin/env python
import os,sys
import psycopg2
import Utility.KLPDB

connection = Utility.KLPDB.getConnection()
cursor = connection.cursor()

#If DB is klpmaster - Mahiti DB, run this
statement="select DISTINCT s.id, lower(smt1.name), sic.name, CASE WHEN c.gender='female' THEN 'Girl' ELSE 'Boy' END, lower(smt2.name),CAST( count(DISTINCT st.id) as integer) from schools_institution s, schools_moi_type smt1, schools_moi_type smt2, schools_student st, schools_child c, schools_institution_category sic, schools_student_studentgrouprelation ssg, schools_studentgroup sg, schools_academic_year say,schools_institution_languages sil where sg.institution_id=s.id and sg.id=ssg.student_group_id and ssg.student_id=st.id and ssg.academic_id=say.id and say.name='2011-2012' and s.id=sil.institution_id and sil.moi_type_id=smt1.id and s.cat_id=sic.id and st.child_id=c.id and c.mt_id=smt2.id and s.active=2 and sg.active=2 and st.active=2 group by s.id,sic.name,c.gender,smt1.name,smt2.name"

#If DB is klpwww run this
#statement="select DISTINCT s.id,CASE WHEN s.moi=null THEN 'kannada' ELSE s.moi END,s.cat,CASE WHEN c.sex='female' THEN 'Girl' ELSE 'Boy' END,c.mt,CAST(COUNT(DISTINCT st.id) as INTEGER) from tb_school s, tb_child c, tb_student st, tb_student_class sc, tb_class cl where cl.sid = s.id and cl.id = sc.clid and sc.stuid = st.id and sc.ayid =121 and st.cid = c.id and st.status = 2 and sc.status =2 and s.status = 2 group by s.id,s.moi,s.cat,c.sex,c.mt order by s.id;"


schoolinfofile=open("../db_scripts/load/schoolcount.sql",'w')

try: 
  cursor.execute(statement)
  curs = cursor.fetchall()
  for data in curs:
    #print str(data)
    schoolinfofile.write("INSERT INTO tb_school_stu_counts (sid,moi,cat,sex,mt,numstu) values " + str(data).replace('None','\'kannada\'') +';\n')
    #print "INSERT INTO tb_school_stu_counts values(" + str(schoolid) + ",'" + data[1].strip() if data[1] != None else 'kannada' + "','" + data[2].strip() + "','" + data[3].strip() + "','" + data[4].strip() if data[4] != None else 'kannada' + "'," + str(data[5]) + ");\n"
except:
  print "Unexpected error:", sys.exc_info()


