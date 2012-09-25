#!/usr/bin/env python
import os,sys
import csv
import Utility.KLPDB
import traceback

klpid_dict = {}
angcode_dict = {}

def getInt(val):
  if len(val.strip()) == 0:
    return 0
  else:
    return int(val.strip())

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

def getQuestionsSql():
  datafile=open("../data/Infra-AWC-questions.csv",'rb')
  sqlfile=open("../db_scripts/load/insertquestions.sql",'w')
  csvbuffer = csv.reader(datafile, delimiter='|') 
  header = csvbuffer.next()
  for row in csvbuffer:
    sqlfile.write('INSERT INTO tb_ai_questions values(' + row[0].strip() + ',' + '\'' + row[1].strip() + '\'' + ');\n')
  sqlfile.close()
  datafile.close()

def getAnswersSql():
  datafile=open("../data/Infra-AWC.csv",'rb')
  anssqlfile=open("../db_scripts/load/insertanswers.sql",'w')
  angsqlfile=open("../db_scripts/load/insertanginfo.sql",'w')
  csvbuffer = csv.reader(datafile, delimiter='|') 
  header = csvbuffer.next()
  klpinfo = [] 
  for row in csvbuffer:
    if len(str(row[4]).strip()) > 0:
      if str(row[4]).strip() in klpid_dict.keys():
        klpinfo = klpid_dict[str(row[4]).strip()]
      else:
        klpinfo =[]
        print "Not in KLP ID dict |" + row[4] 
    elif len(row[5].strip()) > 0:
      if row[5].strip() in angcode_dict.keys():
        klpinfo = angcode_dict[row[5].strip()]
      else:
        klpinfo =[]
        print "Not in CODE dict |" + row[5] 
    else:
      print "In neither dict |" + row[4] + '|' + row[5]
      klpinfo = [] 
    if len(klpinfo) > 0:
      angsqlfile.write('INSERT INTO tb_ang_info values(' + str(klpinfo[4]) + ',\'' + klpinfo[0] + '\',\'' + klpinfo[1] + '\',\'' + klpinfo[2] + '\',\'' + klpinfo[3].replace('\'','') + '\');\n')
      for i in range(0,69):
        if str(row[i+7]).strip().lower() == 'NA'.lower():
          ans = 2
        elif len(str(row[i+7]).strip()) == 0:
          ans = 2
        else:
          ans = row[i+7]
        anssqlfile.write('INSERT INTO tb_ai_answers values(' + str(klpinfo[4]) + ',' + str(i+1) +','+ str(ans) + ');\n')
  angsqlfile.close()
  anssqlfile.close()
  datafile.close()

try:
  getQuestionsSql()
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
