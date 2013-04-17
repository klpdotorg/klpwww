#!/usr/bin/env python
import os,sys
import csv
import Utility.KLPDB
import traceback

klpid_dict = {}
angcode_dict = {}

year=str(sys.argv[1])

def populateLookups():
  connection = Utility.KLPDB.getConnection()
  cursor = connection.cursor()
  cursor.execute("select UPPER(b3.name),UPPER(b2.name),UPPER(b1.name),s.id,UPPER(S.name),s.dise_code from tb_school s, tb_boundary b1, tb_boundary b2, tb_boundary b3 where s.bid = b1.id and b1.parent=b2.id and b2.parent=b3.id and b3.id in (8773) and s.status=2;")
  result = cursor.fetchall()
  for row in result:
    if row[3]:
      klpid_dict[str(row[3]).strip()] = [row[0],row[1],row[2],row[4],row[3]]
    if row[5] and len(row[5].strip())>0:
      angcode_dict[row[5].strip()] = [row[0],row[1],row[2],row[4],row[3]]
  #print len(klpid_dict)
  #print len(angcode_dict)
  #print angcode_dict.keys()

def getAnswersSql():
  datafile=open("data/" + year.replace('-','_').strip()  + ".csv",'rb')
  anssqlfile=open("db_scripts/load/insertanswers" + year.strip() + ".sql",'w')
  angsqlfile=open("db_scripts/load/insertanginfo" + year.strip() + ".sql",'w')
  csvbuffer = csv.reader(datafile, delimiter='|') 
  header = csvbuffer.next()
  klpinfo = [] 
  for row in csvbuffer:
    if len(str(row[10]).strip()) > 0:
      if str(row[10]).strip() in klpid_dict.keys():
        klpinfo = klpid_dict[str(row[10]).strip()]
        print klpinfo
      else:
        klpinfo =[]
        print "Not in KLP ID dict |" + row[10] 
    elif len(str(row[11]).strip()) > 0:
      if str(row[11]).strip() in angcode_dict.keys():
        klpinfo = angcode_dict[str(row[11]).strip()]
        print klpinfo 
        print str(row[11])
      else:
        klpinfo =[]
        print "Not in CODE dict |" + row[11] 
    else:
      print "In neither dict |" + str(row[10]) + "|" + str(row[11])
      klpinfo = [] 
    if len(klpinfo) > 0:
      angsqlfile.write('INSERT INTO tb_ang_info values(' + str(klpinfo[4]) + ',\'' + klpinfo[0] + '\',\'' + klpinfo[1] + '\',\'' + klpinfo[2] + '\',\'' + klpinfo[3].replace('\'','') + '\');\n')
      for i in range(0,70):
        if str(row[i+13]).strip().lower() == 'YES'.lower() or str(row[i+13]).strip().lower()=='1':
          ans = 1
        elif str(row[i+13]).strip().lower() == 'NO'.lower() or str(row[i+13]).strip().lower()=='0':
          ans = 0
        else:
          ans = 2
        anssqlfile.write('INSERT INTO tb_ai_answers values(' + str(klpinfo[4]) + ',' + str(i+1) +','+ str(ans) + ',\''+ year.strip() + '\');\n')
  angsqlfile.close()
  anssqlfile.close()
  datafile.close()

try:
  populateLookups()
  getAnswersSql()
except:
  print "Unexpected error:", sys.exc_info()
  print "Exception in user code:"
  print '-'*60
  traceback.print_exc(file=sys.stdout)
  print '-'*60
finally:
  pass
