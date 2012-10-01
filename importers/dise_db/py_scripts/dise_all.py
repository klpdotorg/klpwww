#!/usr/bin/env python
import os,sys
import csv

def getInt(val):
  if len(val.strip()) == 0:
    return 0
  else:
    return int(val.strip())

filelist = {"All_basic.csv":"tb_dise_basic",
            "All_facility.csv":"tb_dise_facility",
            "All_rte.csv":"tb_dise_rte",
            "All_teacher.csv":"tb_dise_teacher",
            "All_general.csv":"tb_dise_general",
            "All_enrol.csv":"tb_dise_enrol",
            "All_basic2.csv":"tb_dise_basic",
            "All_facility2.csv":"tb_dise_facility",
            "All_rte2.csv":"tb_dise_rte",
            "All_teacher2.csv":"tb_dise_teacher",
            "All_general2.csv":"tb_dise_general",
            "All_enrol2.csv":"tb_dise_enrol"}

try:
  for file in filelist.keys():
    disedatafile=open("../db_scripts/load/" + filelist[file] + '.sql' ,'a')
    csvbuffer = csv.reader(open('../data/'+file,'rb'), delimiter='|') 
    header = csvbuffer.next()
    headlen = len(header)
    for row in csvbuffer:
      if len(row) > headlen :
        print row
        print filelist[file]
      disedatafile.write('INSERT INTO ' + filelist[file] + ' values('+ (', '.join('\'' + item + '\'' for item in row)) +');\n')
except:
  print "Unexpected error:", sys.exc_info()
  print "Exception in user code:"
  print '-'*60
  traceback.print_exc(file=sys.stdout)
  print '-'*60
finally:
  disedatafile.close()
