#!/usr/bin/env python
import os,sys
import csv

def checkEmpty(value):
  if len(value.strip()) == 0:
     return 'null'
  else:
     try:
       num = int(value)
       return value.strip()
     except:
       print "Value of " + value + " was discarded and set to null"
       return 'null'

filelist = {"ap_data1.csv":"tb_middaymeal",
            "ap_data2.csv":"tb_middaymeal",
            "ap_data3.csv":"tb_middaymeal"}
#filelist = {"ap_data3.csv":"tb_middaymeal"}

try:
  for file in filelist.keys():
    datafile=open("load/" + filelist[file] + '.sql' ,'a')
    csvbuffer = csv.reader(open('data/'+file,'rb'), delimiter='|') 
    header = csvbuffer.next()
    headlen = len(header)
    for row in csvbuffer:
      datafile.write('INSERT INTO ' + filelist[file] + ' values('+ row[0] + ','
                                                         + (', '.join('\'' + item.strip() + '\'' for item in row[1:5])) + ','
						         + (', '.join(checkEmpty(item) for item in row[5:13])) + ');\n')
except:
  print "Unexpected error:", sys.exc_info()
  print "Exception in user code:"
  print '-'*60
  traceback.print_exc(file=sys.stdout)
  print '-'*60
finally:
  datafile.close()
