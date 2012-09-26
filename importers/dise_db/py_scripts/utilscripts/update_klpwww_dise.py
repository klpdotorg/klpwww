#!/usr/bin/env python
import csv
import sys
import re
import os
import difflib
import traceback
import Utility.KLPDB

rootdir = '/home/megha/www/reports/databases/dise_db/dise_all/data/'
filelist = ['All_basic.csv']
#correctedcsv = '/home/megha/www/reports/databases/dise_db/dise_all/py_scripts/utilscripts/Verify_dise.lst'
updatesql = '/home/megha/www/reports/databases/dise_db/dise_all/db_scripts/load/update_klpwww_codes.sql'

dise_list = {}

connection = Utility.KLPDB.getConnection()
cursor = connection.cursor()

def populateLookup():
  for file in filelist:
    readfile = open(rootdir + file,'r')
    reader = csv.reader(readfile,delimiter='|')
    reader.next()
    for row in reader:
      dise_list[row[2].strip().upper()]=[row[1].strip(),row[0].strip(),row[3].strip(),row[4].strip()]
    readfile.close()
  print "Lookup_size" + str(len(dise_list.keys()))

    
def correctDiseIds():
  count = 0
  found_count = 0
  corrected_count = 0
  #writefile = open(correctedcsv,'w')
  updatefile = open(updatesql,'w')
  #writefile.write('DISTRICT|BLOCK|CLUSTER|KLPID|SCHOOL NAME|DISE CODE|NAME FROM DISE DB| CODE FROM DISE DB|DISTRICT FROM DISE|BLK FROM DISE|CLUSTER FROM DISE|MATCH\n')
  cursor.execute("select UPPER(b3.name),UPPER(b2.name),UPPER(b1.name),s.id,UPPER(S.name),s.dise_code from tb_school s, tb_boundary b1, tb_boundary b2, tb_boundary b3 where s.bid = b1.id and b1.parent=b2.id and b2.parent=b3.id and s.status=2;")
  result = cursor.fetchall()
  for row in result:
    name_in_dict = difflib.get_close_matches(row[4].strip().upper(),dise_list.keys())
    if len(name_in_dict) > 0:
      #writestr = '|'.join(map(str,row))+'|'+name_in_dict[0]+'|'+'|'.join(dise_list[name_in_dict[0]])
      if row[5]:
        if row[5].strip() == dise_list[name_in_dict[0]][0]:
          #writestr = writestr + '|Y'
	  found_count = found_count + 1
        else:
          dist = difflib.get_close_matches(row[0].strip(),[dise_list[name_in_dict[0]][1]])
          blk = difflib.get_close_matches(row[1].strip(),[dise_list[name_in_dict[0]][2]])
          clust = difflib.get_close_matches(row[2].strip(),[dise_list[name_in_dict[0]][3]])
          if len(dist)>0 and len(blk)>0 and len(clust)>0:
            updatefile.write('UPDATE tb_school SET dise_code=\'' + dise_list[name_in_dict[0]][0] + '\' where id=' + str(row[3]) + ';\n')
            #writestr = writestr + '|C'
	    corrected_count = corrected_count + 1
          else:
            #writestr = writestr + '|N'
            count = count + 1
      else:
        dist = difflib.get_close_matches(row[0].strip(),[dise_list[name_in_dict[0]][1]])
        blk = difflib.get_close_matches(row[1].strip(),[dise_list[name_in_dict[0]][2]])
        clust = difflib.get_close_matches(row[2].strip(),[dise_list[name_in_dict[0]][3]])
        if len(dist)>0 and len(blk)>0 and len(clust)>0:
          updatefile.write('UPDATE tb_school SET dise_code=\'' + dise_list[name_in_dict[0]][0] + '\' where id=' + str(row[3]) + ';\n')
          #writestr = writestr + '|C'
	  corrected_count = corrected_count + 1
        else:
          #writestr = writestr + '|N'
          count = count + 1
    else:
      #writestr = '|'.join(map(str,row))+'||||||N'
      count = count + 1
    #writefile.write(writestr+'\n')

  #writefile.close()
  print "Schools not found:" + str(count)
  print "Schools found:" + str(found_count)
  print "Schools corrected:" + str(corrected_count)
  updatefile.close()

try:
  populateLookup()
  correctDiseIds()
except:
  print "Unexpected error:", sys.exc_info()
  print "Exception in user code:"
  print '-'*60
  traceback.print_exc(file=sys.stdout)
  print '-'*60
