#!/usr/bin/env python
import os,sys
import csv
import traceback


def getQuestionsSql():
  datafile=open("data/Infra-AWC-questions.csv",'rb')
  sqlfile=open("db_scripts/load/insertquestions.sql",'w')
  csvbuffer = csv.reader(datafile, delimiter='|') 
  header = csvbuffer.next()
  for row in csvbuffer:
    sqlfile.write('INSERT INTO tb_ai_questions values(' + row[0].strip() + ',' + '\'' + row[1].strip() + '\'' + ');\n')
  sqlfile.close()
  datafile.close()

try:
  getQuestionsSql()
except:
  print "Unexpected error:", sys.exc_info()
  print "Exception in user code:"
  print '-'*60
  traceback.print_exc(file=sys.stdout)
  print '-'*60
finally:
  pass
