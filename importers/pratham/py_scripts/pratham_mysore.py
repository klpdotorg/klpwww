#!/usr/bin/env python
import os,sys
import csv
import Utility.KLPDB


connection = Utility.KLPDB.getConnection()
cursor = connection.cursor()

def getInt(val):
  if len(val.strip()) == 0:
    return 0
  else:
    return int(val.strip())

filelist = ["Pratham_Mysore.csv"]
datafile=open("../db_scripts/load/pratham_mysore.sql",'w')
pratham_assessment=open("../db_scripts/load/pratham_assessment.sql",'w')
pratham_assessment_eval=open("../db_scripts/load/pratham_assessment_eval.sql",'w')
pratham_assessment_agg=open("../db_scripts/load/pratham_assessment_agg.sql",'w')


domain={10001:'Students/Teachers',
        10002:'Students/Teachers',
        10003:'Midday Meal',
        10004:'Midday Meal',
        10005:'Infrastructure',
        10006:'Infrastructure',
        10007:'Infrastructure',
        10008:'Library',
        10009:'Library',
        10010:'Water and Sanitation',
        10011:'Infrastructure',
        10012:'Infrastructure',
        10013:'Infrastructure',
        10014:'Water and Sanitation',
        10015:'Water and Sanitation',
        10016:'Water and Sanitation',
        10017:'Water and Sanitation',
        10018:'Water and Sanitation',
        10019:'Water and Sanitation',
        10020:'Water and Sanitation',
        10021:'Water and Sanitation',
        10022:'Water and Sanitation'
}
        

pratham_assessment.write("INSERT INTO tb_partner values(2,'Pratham Mysore',1,'Mysore');\n")
pratham_assessment.write("INSERT INTO tb_programme values(1001,'School Information','1-6-2012','1-8-2012',1,121,2);\n")
pratham_assessment.write("INSERT INTO tb_assessment values(1001,'School Assessment',1001,'1-6-2012','1-8-2012');\n")

questionid={'Number of Students':10001,
'Number of Teachers':10002,
'Was midday meal served during the day of visit?':10003,
'Was midday meal cooked in the school?':10004,
'Total number of rooms in the school':10005,
'Total number of rooms in the school used for teaching':10006,
'Playground present':10007,
'Library books available':10008,
'Library being used':10009,
'Drinking water available':10010,
'Boundary wall/fencing available':10011,
'Computer facility present':10012,
'Children using computer':10013,
'Girls Toilet available':10014,
'Boys Toilet available':10015,
'Common Toilet available':10016,
'Girls Toilet Locked':10017,
'Boys Toilet Locked':10018,
'Common Toilet Locked':10019,
'Girls Toilet Usable':10020,
'Boys Toilet Usable':10021,
'Common Toilet Usable':10022
}
for question in questionid:
  pratham_assessment.write('insert into tb_question (id, "desc" , assid) values('+str(questionid[question])+",'"+question+"',1001);\n")
pratham_questions={12:{'question':'Number of Students','interpretation':{}},
13:{'question':'Number of Students','interpretation':{}},
14:{'question':'Number of Students','interpretation':{}},
15:{'question':'Number of Students','interpretation':{}},
16:{'question':'Number of Students','interpretation':{}},
17:{'question':'Number of Students','interpretation':{}},
18:{'question':'Number of Students','interpretation':{}},
31:{'question':'Number of Teachers','interpretation':{}},
45:{'question':'Was midday meal served during the day of visit?','interpretation':{'1':'Yes','2':'No','':'No'}},
46:{'question':'Was midday meal cooked in the school?','interpretation':{'1':'Yes','2':'No','':'No'}},
49:{'question':'Total number of rooms in the school','interpretation':{}},
50:{'question':'Total number of rooms in the school used for teaching','interpretation':{}},
52:{'question':'Playground present','interpretation':{'1':'Yes','2':'No','':'No'}},
53:{'question':'Library books available','interpretation':{'1':'Yes','2':'No','':'No'}},
54:{'question':'Library being used','interpretation':{'1':'Yes','2':'No','':'No'}},
57:{'question':'Drinking water available','interpretation':{'1':'Yes','2':'No','':'No'}},
58:{'question':'Boundary wall/fencing available','interpretation':{'1':'Yes','2':'No','':'No'}},
59:{'question':'Computer facility present','interpretation':{'1':'Yes','2':'No','':'No'}},
60:{'question':'Children using computer','interpretation':{'1':'Yes','2':'No','':'No'}},
87:{'question':'Girls Toilet available','interpretation':{'1':'Yes','2':'No','':'No'}},
88:{'question':'Boys Toilet available','interpretation':{'1':'Yes','2':'No','':'No'}},
89:{'question':'Common Toilet available','interpretation':{'1':'Yes','2':'No','':'No'}},
91:{'question':'Girls Toilet Locked','interpretation':{'1':'Yes','2':'No','':'No'}},
92:{'question':'Boys Toilet Locked','interpretation':{'1':'Yes','2':'No','':'No'}},
93:{'question':'Common Toilet Locked','interpretation':{'1':'Yes','2':'No','':'No'}},
95:{'question':'Girls Toilet Usable','interpretation':{'1':'Yes','2':'No','':'No'}},
96:{'question':'Boys Toilet Usable','interpretation':{'1':'Yes','2':'No','':'No'}},
98:{'question':'Common Toilet Usable','interpretation':{'1':'Yes','2':'No','':'No'}},
}

schoolquestions={}
schoolid={}
def main():
  for file in filelist:
    csvbuffer = csv.reader(open('../data/'+file,'rb'), delimiter='|') 
    header = csvbuffer.next()
    count=0
    for row in csvbuffer:
      count=count+1
      disecode=row[105].strip()
      cursor.execute("select distinct id from schools_institution where dise_code='"+disecode+"'")
      result=cursor.fetchall()
      sid=0
      for r in result:
        sid=r[0]
      if sid==0:
        print "not found :"+disecode+"."
      schoolid[disecode]=sid
      datafile.write("INSERT INTO tb_school_info values('MYSORE','" + row[3].strip() +"','"+row[1].strip()+"','"+row[2].strip()+"','"+row[4].strip()+"','"+row[28].strip()+"','"+row[105].strip()+"');\n")
      pratham_assessment_agg.write("INSERT INTO tb_school_assessment_agg(sid,assid,aggtext) values("+str(sid)+",'1001','Assessment Present');\n")
      schoolquestions[disecode]={}
      for columnnum in pratham_questions:
        data=row[columnnum].strip()
        if pratham_questions[columnnum]['question'] not in schoolquestions[disecode]:
          if pratham_questions[columnnum]['interpretation']=={}:
            schoolquestions[disecode][pratham_questions[columnnum]['question']]=data
          else:
            schoolquestions[disecode][pratham_questions[columnnum]['question']]=pratham_questions[columnnum]['interpretation'][data]
        else:
          if data=='':
            data=0
          schoolquestions[disecode][pratham_questions[columnnum]['question']]=int(schoolquestions[disecode][pratham_questions[columnnum]['question']])+int(data)
        
  for school in schoolquestions:
    for question in schoolquestions[school]:
      pratham_assessment_eval.write("INSERT INTO tb_school_eval values('"+str(schoolid[school])+"','"+str(school)+"','"+str(domain[questionid[question]])+"','"+str(questionid[question])+"','"+str(schoolquestions[school][question])+"');\n")

main()
