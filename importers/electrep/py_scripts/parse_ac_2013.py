#!/usr/bin/env python
import csv

mlaDict = {} 
alternateDict = {}

def populateLookups():
  dictfile = open('../data/tb_mla_2012.lst','r')
  lines = dictfile.readlines()
  for line in lines[2:-2]:
    data = line.split('|')
    if data[1].strip() not in mlaDict.keys():
      mlaDict[data[1].strip()] = [data[0].strip(),data[2].strip(),data[3].strip(),data[4].strip()]
    else:
      print "DUPLICATE:" + line
    if data[2].strip() not in alternateDict.keys():
      alternateDict[data[2].strip()] = [data[0].strip(),data[1].strip(),data[3].strip(),data[4].strip()]
    else:
      print "DUPLICATE:" + line
  dictfile.close()

def updateMlaRecords():
  wf = open('../db_scripts/load/tb_electedrep_update_2013.sql','w')
  rf = csv.reader(open('../data/eciresults.csv','r'),delimiter=';')
  rf.next()
  for row in rf:
    if row[3].strip() in mlaDict.keys():
    	mla = mlaDict[row[3].strip()]
    	wf.write('update tb_electedrep_master set prev_elected_rep=\'' + mla[2] + '\', prev_elected_party=\'' + mla[3] + '\', losing_elected_party = \'' + row[9].strip() + '\', current_elected_rep=\'' + row[2].strip() + '\', current_elected_party=\'' + row[4].strip() + '\', entry_year=\'2013\' where id=' + mla[0] + ';\n')
        print 'Found by code ' + mla[1] + ':' + row[0]
    elif row[0].strip() in alternateDict.keys():
    	mla = alternateDict[row[0].strip()]
    	wf.write('update tb_electedrep_master set prev_elected_rep=\'' + mla[2] + '\', prev_elected_party=\'' + mla[3] + '\', losing_elected_party = \'' + row[9].strip() + '\', current_elected_rep=\'' + row[2].strip() + '\', current_elected_party=\'' + row[4].strip() + '\', entry_year=\'2013\' where id=' + mla[0] + ';\n')
        print 'Found by name ' + mla[1] + ':' + row[3]
    else:
        wf.write('insert into tb_electedrep_master (parent,const_ward_name,const_ward_type,current_elected_rep,elec_comm_code,current_elected_party,entry_year) values (2,\'' + row[0].strip() + '\',\'MLA Constituency\',\'' + row[2].strip()+ '\',' + row[3].strip() + ',\'' + row[4].strip() + '\',\'2013\');\n')
        print 'Not found so inserted' + row[3] +':'+ row[0]

  wf.close()

populateLookups()
updateMlaRecords()


