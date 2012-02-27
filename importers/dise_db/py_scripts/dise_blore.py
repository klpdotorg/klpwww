#!/usr/bin/env python
import os,sys
import csv

def getInt(val):
  if len(val.strip()) == 0:
    return 0
  else:
    return int(val.strip())

filelist = ["North.csv","South.csv","Rural.csv"]
disedatafile=open("../db_scripts/load/disedata.sql",'w')
try:
  for file in filelist:
    csvbuffer = csv.reader(open('../data/'+file,'rb'), delimiter='|') 
    header = csvbuffer.next()
    for row in csvbuffer:
      disedatafile.write('INSERT INTO tb_dise_facility values(\'' + row[0].strip() + '\',' + str(getInt(row[2])) + ',' + str(getInt(row[26])+ getInt(row[27]))+ ',' + '\'active\'' + ');\n')
except:
  print "Unexpected error:", sys.exc_info()
  print "Exception in user code:"
  print '-'*60
  traceback.print_exc(file=sys.stdout)
  print '-'*60
finally:
  disedatafile.close()
