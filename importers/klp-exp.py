#!/usr/bin/env python
import Utility.EXIF
import os,sys
import psycopg2
import Utility.KLPDB



connection = Utility.KLPDB.getConnection()
cursor = connection.cursor()

pidAyid={'1':90,'2':1,'3':2,'5':119,'6':119,'7':119,'8':119,'9':119,'10':119,'11':119,'12':119,'13':119,'14':101,'15':101,'18':101,'19':102,'23':102,'24':102,'25':102,'26':102,'27':102,'28':102,'29':102,'30':102,'31':102}


queries=[{'tb_bhierarchy':'select distinct id,boundary_category from schools_boundary_category'},
{'tb_boundary_type' : "select id,boundary_type from schools_boundary_type"},
{'tb_boundary' : "select id,parent_id,name,boundary_category_id,boundary_type_id from schools_boundary where not name='No Parent'"},
{'tb_address': 'select * from schools_institution_address'},
{'tb_school': 'select inst.id,inst.boundary_id,inst.inst_address_id,inst.dise_code,inst.name,cat.name,inst.institution_gender,moi.name,mgmt.name,inst.active from schools_institution inst left outer join schools_institution_category cat on (inst.cat_id=cat.id) left outer join schools_institution_languages lang on (lang.institution_id=inst.id) left outer join schools_moi_type moi on (moi.id=moi_type_id) left outer join schools_institution_management mgmt on (inst.mgmt_id=mgmt.id)'},
{'tb_child' : 'select c.id,lower(trim(c."firstName")),lower(trim(c."middleName")),lower(trim(c."lastName")),to_char(c.dob, \'YYYY-MM-DD\') as dob,c.gender,mt.name from schools_child c left outer join schools_moi_type mt on (c.mt_id=mt.id)'},
{'tb_class':"select id,institution_id,name,section from schools_studentgroup where group_type='Class'"},
{'tb_academic_year':'select * from schools_academic_year'},
{'tb_student':'select * from schools_student'},
{'tb_student_class':"select stusg.student_id,stusg.student_group_id,stusg.academic_id,stusg.active from schools_student_studentgrouprelation stusg,schools_studentgroup sg where stusg.student_group_id=sg.id and sg.group_type='Class'"},
{'tb_programme':'select id,name,"startDate","endDate",programme_institution_category_id from schools_programme where id in (1,2,3,5,6,7,8,9,14,15,18,19,23,24,25,26,27,28,29,30,31)'},
{'tb_assessment':'select ass.id,ass.name,ass.programme_id,ass."startDate",ass."endDate" from schools_assessment ass,schools_programme p where ass.programme_id=p.id and p.id in (1,2,3,5,6,7,8,9,14,15,18,19,23,24,25,26,27,28,29,30,31)'},
{'tb_question':'select q.id,q.assessment_id,q.name,q."questionType",q."scoreMax",q."scoreMin",q.grade from schools_question q, schools_assessment ass,schools_programme p where q.assessment_id=ass.id and ass.programme_id=p.id and p.id in (1,2,3,5,6,7,8,9,14,15,18,19,23,24,25,26,27,28,29,30,31)'},
{'tb_student_eval':'select se.question_id,se.object_id,se."answerScore",se."answerGrade" from schools_answer se,schools_question q, schools_assessment ass,schools_programme p where se.question_id=q.id and q.assessment_id=ass.id and ass.programme_id=p.id and p.id in (1,2,3,5,6,7,8,9,14,15,18,19,23,24,25,26,27,28,29,30,31)'},
{'tb_teacher': 'select t.id,lower(trim(t."firstName")),lower(trim(t."middleName")),lower(trim(t."lastName")),t.gender,t.active,mt.name,t.doj,type."staffType" from schools_staff t left outer join schools_moi_type mt on (t.mt_id=mt.id) left outer join schools_staff_type type on (t.staff_type_id=type.id)'},
{'tb_teacher_qual':'select sq.staff_id,qual.qualification from schools_staff_qualification sq,schools_staff_qualifications qual where sq.staff_qualifications_id=qual.id'},
{'tb_teacher_class': 'select staff_id,student_group_id,academic_id,active from schools_staff_studentgrouprelation'}]


loadfile=open('load/load.sql','w',0)

def getRow(row):
  line=str(row).strip('(')
  line = line.strip(')')
  line = line.strip()
  line = line.replace('\'','"')
  line = line.replace('None','')
  return line


def getDataName(cursor,file):
   for row in cursor:
    firstdata=1
    datacount=0
    name=""
    namecheck=0
    for data in row:
      datacount=datacount+1
      data=str(data)
      print data+" "+str(datacount)+" "+str(namecheck)
      if datacount==2:
        namecheck=1
        if data=='None':
          data=''
        name=data
      if datacount==3:
        namecheck=1
        if data=='None':
          data=''
        else:
          name=name+" "+data
      if datacount==4:
        if data=='None':
          data=''
        else:
          name=name+" "+data
        data=name
        namecheck=0
      print namecheck
      if namecheck:
         continue  
      if firstdata:
        if data=="":
          file.write(data)
        elif data=='None':
          file.write('')
        else:
          file.write('"'+data+'"')
        firstdata=0
      else:
        if data=="":
          file.write(","+data)
        elif data=="None":
          file.write(',')
        else:
          file.write(',"'+data+'"')
    file.write("\n")

def insertAyid(cursor,file):
  for row in cursor:
    firstdata=1
    pid=''
    for data in row:
      data=str(data)
      if firstdata:
        if data=="":
          file.write(data)
        elif data=='None':
          file.write('')
        else:
          pid=data
          file.write(data)
        firstdata=0
      else:
        if data=="":
          file.write(","+data)
        elif data=="None":
          file.write(',')
        else:
          file.write(',"'+data+'"')
    file.write(',"'+str(pidAyid[pid])+'"')
    file.write("\n")
 

def make_csv(tbname,query):
  filename='load/'+tbname+'.csv'
  loadfile.write("copy "+tbname+" from "+"'"+os.getcwd()+"/"+filename+"' with csv;\n")
  file=open(filename,'w',0)
  print "Executing qurey"
  sys.stdout.flush()
  cursor.execute(query)
  print "Finished executing query"
  sys.stdout.flush()
  #result = cursor.fetchall()
  #count=0
  if tbname=="tb_child" or tbname=="tb_teacher":
    getDataName(cursor,file)
  if tbname=="tb_programme":
    insertAyid(cursor,file)
  else:
   for row in cursor:
    firstdata=1
    for data in row:
      data=str(data)
      if firstdata:
        if data=="":
          file.write(data)
        elif data=='None':
          file.write('')
        else:
          file.write('"'+data+'"')
        firstdata=0
      else:
        if data=="":
          file.write(","+data)
        elif data=="None":
          file.write(',')
        else:
          file.write(',"'+data+'"')
    file.write("\n")
  

for query in queries:
  for tbname in query:
    print tbname
    sys.stdout.flush()
    make_csv(tbname,query[tbname])


connection.close()
