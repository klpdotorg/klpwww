#!/usr/bin/env python
import xml.dom.minidom
import csv
#import Levenshtein
import difflib
from xml.dom.minidom import Node
ac_datacsv = open('../data/AC_electedreps.csv','r')
pc_datacsv = open('../data/PC_electedreps.csv','r')

ac_dict={}
pc_dict={}

ac_datasource = open('../data/AC_LATLONG.xml')
pc_datasource = open('../data/PC_LATLONG.xml')
ac_corrections = open('../data/AC_missed_consts.csv','r')
pc_corrections = open('../data/PC_missed_consts.csv','r')
wf = open('../db_scripts/load/tb_electedrep_insert.sql','w')

ac_dom = xml.dom.minidom.parse(ac_datasource)
pc_dom = xml.dom.minidom.parse(pc_datasource)

def getText(nodelist):
    rc = []
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            rc.append(node.data)
    return ''.join(rc)

def populateLookup():
  ac_data = csv.reader(ac_datacsv)
  for data in ac_data:
    ac_dict[data[1].strip().upper()] = [data[3].strip(),data[0].strip(),data[2].strip() if len(data[2].strip())>0 else '']
  ac_datacsv.close()
  pc_data = csv.reader(pc_datacsv)
  for data in pc_data:
    pc_dict[data[1].strip().upper()] = [data[2].strip(),data[0].strip(),data[3].strip() if len(data[3].strip())>0 else '']
  pc_datacsv.close()
  
def handleConstituency(dom,isAC):
  if isAC == 'Y':
    parentAttr = 'AC_LATLONG'
    stateAttr = 'ST_NAME'
    constAttr = 'AC_NAME'
    enumVal = 'MLA Constituency'
  else:
    parentAttr = 'PC_LATLONG'
    stateAttr = 'ST_NAME'
    constAttr = 'PC_NAME'
    enumVal = 'MP Constituency'

  for node in dom.getElementsByTagName(parentAttr):
    if 'KARNATAKA' in node.getElementsByTagName(stateAttr)[0].toxml():
      electedrep = []
      ac_name = node.getElementsByTagName(constAttr)[0].toxml()
      ac_name_str = ac_name[9:len(ac_name)-10].upper().strip('\'')
      if isAC == 'Y':
        key_str = difflib.get_close_matches(ac_name_str,ac_dict.keys())
        if len(key_str) > 0:
          electedrep = ac_dict[key_str[0]]
      else:
        key_str = difflib.get_close_matches(ac_name_str,pc_dict.keys())
        if len(key_str) > 0:
          electedrep = pc_dict[key_str[0]]
      #KARNATAKA is already inserted and is the first record so id=1
      if len(electedrep) > 0:
        wf.write('insert into tb_electedrep_master (parent,const_ward_name,const_ward_type,current_elected_rep,elec_comm_code,current_elected_party) values (2,\'' \
                                              + ac_name_str + '\',\'' + enumVal + '\',\'' + electedrep[0] + '\',' + electedrep[1] + ',\'' + electedrep[2] + '\');\n')


# This function will take care of the constiuencies missed in the AC/ PC Lat Long XMLs and but available in the CSV with elected rep names.
def addMissedConsts():
  data = ac_corrections.readlines()[0].split(',')
  for row in data:
    key_str = difflib.get_close_matches(row.strip(),ac_dict.keys())
    if len(key_str) > 0:
      electedrep = ac_dict[key_str[0]]
    wf.write('insert into tb_electedrep_master (parent,const_ward_name,const_ward_type,current_elected_rep,elec_comm_code,current_elected_party,entry_year) values (2,\'' \
                                              + row.strip() + '\',\'MLA Constituency\',\'' + electedrep[0] + '\',' + electedrep[1] + ',\'' + electedrep[2] + '\',\'2012\');\n')
  data = pc_corrections.readlines()[0].split(',')
  for row in data:
    key_str = difflib.get_close_matches(row.strip(),pc_dict.keys())
    if len(key_str) > 0:
      electedrep = pc_dict[key_str[0]]
    wf.write('insert into tb_electedrep_master (parent,const_ward_name,const_ward_type,current_elected_rep,elec_comm_code,current_elected_party,entry_year) values (2,\'' \
                                              + row.strip() + '\',\'MP Constituency\',\'' + electedrep[0] + '\',' + electedrep[1] + ',\'' + electedrep[2] + '\',\'2012\');\n')
  ac_corrections.close()
  pc_corrections.close()

populateLookup()
handleConstituency(ac_dom,'Y')
handleConstituency(pc_dom,'N')
addMissedConsts()
ac_dom.unlink()
pc_dom.unlink()
wf.close()


