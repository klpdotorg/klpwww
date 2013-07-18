#!/usr/bin/env python
import os
import sys
import traceback

import csv
import Utility.KLPDB

connection = Utility.KLPDB.getConnection()
cursor = connection.cursor()

filelist = {"lib_reading_kan.csv":["tb_assessment","2011-2012"]}

def check_empty(value):

    if len(value.strip()) == 0:
        return 'null'
    else:
        try:
            num = int(value)
            return value.strip()
        except:
            print "Value of " + value + " was discarded and set to null"
            return 'null'

def verify_student(stu_id,sch_id,cls,ay):
    if stu_id == '':
        return None
    query = '';
    is_tmpid = False
    try:
        stu_id = int(stu_id)
    except:
        is_tmpid = True
    if is_tmpid:
        if 'TMP' in stu_id.upper():
            query = "select s.id,sg.name,sg.sid from tb_student s ,tb_class sg, tb_student_class ssg, tb_academic_year ay where ssg.clid = sg.id and ssg.stuid = s.id and ssg.ayid = ay.id and ay.name = '" + ay + "' and s.otherstudentid = '" + str(stu_id).strip().upper() + "';"
    else:
        query = "select s.id,sg.name,sg.sid from tb_student s ,tb_class sg, tb_student_class ssg, tb_academic_year ay where ssg.clid = sg.id and ssg.stuid = s.id and ssg.ayid = ay.id and ay.name = '" + ay + "' and s.id = " + str(stu_id).strip() + ";"
    if len(query) > 0:
        cursor.execute(query)
        results = cursor.fetchall()
        for data in results:
            if str(data[2]) == str(sch_id) and data[1].strip() == cls:
                return data[0]    
            else:
                return None
        connection.commit()
    

def get_gender(gender):

    if gender.strip() == 'M':
        return 'boy'
    elif gender.strip() == 'F':
        return 'girl'
    else:
        return 'err'

def get_class(cls):
    
    if len(cls) > 0:
        if str(cls[:1]) == 'N':
            return 'null'
        return str(cls[:1])
    else:
        return 'null'

def get_grade(grade):
    
    grade_str = 'null' 
    if len(grade) > 0:
        grade_str = grade[:1]
        if grade.upper().strip() == 'STORY':
          grade_str = 'P'
    '''
    if grade_str in ['Z','L','P','W','S']:
        if grade_str == 'Z':
            return 'O'
        elif grade_str == 'P':
            return 'S'
        elif grade_str == 'S':
            return 'P'
        else:
            return grade_str
    else:
        return grade_str
    '''
    return grade_str


try:
    for file in filelist.keys():
        datafile=open("load/" + filelist[file][0] + '.sql' ,'w')
        csvbuffer = csv.reader(open('data/'+file,'rb'), delimiter='|') 
        header = csvbuffer.next()
        headlen = len(header)
        for row in csvbuffer:
            sch_id = row[1].strip()
            if sch_id!= None and len(sch_id) > 0:
                stu_id = row[3] #verify_student(row[3],row[1],get_class(row[5]),filelist[file][1])
                if stu_id != None and len(stu_id.strip()) > 0:
                    datafile.write("INSERT INTO " + filelist[file][0] + " values(" + sch_id + ",'" + row[0].strip() + "','" + str(stu_id) + "','" + row[2].strip("'").strip("\"") + "','" + filelist[file][1] + "','" + get_gender(row[4]) + "'," + get_class(row[5]) + ",'" + get_grade(row[6]) + "');\n" )
                else:
                    pass
        datafile.close()
except:
    print "Unexpected error:", sys.exc_info()
    print "Exception in user code:"
    print '-'*60
    traceback.print_exc(file=sys.stdout)
    print '-'*60
finally:
    cursor.close()
    connection.close()
