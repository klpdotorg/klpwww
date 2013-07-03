#!/usr/bin/env python
import csv
import sys
import re
import os
import difflib
import traceback

rootdir = '../'

mpmlafile=open(rootdir+"db_scripts/load/tb_school_electedrep.sql",'w')
logfile=open("school_rep_log.txt","a",0)

wardDict = {}
mpDict = {}
mlaDict = {}

def populateLookups():
  dictfile = open(rootdir+'data/tb_elected_rep.lst','r')
  lines = dictfile.readlines()
  for line in lines[2:-2]:
    data = line.split('|')
    if data[3].strip().strip('\n') == 'Ward':
      wardDict[data[1].strip()] = data[0].strip()
    elif data[3].strip().strip('\n') == 'MP Constituency':
      mpDict[data[1].strip()] = data[0].strip()
    else:
      mlaDict[data[1].strip()] = data[0].strip()
  dictfile.close()
    
def main():
  #SCHOOL 
  readfile = open(rootdir+'data/mla_mp_school.csv','r')
  data = csv.reader(readfile)
  for row in data:
    try:
      school_id = int(row[3].strip())
      wardkey = difflib.get_close_matches(row[7].strip().upper(),wardDict.keys())
      ward_id = wardDict[wardkey[0]] if len(wardkey) != 0 else 'null' 
      mpkey = difflib.get_close_matches(row[6].strip().upper(),mpDict.keys())
      mp_id = mpDict[mpkey[0]] if len(mpkey) != 0 else 'null' 
      mlakey = difflib.get_close_matches(row[5].strip().upper(),mlaDict.keys())
      #print row[8].strip() + ' ' + str(mlakey)
      mla_id = mlaDict[mlakey[0]] if len(mlakey) != 0 else 'null' 
      mpmlafile.write("INSERT INTO tb_school_electedrep values("+str(school_id)+","+ ward_id+","+mla_id+","+mp_id+",1);\n")
    except:
      print "Invalid schoolid" + row[5].strip()
      #print "Unexpected error:", sys.exc_info()
      #print "Exception in user code:"
      #print '-'*60
      #traceback.print_exc(file=sys.stdout)
      #print '-'*60

  #PRESCHOOL
  readfile = open(rootdir+'data/mla_mp_preschool.csv','r')
  data = csv.reader(readfile)
  for row in data:
    try:
      school_id = int(row[3].strip())
      wardkey = difflib.get_close_matches(row[7].strip().upper(),wardDict.keys())
      ward_id = wardDict[wardkey[0]] if len(wardkey) != 0 else 'null'
      mpkey = difflib.get_close_matches(row[6].strip().upper(),mpDict.keys())
      mp_id = mpDict[mpkey[0]] if len(mpkey) != 0 else 'null' 
      mlakey = difflib.get_close_matches(row[5].strip().upper(),mlaDict.keys())
      mla_id = mlaDict[mlakey[0]] if len(mlakey) != 0 else 'null'
      mpmlafile.write("INSERT INTO tb_school_electedrep values("+str(school_id)+","+ ward_id+","+mla_id+","+mp_id+",2);\n")
    except:
      print "Invalid schoolid" + row[3].strip()

populateLookups()
main()
