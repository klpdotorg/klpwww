#!/usr/bin/env python
import os,sys
import cx_Oracle


connstr='repl_aksems/repl_aksems'
conn = cx_Oracle.connect(connstr)
curs = conn.cursor()
curs.arraysize=50
statement="select DISTINCT stu.schoolid, lower(l2.language), sc.category_desc,c.gender,lower(l.language),count(DISTINCT stu.studentid) FROM egems_student stu,eg_school s,eg_school_category sc,egclts_child c, eg_language l,eg_language l2  WHERE stu.statusid=1 AND stu.is_active=1 AND stu.childid=c.childid AND c.languageid=l.languageid(+) AND s.id_instr_medium=l2.languageid(+) AND stu.schoolid=s.ID AND s.categoryid=sc.categoryid AND s.is_Active=1 group by stu.schoolid, sc.category_desc, c.gender, l.language, l2.language order by stu.schoolid"

schoolinfofile=open("../db_scripts/load/schoolcount.sql",'w')

try: 
  curs.execute(statement)
  for data in curs:
    #print str(data)
    schoolinfofile.write("INSERT INTO tb_school_stu_counts (sid,moi,cat,sex,mt,numstu) values " + str(data).replace('None','\'kannada\'') +';\n')
    #print "INSERT INTO tb_school_stu_counts values(" + str(schoolid) + ",'" + data[1].strip() if data[1] != None else 'kannada' + "','" + data[2].strip() + "','" + data[3].strip() + "','" + data[4].strip() if data[4] != None else 'kannada' + "'," + str(data[5]) + ");\n"
except:
  print "Unexpected error:", sys.exc_info()


