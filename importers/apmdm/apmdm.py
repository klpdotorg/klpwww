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

def checkDayMonYear(arr):
  if len(arr[0].strip()) > 0:
    if len(arr[1].strip()) > 0:
      if len(arr[2].strip()) > 0:
        return True
      else:
        return False

filelist = {"ap_data1.csv,0":"tb_middaymeal",
            "ap_data2.csv,0":"tb_middaymeal",
            "ap_data3.csv,0":"tb_middaymeal",
            "ap_data_sep1.csv,1":"tb_middaymeal",
            "ap_data_sep2.csv,1":"tb_middaymeal"}

try:
  for file in filelist.keys():
    hasdise = int(file.split(',')[1])
    filename = file.split(',')[0]
    datafile=open("load/" + filelist[file] + '.sql' ,'a')
    csvbuffer = csv.reader(open('data/'+filename,'rb'), delimiter='|') 
    header = csvbuffer.next()
    headlen = len(header)
    for row in csvbuffer:
      if hasdise:
        if checkDayMonYear(row[3:6]):
          if len(row[1].strip()) > 0 and len(row[0].strip())<8:
            datafile.write('INSERT INTO ' + filelist[file] + ' values('+ row[1] + ','
                  + (', '.join('\'' + item.strip().replace('\'','') + '\'' for item in row[2:6])) + ','
                  + (', '.join(checkEmpty(item) for item in row[6:14])) + ');\n')
      else:
        if checkDayMonYear(row[2:5]):
          if len(row[0].strip()) > 0 and len(row[0].strip())<8:
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
