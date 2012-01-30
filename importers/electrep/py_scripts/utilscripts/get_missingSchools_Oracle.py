#!/usr/bin/env python
import os,sys
import cx_Oracle
import traceback

connstr="repl_aksems/repl_aksems"
conn = cx_Oracle.connect(connstr)
curs = conn.cursor()
curs.arraysize=50
statement='SELECT (CASE b1.id_bndry_type WHEN 9 THEN \'SCHOOL\' WHEN 13 THEN \'PRESCHOOL\' END ) AS "TYPE", b1.NAME AS "DISTRICT", b2.NAME AS "BLOCK", b3.NAME AS "CLUSTER", s.ID, s.SCHOOLNAME, sc.category_desc FROM eg_boundary b1, eg_boundary b2, eg_boundary b3, eg_school s, eg_school_category sc WHERE sc.categoryid = s.categoryid and b3.id_bndry= s.id_adm_boundary AND b3.PARENT= b2.id_bndry AND b2.PARENT=b1.id_bndry AND s.ID IN ('
statement_par2 = ') order by b1.name,b2.name,b3.name,s.id'

missingschfile=open("../data/missinglist_sch_Aug10.csv","w")
schoolinfofile=open("../data/missing_schids_Aug10.csv","r")

try: 
  schids =  []
  lines = schoolinfofile.readlines()
  for line in lines[2:-2]:
    schids.append(str(line).strip())
  #curs.execute(statement,{'schid':",".join(schids)})
  curs.execute(statement + ",".join(schids) + statement_par2)
  missingschfile.write('"heirarchy","district","proj/block","circle/cluster","ID","SCHOOLNAME","CATEGORY_DESC"\n')
  for data in curs:
    missingschfile.write(str(data).strip(')').strip('(') +"\n")
except:
  print "Unexpected error:", sys.exc_info()
  print "Exception in user code:"
  print "-"*60
  traceback.print_exc(file=sys.stdout)
  print "-"*60

missingschfile.close()
schoolinfofile.close()


