#!/usr/bin/env python
import csv
import sys
import re
import os
import difflib
import traceback
import Utility.KLPDB

rootdir = '../'

mpmlafile=open(rootdir+"db_scripts/load/tb_school_electedrep_missing.sql",'w')
updatefile=open(rootdir+"db_scripts/load/tb_school_electedrep_part_update.sql",'w')
logfile=open("school_rep_update_log.txt","a",0)

wardDict = {}
wardDict_bycode = {}
mpDict = {}
mlaDict = {}
dbschoollist = []

def populateLookups():
  dictfile = open(rootdir+'data/tb_elected_rep.lst','r')
  lines = dictfile.readlines()
  for line in lines[2:-2]:
    data = line.split('|')
    if data[3].strip().strip('\n') == 'Ward':
      wardDict[data[1].strip()] = [data[0].strip(),data[2].strip()]
      wardDict_bycode[data[2].strip()] = [data[0].strip(),data[1].strip()]
    elif data[3].strip().strip('\n') == 'MP Constituency':
      mpDict[data[1].strip()] = [data[0].strip(),data[2].strip()] 
    else:
      mlaDict[data[1].strip()] = [data[0].strip(),data[2].strip()] 
  dictfile.close()
  dictfile = open(rootdir+'data/tb_school_rep.lst','r')
  lines = dictfile.readlines()
  for line in lines[2:-2]:
    dbschoollist.append(str(line).strip())
  dictfile.close()
    
def missing_all():
  filedict = {}
  for i in range(1,13):
    readfile = open(rootdir+'data/missing/missinglist_sch_' + str(i) + '.csv','r')
    for line in readfile.readlines()[1:]:
      row = line.split(',')
      try:
        stype = 0
        if row[0].strip() == 'SCHOOL':
          stype = 1
        else:
          stype = 2
        school_id = int(row[4].strip())
        if school_id not in dbschoollist:
          try:
            ward_id = int(row[11])
          except:
            wardkey = difflib.get_close_matches(row[11].strip().upper(),wardDict.keys())
            ward_id = wardDict[wardkey[0]][0] if len(wardkey) != 0 else 'null' 
          mpkey = difflib.get_close_matches(row[7].strip().upper(),mpDict.keys())
          mp_id = mpDict[mpkey[0]][0] if len(mpkey) != 0 else 'null' 
          mlakey = difflib.get_close_matches(row[9].strip().upper(),mlaDict.keys())
          mla_id = mlaDict[mlakey[0]][0] if len(mlakey) != 0 else 'null' 
          if mla_id == 'null' and mp_id == 'null' and ward_id == 'null':
            pass
          else:
            #insertsql = "INSERT INTO tb_school_electedrep values(" + str(school_id) + "," + str(ward_id) + "," + str(mla_id) + "," + str(mp_id) + "," + str(stype) + ");\n"
            updatesql = "update tb_school_electedrep set ward_id=" + str(ward_id) + ",mla_const_id=" + str(mla_id) + ",mp_const_id=" + str(mp_id) + " where sid=" + str(school_id)  + ";\n"
            if school_id in filedict.keys():
              if len(updatesql.replace('null','')) > len(filedict[school_id].replace('null','')):
                filedict[school_id] = updatesql
            else:
              filedict[school_id] = updatesql
        count = 0
      except:
        print "Invalid schoolid" + row[4].strip()
        print "Unexpected error:", sys.exc_info()
        print "Exception in user code:"
        print '-'*60
        traceback.print_exc(file=sys.stdout)
        print '-'*60
  for key in filedict.keys():
    mpmlafile.write(filedict[key])
    count = count + 1
    print count

def missing_part():
  filedict = {}
  strlist = ['mp','mla','ward']
  for each in strlist:
    readfile = open(rootdir+'data/missing/' + each + '_missing_only.csv','r')
    for line in readfile.readlines()[1:]:
      row = line.split(',')
      try:
        school_id = int(row[4].strip())
        if each == 'mp':
          mpkey = difflib.get_close_matches(row[6].strip().upper(),mpDict.keys())
          mp_id = mpDict[mpkey[0]][0] if len(mpkey) != 0 else 'null' 
          updatefile.write('UPDATE tb_school_electedrep set mp_const_id=' + str(mp_id) + ' where sid=' + str(school_id) + ';\n')
        if each == 'mla':
          mlakey = difflib.get_close_matches(row[6].strip().upper(),mlaDict.keys())
          mla_id = mlaDict[mlakey[0]][0] if len(mlakey) != 0 else 'null' 
          updatefile.write('UPDATE tb_school_electedrep set mla_const_id=' + str(mla_id) + ' where sid=' + str(school_id) + ';\n')
        if each == 'ward':
          wardkey = difflib.get_close_matches(row[6].strip().upper(),wardDict.keys())
          ward_id = wardDict[wardkey[0]][0] if len(wardkey) != 0 else 'null' 
          updatefile.write('UPDATE tb_school_electedrep set ward_id=' + str(mla_id) + ' where sid=' + str(school_id) + ';\n')
      except:
        print "Invalid schoolid" + row[4].strip()
        print "Unexpected error:", sys.exc_info()
        print "Exception in user code:"
        print '-'*60
        traceback.print_exc(file=sys.stdout)
        print '-'*60

def geo_compare():
  rf = csv.reader(open('../data/missing/ward_updates.csv','r'),delimiter=';')
  rf.next()
  for row in rf:
    ward_id = ''
    if row[10].strip() in wardDict_bycode.keys():
      ward_id = wardDict_bycode[row[10].strip()][0] if len(row[10].strip()) != 0 else 'null' 
      updatefile.write('UPDATE tb_school_electedrep set ward_id=' + ward_id + ' where sid=' + str(row[7]).strip() + ';\n')
populateLookups()
missing_all()
missing_part()
geo_compare()
