import web
import psycopg2
import decimal
import jsonpickle
import csv
import re
import difflib
import smtplib,email,email.encoders,email.mime.text,email.mime.base,mimetypes
from web import form

# Needed to find the templates
import sys, os,traceback
abspath = os.path.dirname(__file__)
sys.path.append(abspath)
os.chdir(abspath)

from Utility import KLPDB

urls = (
     '/','mainmap',
     '/pointinfo/', 'getPointInfo',
     '/assessment/(.*)/(.*)/(.*)','assessments',
     '/visualization*','visualization',
     '/info/school/(.*)','getSchoolInfo',
     '/info/preschool/(.*)','getSchoolInfo',
     '/shareyourstory(.*)\?*','shareyourstory',
     '/schoolpage/(.*)/(.*)\?*','SchoolPage',
     '/info/(.*)/(.*)','getBoundaryInfo',
     '/boundaryPoints/(.*)/(.*)','getBoundaryPoints',
     '/text/(.+)', 'text',
     '/schoolInfo/(.*)','getSchoolBoundaryInfo',
     '/insertsys/(.*)','insertSYS',
     '/postSYS/(.*)','postSYS',
     '/sysinfo','getSYSInfo',
     '/listFiles/(.*)','listFiles',
)

class DbManager:

  con = None
  cursor = None
  syscon = None
  syscursor = None

  @classmethod
  def getMainCon(cls):
    if cls.con and cls.con.closed==0:
      pass
    else:
      cls.con = KLPDB.getConnection()
    return cls.con

  @classmethod
  def getSysCon(cls):
    if cls.syscon and cls.syscon.closed==0:
      pass
    else:
      cls.syscon = KLPDB.getSysConnection()
    return cls.syscon
   
mySchoolform =form.Form(
                   form.Hidden('schoolid'),
                   form.Textbox('name'),
                   form.Textbox('email'),
                   form.Textbox('telephone'),
                   form.Textbox('dateofvisit'),
                   form.File('file1'),
                   form.File('file2'),
                   form.File('file3'),
                   form.File('file4'),
                   form.File('file5'),
                   form.Textarea('comments'),
                   form.Hidden('chkboxes'))


myPreSchoolform =form.Form(
                   form.Hidden('schoolid'),
                   form.Textbox('name'),
                   form.Textbox('email'),
                   form.Textbox('telephone'),
                   form.Textbox('dateofvisit'),
                   form.File('file1'),
                   form.File('file2'),
                   form.File('file3'),
                   form.File('file4'),
                   form.File('file5'),
                   form.Textarea('comments'),
                   form.Hidden('chkboxes'))


preschoolAgeGroup=5
preschoolPids=['5','18']
pidType={"grade":[1,4,5,7,8,13,15,17,18,19,20,23,25],"mark":[2,3,6,9,10,11,12,14,16]}

baseassess = {"1":[1],
              "2":[5,6,7,8],
              "3":[13,14,15,16],
              "4":[21],
              "5":[23],
              "6":[25],
              "7":[27],
              "8":[30],
              "9":[33],
              "10":[35],
              "11":[37],
              "12":[39],
              "13":[40],
              "14":[41,43,45,47],
              "15":[49],
              "16":[51,53],
              "18":[56],
              "19":[59],
              "23":[65,66,67],
              "25":[70]
              }


statements = {'get_district':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='District' and b.id=bcoord.id_bndry order by b.name",
              'get_preschooldistrict':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='PreSchoolDistrict' and b.id=bcoord.id_bndry order by b.name",
              'get_block':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='Block' and b.id=bcoord.id_bndry order by b.name",
              'get_cluster':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='Cluster' and b.id=bcoord.id_bndry order by b.name",
              'get_project':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='Project' and b.id=bcoord.id_bndry order by b.name",
              'get_circle':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='Circle' and b.id=bcoord.id_bndry order by b.name",
              'get_school':"select inst.instid ,ST_AsText(inst.coord),upper(s.name) from vw_inst_coord inst, tb_school s,tb_boundary b,tb_bhierarchy bhier where s.id=inst.instid and s.bid=b.id and bhier.id = b.hid and b.type='1' order by s.name",
              'get_preschool':"select inst.instid ,ST_AsText(inst.coord),upper(s.name) from vw_inst_coord inst, tb_school s,tb_boundary b,tb_bhierarchy bhier where s.id=inst.instid and s.bid=b.id and bhier.id = b.hid and b.type='2' order by s.name",
              'get_district_points':"select distinct b1.id, b1.name from tb_boundary b, tb_boundary b1, tb_boundary b2,tb_bhierarchy hier where b.id=b1.parent and b1.id=b2.parent and b.hid=hier.id and b.type=1 and b.id=%s order by b1.name",
              'get_preschooldistrict_points':"select distinct b1.id, b1.name from tb_boundary b, tb_boundary b1,tb_boundary b2,tb_bhierarchy hier where b2.parent=b1.id and b1.parent = b.id and b.hid = hier.id and b.type=2 and b.id=%s",
              'get_block_points':"select distinct b2.id, b2.name from tb_boundary b, tb_boundary b1, tb_boundary b2,tb_bhierarchy hier where b.id=b1.parent and b1.id=b2.parent  and b.hid = hier.id and b.type=1 and b1.id=%s order by b2.name",
              'get_cluster_points':"select distinct s.id, s.name from tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s,tb_bhierarchy hier where b.id=b1.parent and b1.id=b2.parent and s.bid=b2.id and b.hid = hier.id and b.type=1 and b2.id=%s order by s.name",
              'get_project_points':"select distinct b2.id, b2.name from tb_boundary b, tb_boundary b1, tb_boundary b2,tb_bhierarchy hier where b.id=b1.parent and b1.id=b2.parent  and b.hid = hier.id and b.type=2 and b1.id=%s order by b2.name",
              'get_circle_points':"select distinct s.id, s.name from tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s,tb_bhierarchy hier where b.id=b1.parent and b1.id=b2.parent and s.bid=b2.id and b.hid = hier.id and b.type=2 and b2.id=%s order by s.name",
              'get_district_gender':"select sv.sex, sum(sv.num) from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b.id = %s group by sv.sex",
              'get_district_info':"select count(distinct sv.id),b.name from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b.id = %s group by b.name",
              'get_preschooldistrict_gender':"select sv.sex, sum(sv.num) from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b.id = %s group by sv.sex",
              'get_preschooldistrict_info':"select count(distinct sv.id),b.name from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b.id = %s group by b.name",
              'get_block_gender':"select sv.sex, sum(sv.num) from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b1.id = %s group by sv.sex",
              'get_block_info':"select count(distinct sv.id),b1.name from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b1.id = %s group by b1.name",
              'get_project_gender':"select sv.sex, sum(sv.num) from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2,tb_bhierarchy bhier where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b2.hid=bhier.id and b.type='2' and b1.id = %s group by sv.sex",
              'get_project_info':"select count(distinct sv.id),b1.name from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2,tb_bhierarchy bhier where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b2.hid=bhier.id and b.type='2' and b1.id = %s group by b1.name",
              'get_cluster_gender':"select sv.sex, sum(sv.num) from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b2.id = %s group by sv.sex",
              'get_cluster_info':"select count(distinct sv.id),b2.name from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b2.id = %s group by b2.name",
              'get_circle_gender':"select sv.sex, sum(sv.num) from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2,tb_bhierarchy bhier where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b2.hid=bhier.id and b.type='2'and b2.id = %s group by sv.sex",
              'get_circle_info':"select count(distinct sv.id),b2.name from tb_school_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2,tb_bhierarchy bhier where sv.bid = b2.id and b2.parent = b1.id and b1.parent = b.id and b2.hid=bhier.id and b.type='2' and b2.id = %s group by b2.name",
              'get_school_gender':"select sv.name, sv.sex, sum(sv.num) from tb_school_agg sv where sv.id = %s group by sv.name, sv.sex",
              'get_school_mt':"select sv.name, sv.mt, sum(sv.num) from tb_school_agg sv where sv.id = %s group by sv.name, sv.mt",
              'get_school_boundary_info':"select b.name, b1.name, b2.name, s.name,b.type from tb_boundary b, tb_boundary b1, tb_boundary b2, tb_school s,tb_bhierarchy h where s.id = %s and b.id=b1.parent and b1.id=b2.parent and s.bid=b2.id and b.hid=h.id",
              'get_num_stories':"select count(*) from tb_sys_data where schoolid= %s",
              'get_sys_qids':"select id, qfield from tb_sys_questions order by id",
              'get_sys_qtext':"select id, qtext from tb_sys_questions order by id",
              'get_sys_school_questions':"select * from tb_sys_displayq where hiertype=1 order by id",
              'get_sys_preschool_questions':"select * from tb_sys_displayq where hiertype=2 order by id",
              'get_programme_info':"select p.name,p.start,partner.name from tb_programme p,tb_partner partner where p.partnerid=partner.id and p.id =%s",
              'get_assessmentinfo_school':"select distinct p.name,p.start,p.id,pn.name from tb_programme p, tb_assessment ass, tb_school_assessment_agg agg, tb_partner pn where agg.sid =%s  and ass.id = agg.assid and p.id = ass.pid and p.partnerid=pn.id",
              'get_assessmentinfo_preschool':"select distinct p.name,p.start,p.id,pn.name from tb_programme p, tb_assessment ass, tb_preschool_assessment_agg agg, tb_partner pn where agg.sid =%s  and ass.id = agg.assid and p.id = ass.pid and p.partnerid=pn.id",
              'get_district_assessmentinfo':"select distinct p.name, p.start,p.id,pn.name from tb_programme p, tb_assessment ass, tb_school_assessment_agg agg, tb_boundary b, tb_boundary b1, tb_boundary b2, tb_school s,tb_bhierarchy hier, tb_partner pn where b.id=%s and b1.parent = b.id and b2.parent=b1.id and b.hid=hier.id and b.type=1 and s.bid=b2.id and agg.sid = s.id and ass.id = agg.assid and p.id = ass.pid and p.partnerid=pn.id",
              'get_block_assessmentinfo':"select distinct p.name, p.start,p.id ,pn.name from tb_programme p, tb_assessment ass, tb_school_assessment_agg agg, tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s,tb_bhierarchy hier, tb_partner pn where b.id = b1.parent and b1.id=b2.parent and b.hid=hier.id and b.type=1 and s.bid=b2.id and agg.sid = s.id and ass.id = agg.assid and p.id = ass.pid and b1.id=%s  and p.partnerid=pn.id",
              'get_cluster_assessmentinfo':"select distinct p.name, p.start,p.id,pn.name from tb_programme p, tb_assessment ass, tb_school_assessment_agg agg, tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s,tb_bhierarchy hier, tb_partner pn where b.id = b1.parent and b1.id=b2.parent and b.hid=hier.id and b.type=1 and s.bid=b2.id and agg.sid = s.id and ass.id = agg.assid and p.id = ass.pid and b2.id=%s  and p.partnerid=pn.id",
              'get_preschooldistrict_assessmentinfo':"select distinct p.name, p.start,p.id,pn.name from tb_programme p, tb_assessment ass, tb_preschool_assessment_agg agg, tb_boundary b, tb_boundary b1, tb_boundary b2, tb_school s,tb_bhierarchy hier, tb_partner pn where b.id=%s and b1.parent = b.id and b2.parent=b1.id and b.hid=hier.id and b.type=2 and s.bid=b2.id and agg.sid = s.id and ass.id = agg.assid and p.id = ass.pid  and p.partnerid=pn.id",
              'get_project_assessmentinfo':"select distinct p.name, p.start,p.id,pn.name from tb_programme p, tb_assessment ass, tb_preschool_assessment_agg agg, tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s,tb_bhierarchy hier, tb_partner pn where b.id = b1.parent and b1.id=b2.parent and b.hid=hier.id and b.type=2 and s.bid=b2.id and agg.sid = s.id and ass.id = agg.assid and p.id = ass.pid and b1.id=%s  and p.partnerid=pn.id",
              'get_circle_assessmentinfo':"select distinct p.name, p.start,p.id,pn.name from tb_programme p, tb_assessment ass, tb_preschool_assessment_agg agg, tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s,tb_bhierarchy hier, tb_partner pn where b.id = b1.parent and b1.id=b2.parent and b.hid=hier.id and b.type=2 and s.bid=b2.id and agg.sid = s.id and ass.id = agg.assid and p.id = ass.pid and b2.id=%s and p.partnerid=pn.id",
              'get_basic_assessmentinfo_school':"select info.assid,cl.name,info.sex,s.name, sum(info.num),b.id,b1.id,b2.id from tb_class cl, tb_school_basic_assessment_info info,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=%s and s.id=info.sid and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and info.clid=cl.id group by info.sex,s.name,b.id,b1.id,b2.id, info.assid,cl.name",
              'get_basic_assessmentinfo_district':"select info.assid,cl.name,info.sex,b.name, sum(info.num) from tb_class cl, tb_school_basic_assessment_info info ,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b.id=%s and info.clid=cl.id group by info.sex,b.name,info.assid,cl.name",
              'get_basic_assessmentinfo_block':"select info.assid,cl.name,info.sex,b1.name, sum(info.num) from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b1.id=%s and info.clid=cl.id group by info.sex,b1.name,info.assid,cl.name",
              'get_basic_assessmentinfo_cluster':"select info.assid,cl.name,info.sex,b2.name, sum(info.num) from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b2.id=%s and info.clid=cl.id group by info.sex,b2.name,info.assid,cl.name",
              'get_basic_assessmentinfo_preschool':"select info.assid,info.agegroup,info.sex,s.name, sum(info.num),b2.id,b1.id,b.id from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=%s and s.id=info.sid and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id  group by info.sex,s.name,b.id,b1.id,b2.id, info.assid,info.agegroup",
              'get_basic_assessmentinfo_preschooldistrict':"select info.assid,info.agegroup,info.sex,b2.name, sum(info.num) from tb_preschool_basic_assessment_info info ,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by info.sex,b2.name,info.assid,info.agegroup",
              'get_basic_assessmentinfo_project':"select info.assid,info.agegroup,info.sex,b1.name, sum(info.num) from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by info.sex,b1.name,info.assid,info.agegroup",
              'get_basic_assessmentinfo_circle':"select info.assid,info.agegroup,info.sex,b.name, sum(info.num) from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=s.id  and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by info.sex,b.name,info.assid,info.agegroup",
              'get_assessmentpertext_school':"select agg.assid,cl.name,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass where ass.pid=%s and agg.assid=ass.id and agg.sid=%s and agg.clid=cl.id group by agg.aggtext,agg.assid,cl.name",
              'get_assessmentpertext_district':"select agg.assid,cl.name,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b.id=%s and agg.clid=cl.id group by cl.name,agg.aggtext,agg.assid",
              'get_assessmentpertext_block':"select agg.assid,cl.name,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b1.id=%s and agg.clid=cl.id group by agg.aggtext,agg.assid,cl.name",
              'get_assessmentpertext_cluster':"select agg.assid,cl.name,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b2.id=%s and agg.clid=cl.id group by agg.aggtext,agg.assid,cl.name",
              'get_assessmentpertext_preschool':"select agg.assid,agg.agegroup,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass where ass.pid=%s and agg.assid=ass.id and agg.sid=%s group by agg.aggtext,agg.assid,agg.agegroup",
              'get_assessmentpertext_preschooldistrict':"select agg.assid,agg.agegroup,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by agg.agegroup,agg.aggtext,agg.assid",
              'get_assessmentpertext_project':"select agg.assid,agg.agegroup,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by agg.aggtext,agg.assid,agg.agegroup",
              'get_assessmentpertext_circle':"select agg.assid,agg.agegroup,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by agg.aggtext,agg.assid,agg.agegroup",
              'get_assessmentgender_school':"select agg.assid,cl.name,agg.sex,agg.aggtext, sum(agg.aggval) from tb_class cl, tb_school_assessment_agg agg,tb_assessment ass where ass.pid=%s and agg.assid=ass.id and agg.sid=%s and cl.id=agg.clid group by agg.sex,agg.aggtext,agg.assid,cl.name",
              'get_assessmentgender_district':"select agg.assid,cl.name,agg.sex,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b.id=%s and cl.id=agg.clid group by agg.sex,agg.aggtext,agg.assid,cl.name",
              'get_assessmentgender_block':"select agg.assid,cl.name,agg.sex,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b1.id=%s and cl.id=agg.clid group by agg.sex,agg.aggtext,agg.assid,cl.name",
              'get_assessmentgender_cluster':"select agg.assid,cl.name,agg.sex,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b2.id=%s and cl.id=agg.clid group by agg.sex,agg.aggtext,agg.assid,cl.name",
              'get_assessmentgender_preschool':"select agg.assid,agg.agegroup,agg.sex,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass where ass.pid=%s and agg.assid=ass.id and agg.sid=%s group by agg.sex,agg.aggtext,agg.assid,agg.agegroup",
              'get_assessmentgender_preschooldistrict':"select agg.assid,agg.agegroup,agg.sex,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by agg.sex,agg.aggtext,agg.assid,agg.agegroup",
              'get_assessmentgender_project':"select agg.assid,agg.agegroup,agg.sex,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by agg.sex,agg.aggtext,agg.assid,agg.agegroup",
              'get_assessmentgender_circle':"select agg.assid,agg.agegroup,agg.sex,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by agg.sex,agg.aggtext,agg.assid,agg.agegroup",
              'get_assessmentmt_count_school':"select info.assid,cl.name,info.mt,sum(info.num) from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass where ass.pid=%s and info.assid=ass.id and info.sid=%s and cl.id=info.clid group by info.mt,info.assid,cl.name",
              'get_assessmentmt_count_district':"select info.assid,cl.name,info.mt,sum(info.num) from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b.id=%s and cl.id=info.clid group by info.mt,info.assid,cl.name",
              'get_assessmentmt_count_block':"select info.assid,cl.name,info.mt,sum(info.num) from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b1.id=%s and cl.id=info.clid group by info.mt,info.assid,cl.name",
              'get_assessmentmt_count_cluster':"select info.assid,cl.name,info.mt,sum(info.num) from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b2.id=%s and cl.id=info.clid group by info.mt,info.assid,cl.name",
              'get_assessmentmt_count_preschool':"select info.assid,info.agegroup,info.mt,sum(info.num) from tb_preschool_basic_assessment_info info,tb_assessment ass where ass.pid=%s and info.assid=ass.id and info.sid=%s group by info.mt,info.assid,info.agegroup",
              'get_assessmentmt_count_preschooldistrict':"select info.assid,info.agegroup,info.mt,sum(info.num) from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by info.mt,info.assid,info.agegroup",
              'get_assessmentmt_count_project':"select info.assid,info.agegroup,info.mt,sum(info.num) from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by info.mt,info.assid,info.agegroup",
              'get_assessmentmt_count_circle':"select info.assid,info.agegroup,info.mt,sum(info.num) from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by info.mt,info.assid,info.agegroup",
              'get_assessmentmt_school':"select agg.assid,cl.name,agg.mt,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass where ass.pid=%s and agg.assid=ass.id and agg.sid=%s and cl.id=agg.clid group by agg.mt,agg.aggtext,agg.assid,cl.name",
              'get_assessmentmt_district':"select agg.assid,cl.name,agg.mt,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b.id=%s and cl.id=agg.clid group by agg.mt,agg.aggtext,agg.assid,cl.name",
              'get_assessmentmt_block':"select agg.assid,cl.name,agg.mt,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b1.id=%s and cl.id=agg.clid group by agg.mt,agg.aggtext,agg.assid,cl.name",
              'get_assessmentmt_cluster':"select agg.assid,cl.name,agg.mt,agg.aggtext, sum(agg.aggval) from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and b.id=b1.parent and b1.id=b2.parent and b2.id=s.bid and b2.id=%s and cl.id=agg.clid group by agg.mt,agg.aggtext,agg.assid,cl.name",
              'get_assessmentmt_preschool':"select agg.assid,agg.agegroup,agg.mt,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass where ass.pid=%s and agg.assid=ass.id and agg.sid=%s group by agg.mt,agg.aggtext,agg.assid,agg.agegroup",
              'get_assessmentmt_preschooldistrict':"select agg.assid,agg.agegroup,agg.mt,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by agg.mt,agg.aggtext,agg.assid,agg.agegroup",
              'get_assessmentmt_project':"select agg.assid,agg.agegroup,agg.mt,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by agg.mt,agg.aggtext,agg.assid,agg.agegroup",
              'get_assessmentmt_circle':"select agg.assid,agg.agegroup,agg.mt,agg.aggtext, sum(agg.aggval) from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by agg.mt,agg.aggtext,agg.assid,agg.agegroup",
              'get_progress_count_school':"select info.assid,cl.name,ass.name,sum(info.num),ass.start from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass where ass.pid=%s and info.assid=ass.id and info.sid=%s and cl.id=info.clid group by ass.name,ass.start,info.assid,cl.name order by ass.start,cl.name",
              'get_progress_count_district':"select info.assid,cl.name,ass.name,  sum(info.num),ass.start from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b2.id and b2.parent=b1.id and b1.parent=b.id and b.id=%s and cl.id=info.clid group by ass.name,ass.start,info.assid,cl.name  order by ass.start,cl.name",
              'get_progress_count_block':"select info.assid,cl.name,ass.name,  sum(info.num),ass.start from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b2.id and b2.parent=b1.id and b1.parent=b.id and b1.id=%s and cl.id=info.clid group by ass.name,ass.start,info.assid,cl.name order by ass.start,cl.name",
              'get_progress_count_cluster':"select info.assid,cl.name,ass.name,  sum(info.num),ass.start from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b2.id and b2.parent=b1.id and b1.parent=b.id and b2.id=%s and cl.id=info.clid group by ass.name,ass.start,info.assid,cl.name  order by ass.start,cl.name",
              'get_progress_count_preschool':"select info.assid,info.agegroup,ass.name,sum(info.num),ass.start from tb_preschool_basic_assessment_info info,tb_assessment ass where ass.pid=%s and info.assid=ass.id and info.sid=%s group by ass.name,ass.start,info.assid,info.agegroup order by ass.start,info.agegroup",
              'get_progress_count_preschooldistrict':"select info.assid,info.agegroup,ass.name,  sum(info.num),ass.start from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by ass.name,ass.start,info.assid,info.agegroup  order by ass.start,info.agegroup",
              'get_progress_count_project':"select info.assid,info.agegroup,ass.name,  sum(info.num),ass.start from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by ass.name,ass.start,info.assid,info.agegroup order by ass.start,info.agegroup",
              'get_progress_count_circle':"select info.assid,info.agegroup,ass.name,  sum(info.num),ass.start from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by ass.name,ass.start,info.assid,info.agegroup  order by ass.start,info.agegroup",
              'get_progress_school':"select agg.assid,s.name,cl.name,agg.aggtext,ass.name,  sum(agg.aggval),ass.start from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=%s and s.id = agg.sid and cl.id=agg.clid group by s.name,agg.aggtext,ass.name,ass.start,agg.assid,cl.name  order by ass.start,cl.name",
              'get_progress_district':"select agg.assid,b.name,cl.name,agg.aggtext,ass.name,   sum(agg.aggval),ass.start from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and b.id=b1.parent and b1.id = b2.parent and s.bid = b2.id and agg.sid=s.id and b.id = %s and cl.id=agg.clid group by b.name,agg.aggtext,ass.name,ass.start,agg.assid,cl.name  order by ass.start,cl.name",
              'get_progress_block':"select agg.assid,b1.name,cl.name,agg.aggtext,ass.name,   sum(agg.aggval),ass.start from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and b.id=b1.parent and b1.id = b2.parent and s.bid = b2.id and agg.sid=s.id and b1.id = %s and cl.id=agg.clid group by b1.name,agg.aggtext,ass.name,ass.start,agg.assid,cl.name  order by ass.start,cl.name",
              'get_progress_cluster':"select agg.assid,b2.name,cl.name,agg.aggtext,ass.name,   sum(agg.aggval),ass.start from tb_class cl,tb_school_assessment_agg agg,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and b.id=b1.parent and b1.id = b2.parent and s.bid = b2.id and agg.sid=s.id and b2.id = %s and cl.id=agg.clid group by b2.name,agg.aggtext,ass.name,ass.start,agg.assid,cl.name  order by ass.start,cl.name",
              'get_progress_preschool':"select agg.assid,s.name,agg.agegroup,agg.aggtext,ass.name,  sum(agg.aggval),ass.start from tb_preschool_assessment_agg agg,tb_assessment ass,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=%s and s.id = agg.sid group by s.name,agg.aggtext,ass.name,ass.start,agg.assid,agg.agegroup  order by ass.start,agg.agegroup",
              'get_progress_preschooldistrict':"select agg.assid,b2.name,agg.agegroup,agg.aggtext,ass.name,   sum(agg.aggval),ass.start from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by b2.name,agg.aggtext,ass.name,ass.start,agg.assid,agg.agegroup  order by ass.start,agg.agegroup",
              'get_progress_project':"select agg.assid,b1.name,agg.agegroup,agg.aggtext,ass.name,   sum(agg.aggval),ass.start from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by b1.name,agg.aggtext,ass.name,ass.start,agg.assid,agg.agegroup  order by ass.start,agg.agegroup",
              'get_progress_circle':"select agg.assid,b.name,agg.agegroup,agg.aggtext,ass.name,   sum(agg.aggval),ass.start from tb_preschool_assessment_agg agg,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by b.name,agg.aggtext,ass.name,ass.start,agg.assid,agg.agegroup  order by ass.start,agg.agegroup",
              'get_assessmentinfo_district':"select b.name,cl.name,ass.name,sum(info.num) from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and b.id=b1.parent and b1.id = b2.parent and s.bid = b2.id and info.sid=s.id and b.id = %s and cl.id=info.clid group by b.name,cl.name,ass.name",
              'get_assessmentinfo_block':"select b1.name,cl.name,ass.name,sum(info.num) from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and b.id=b1.parent and b1.id = b2.parent and s.bid = b2.id and info.sid=s.id and b1.id = %s and cl.id=info.clid group by b1.name,cl.name,ass.name",
              'get_assessmentinfo_cluster':"select b2.name,cl.name,ass.name,sum(info.num) from tb_class cl,tb_school_basic_assessment_info info,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and b.id=b1.parent and b1.id = b2.parent and s.bid = b2.id and info.sid=s.id and b2.id = %s and cl.id=info.clid group by b2.name,cl.name,ass.name",
              'get_assessmentinfo_preschooldistrict':"select b2.name,info.agegroup,ass.name,sum(info.num) from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by b2.name,info.agegroup,ass.name",
              'get_assessmentinfo_project':"select b1.name,info.agegroup,ass.name,sum(info.num) from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by b1.name,info.agegroup,ass.name",
              'get_assessmentinfo_circle':"select b.name,info.agegroup,ass.name,sum(info.num) from tb_preschool_basic_assessment_info info,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by b.name,info.agegroup,ass.name",
              'get_school_info':"select b.name, b1.name, b2.name, s.name,b.type,s.cat,s.sex,s.moi,s.mgmt,s.dise_code,s.status from tb_boundary b, tb_boundary b1, tb_boundary b2, tb_school s,tb_bhierarchy h where s.id = %s and b.id=b1.parent and b1.id=b2.parent and s.bid=b2.id and b.hid=h.id",
              'get_school_address_info':"select a.address,a.area,a.pincode,a.landmark,a.instidentification,a.instidentification2, a.bus from tb_address a,tb_school s where s.aid=a.id and s.id=%s",
              'get_sys_info':"select sys.dateofvisit,sys.comments,sys.id,initcap(sys.name),to_char(sys.entered_timestamp, 'yyyy-mm-dd HH24:MI:SS') from tb_sys_data sys where sys.schoolid=%s and sys.verified='Y'",
              'get_sys_images':"select distinct hash_file from tb_sys_images where sysid=%s and verified='Y'",
              'get_sys_qans':"select q.qtext,a.answer from tb_sys_questions q, tb_sys_qans a , tb_sys_data sd where a.qid = q.id and a.sysid= sd.id and sd.verified='Y' and a.sysid in %s",
              'get_school_point':"select ST_AsText(inst.coord) from vw_inst_coord inst where inst.instid=%s",
              'get_sys_nums':"select count(*) from tb_sys_data",
              'get_sys_image_nums':"select count(*) from tb_sys_images",
              'get_school_images':"select hash_file from tb_sys_images where schoolid=%s and verified='Y'",
              'get_pratham_assessment_questions':'select distinct eval.domain,q."desc", eval.value,q.id from tb_question q,tb_school s,vw_school_eval eval where eval.sid=s.id and eval.qid=q.id and s.id=%s order by q.id',
              'get_pratham_assessment_info':'select distinct p.name,partner.name,ay.name from tb_programme p,tb_academic_year ay,tb_partner partner where p.partnerid=partner.id and p.ayid=ay.id and p.id=%s',
              'get_school_mpmla':"select mla.const_ward_name, mp.const_ward_name,mla.current_elected_rep, mla.current_elected_party, mp.current_elected_rep, mp.current_elected_party, ward.const_ward_name,ward.current_elected_rep,ward.current_elected_party from vw_school_electedrep se, vw_electedrep_master mla, vw_electedrep_master mp, vw_electedrep_master ward where se.sid=%s and mla.id=se.mla_const_id and mp.id= se.mp_const_id and se.ward_id=ward.id;",
              'get_tlmgrant_sch':"select vpd.grant_type,vpd.grant_amount,vpd.grant_amount* sum(vdf.teacher_count) as total_grant,vdf.tlm_recd,vdf.tlm_expnd from vw_paisa_data vpd, tb_school s, vw_dise_info vdf where s.dise_code=vdf.dise_code and vpd.criteria='teacher_count' and s.id=%s group by  vpd.grant_type, vpd.grant_amount, vdf.tlm_recd,vdf.tlm_expnd;",
              'get_mtncgrant_sch':"select vpd2.grant_type, CASE WHEN mvdf.operator='gt' THEN 'With more than 3 classrooms ' ELSE 'With 3 classrooms or fewer ' END as classroom_count, vpd2.grant_amount as total_grant from (select vdf.dise_code as dise_code, CASE WHEN vdf.classroom_count <= CAST (vpd.factor AS INT) THEN 'lt' ELSE 'gt' END as operator from vw_paisa_data vpd, vw_dise_info vdf where vpd.criteria='classroom_count') AS mvdf, vw_paisa_data vpd2, tb_school s where s.dise_code = mvdf.dise_code and mvdf.operator = vpd2.operator and s.id=%s group by vpd2.grant_type, mvdf.operator, vpd2.grant_amount;",
              'get_annualgrant_sch':"select s.cat, vpd.grant_type, vpd.grant_amount as total_grant,vdf.sg_recd,vdf.sg_expnd from tb_school s, vw_paisa_data vpd, vw_dise_info vdf where vpd.criteria='school_cat' and vpd.factor = s.cat::text and s.id=%s and vdf.dise_code=s.dise_code group by s.cat,vpd.grant_type,vpd.grant_amount,vdf.sg_recd,vdf.sg_expnd ;",
              'get_dise_facility':"select distinct ddm.value, dfa.score,dfa.df_group from vw_dise_facility_agg dfa, tb_school s, vw_dise_display_master ddm where s.dise_code=dfa.dise_code and ddm.key=dfa.df_metric and s.id=%s;",
	      'get_dise_ptr':"select vdi.teacher_count,vdi.boys_count,vdi.girls_count,vdi.classroom_count,vdi.acyear,vdi.lowest_class,vdi.highest_class,vdi.books_in_library from vw_dise_info vdi,tb_school s where s.dise_code=vdi.dise_code and s.id=%s;",
	      'get_dise_stuinfo':"select vdi.boys_count,vdi.girls_count from vw_dise_info vdi,tb_school s where s.dise_code=vdi.dise_code and s.id=%s;",
              'get_dise_rte':"select distinct ddm.value, dra.status,dra.rte_group from vw_dise_rte_agg dra, tb_school s, vw_dise_display_master ddm where s.dise_code=dra.dise_code and ddm.key=dra.rte_metric and s.id=%s;",
              'get_ang_infra':"select distinct adm.value, aia.perc_score,aia.ai_group from vw_anginfra_agg aia, tb_school s, vw_ang_display_master adm where s.id=aia.sid and adm.key=aia.ai_metric and s.id=%s;",
              'get_lib_infra':"select libstatus,libtype,numbooks,numracks,numtables,numchairs,numcomputers,numups from tb_school s, vw_libinfra li where s.id=li.sid and s.id=%s;",
              'get_apmdm':"select mon,wk,indent,attend from vw_mdm_agg where id=%s;",
}
render = web.template.render('templates/', base='base')
render_plain = web.template.render('templates/')

application = web.application(urls,globals()).wsgifunc()


class mainmap:
  """Returns the main template"""
  def GET(self):
    web.header('Content-Type','text/html; charset=utf-8')
    return render.klp()

class getPointInfo:
  def GET(self):
    pointInfo={"district":[],"block":[],"cluster":[],"project":[],"circle":[],"preschooldistrict":[],"school":[],"preschool":[]}
    try:
      cursor = DbManager.getMainCon().cursor()
      for type in pointInfo:
        cursor.execute(statements['get_'+type])
        result = cursor.fetchall()
        for row in result:
          try:
            match = re.match(r"POINT\((.*)\s(.*)\)",row[1])
          except:
            traceback.print_exc(file=sys.stderr)
            continue
          lon = match.group(1)
          lat = match.group(2)
          data={"lon":lon,"lat":lat,"name":row[2],"id":row[0]}
          pointInfo[type].append(data)
        DbManager.getMainCon().commit()
      cursor.close()
    except:
      traceback.print_exc(file=sys.stderr)
      cursor.close()
      DbManager.getMainCon().rollback()
    web.header('Content-Type', 'application/json')
    return jsonpickle.encode(pointInfo)


class visualization:
  def GET(self):
    web.header('Content-Type','text/html; charset=utf-8')
    return render.visualization()



class getSYSInfo:
  def GET(self):
    sysinfo={"numstories":0,"numimages":0}
    try:
      syscursor = DbManager.getSysCon().cursor()
      syscursor.execute(statements['get_sys_nums'])
      result = syscursor.fetchall()
      for row in result:
        sysinfo["numstories"]=int(row[0])
      syscursor.execute(statements['get_sys_image_nums'])
      result = syscursor.fetchall()
      for row in result:
        sysinfo["numimages"]=int(row[0])
      syscursor.close()
      DbManager.getSysCon().commit()
    except:
      traceback.print_exc(file=sys.stderr)
      syscursor.close()
      DbManager.getSysCon().rollback()
    web.header('Content-Type', 'application/json')
    return jsonpickle.encode(sysinfo)

    

class assessments:
  def GET(self,type,pid,id):
    data={}
    try:
       stype=""
       if pid in preschoolPids:
         stype="preschool"
       if pid=='1001':
         assess=prathamData(id,pid)
         data=assess.getData()
       else:
         assess = assessmentData(type,pid,id,stype)
         data = assess.getData()
       DbManager.getMainCon().commit()
    except:
      traceback.print_exc(file=sys.stderr)
      DbManager.getMainCon().rollback()
    web.header('Content-Type','text/html; charset=utf-8')
    if pid=='1001':
      return render_plain.assessmenttable(data)
    return render_plain.chart(data)

class prathamData:
  def __init__(self,id,pid):
    print id
    print pid
    self.id=id
    self.pid=pid
    self.data= {"programme":{"pid":int(self.pid),"name":"","year":"","partner":""},"assessment":{}}
  def getData(self):
    print self.pid
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_pratham_assessment_info'],(self.pid,))
    result=cursor.fetchall()
    for row in result:
      self.data["programme"]["name"]=row[0]
      self.data["programme"]["partner"]=row[1]
      self.data["programme"]["year"]=row[2]
    cursor.execute(statements['get_pratham_assessment_questions'],(self.id,))
    result=cursor.fetchall()
    print result
    counter={}
    for row in result:
      if row[0] not in self.data["assessment"]:
        counter[row[0]]=0
        self.data["assessment"][row[0]]={0:{row[1]:row[2]}}
      else:
        counter[row[0]]=counter[row[0]]+1
        self.data["assessment"][row[0]][counter[row[0]]]={row[1]:row[2]}
    cursor.close()
    return self.data
    
    
    


class baseAssessment:
    def __init__(self,type,programmeid,id,stype):
      self.districtid=0
      self.blockid=0
      self.clusterid=0
      self.total={}
      self.count={}
      self.type = str(type)
      self.pid=programmeid
      self.id = id
      self.stype=stype
      self.data= {"programme":{"pid":int(self.pid),"name":"","year":"","partner":""},"type":self.type,"name":"","Boys":0,"Girls":0,"assessPerText":{},"baseline":{"gender":{},"mt":{},"class":{}},"progress":{},"analytics":{},"base":{}}

    def getProgramInfo(self):
      try:
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements['get_programme_info'],(self.pid,))
        result = cursor.fetchall()
        for row in result:
          self.data["programme"]["name"]=row[0]
          self.data["programme"]["year"]=str(row[1]).split("-")[0]
          self.data["programme"]["partner"]=row[2]
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getBasicAssessmentInfo(self):
      try:
        qtype=self.type
        query='get_basic_assessmentinfo_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          self.data["name"]=row[3].capitalize()
          if row[0] not in baseassess[self.pid]:
            continue
          classname=str(row[1]).strip()
          if classname not in self.data["base"]:
            self.data["base"][classname]={"Boys":0,"Girls":0}
          if row[2] == "female":
            gender="Girls"
          else:
            gender="Boys"
          if gender not in self.data["base"][classname]:
            self.data["base"][classname][gender]=int(row[4])
          else:
            self.data["base"][classname][gender]=self.data["base"][classname][gender]+int(row[4])

          if classname not in self.total:
            self.total[classname] = row[4]
          else:
            self.total[classname] =self.total[classname]+ row[4]

          if classname not in self.count:
            self.count[classname]={"Boys":0,"Girls":0}
          if gender not in self.count[classname]:
            self.count[classname][gender]=row[4]
          else:
            self.count[classname][gender]=self.count[classname][gender]+row[4]

          if qtype=='school' or qtype=='preschool':
            self.districtid=row[5]
            self.blockid=row[6]
            self.clusterid=row[7]


        for classname in self.data["base"]:
          for gender in self.data["base"][classname]:
            self.data[gender]=self.data[gender]+self.data["base"][classname][gender]
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getBaselineGeneral(self):
      try:
        qtype=self.type
        query='get_assessmentpertext_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          if row[0] not in baseassess[self.pid]:
            continue
          classname=str(row[1]).strip()
          if classname not in self.data["assessPerText"]:
             self.data["assessPerText"][classname]={}

          asstext=row[2]
          assval=row[3]
          if asstext not in self.data["assessPerText"][classname]:
            self.data["assessPerText"][classname][asstext]=assval
          else:
            self.data["assessPerText"][classname][asstext]=self.data["assessPerText"][classname][asstext]+assval

        for classname in  self.data["assessPerText"]:
          for asstext in self.data["assessPerText"][classname]:
               self.data["assessPerText"][classname][asstext]=round((float(self.data["assessPerText"][classname][asstext])/float(self.total[classname]))*100.0,2)
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getBaselineGender(self):
      try:
        qtype=self.type
        query='get_assessmentgender_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          if row[0] not in baseassess[self.pid]:
           continue
          classname=str(row[1]).strip()
          if row[2] =="female":
            gender="Girls"
          if row[2] =="male":
            gender="Boys"

          aggtext=row[3]
          aggval=row[4]
          if classname not in self.data["baseline"]["gender"]:
             self.data["baseline"]["gender"][classname]={}
          if gender not in self.data["baseline"]["gender"][classname]:
            self.data["baseline"]["gender"][classname][gender]={}
          if aggtext not in self.data["baseline"]["gender"][classname][gender]:
            self.data["baseline"]["gender"][classname][gender][aggtext]=aggval
          else:
              self.data["baseline"]["gender"][classname][gender][aggtext]=float(self.data["baseline"]["gender"][classname][gender][aggtext])+float(aggval)



        for classname in self.data["baseline"]["gender"]:
          for gender in self.data["baseline"]["gender"][classname]:
            for asstext in self.data["baseline"]["gender"][classname][gender]:
                self.data["baseline"]["gender"][classname][gender][asstext]=round((float(self.data["baseline"]["gender"][classname][gender][asstext])/float(self.count[classname][gender]))*100.0,2)
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getBaselineMTCount(self,type):
      try:
        type=self.type
        query='get_assessmentmt_count_'+type
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          if row[0] not in baseassess[self.pid]:
            continue
          classname=str(row[1]).strip()
          mt=row[2].capitalize()
          count=row[3]
          if classname not in self.count:
            self.count[classname]={}
          if mt not in self.count[classname]:
            self.count[classname][mt]=count
          else:
            self.count[classname][mt]=self.count[classname][mt]+count
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getBaselineMT(self,type=""):
      try:
        qtype=self.type
        self.getBaselineMTCount(qtype)
        query='get_assessmentmt_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          if row[0] not in baseassess[self.pid]:
            continue
          classname=str(row[1]).strip()
          mt=row[2].capitalize()
          aggtext=row[3]
          count=row[4]
          if classname not in self.data["baseline"]["mt"]:
            self.data["baseline"]["mt"][classname]={}
          if mt not in self.data["baseline"]["mt"][classname]:
            self.data["baseline"]["mt"][classname][mt]={}
          if aggtext not in self.data["baseline"]["mt"][classname][mt]:
            self.data["baseline"]["mt"][classname][mt][aggtext]=count
          else:
            self.data["baseline"]["mt"][classname][mt][aggtext]=self.data["baseline"]["mt"][classname][mt][aggtext]+count

        for classname in self.data["baseline"]["mt"]:
          for mt in self.data["baseline"]["mt"][classname]:
            for asstext in self.data["baseline"]["mt"][classname][mt]:
                self.data["baseline"]["mt"][classname][mt][asstext]=round((float(self.data["baseline"]["mt"][classname][mt][asstext])/float(self.count[classname][mt]))*100.0,2)
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getProgressCount(self,qtype):
      try:
        qtype=self.type
        query='get_progress_count_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          classname=str(row[1]).strip()
          assname=row[2]
          count=row[3]
          if classname not in self.count:
            self.count[classname]={}
          self.count[classname][assname]=count
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getProgressInfo(self,type=""):
      try:
        qtype=self.type
        self.getProgressCount(qtype)
        query='get_progress_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          classname=str(row[2]).strip()
          aggtext=row[3]
          assname=row[4]
          sum=row[5]
          starttime=str(row[6])

          if classname not in self.data["progress"]:
            self.data["progress"][classname]={}
          if starttime not in self.data["progress"][classname]:
            self.data["progress"][classname][starttime]={}
          if assname not in self.data["progress"][classname][starttime]:
            self.data["progress"][classname][starttime][assname]={}
          if aggtext not in self.data["progress"][classname][starttime][assname]:
            self.data["progress"][classname][starttime][assname][aggtext]=sum
          else:
            self.data["progress"][classname][starttime][assname][aggtext]=self.data["progress"][classname][starttime][assname][aggtext]+sum


        for classname in self.data["progress"]:
          for starttime in self.data["progress"][classname]:
            for assname in self.data["progress"][classname][starttime]:
              for aggtext in self.data["progress"][classname][starttime][assname]:
                  self.data["progress"][classname][starttime][assname][aggtext]=round((float(self.data["progress"][classname][starttime][assname][aggtext])/float(self.count[classname][assname]))*100.0,2)
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getAnalyticsInfo(self):
      name=self.data["name"].capitalize()+" (School)"
      try:
        qtype=self.type
        query='get_progress_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          sname=row[1].capitalize()
          classname=str(row[2]).strip()
          aggtext=row[3]
          assname=row[4]
          aggsum=row[5]
          starttime=str(row[6])

          if classname not in self.data["analytics"]:
            self.data["analytics"][classname]={}
          if starttime not in self.data["analytics"][classname]:
            self.data["analytics"][classname][starttime]={}
          if assname not in self.data["analytics"][classname][starttime]:
            self.data["analytics"][classname][starttime][assname]={}
          if "School" not in self.data["analytics"][classname][starttime][assname]:
            self.data["analytics"][classname][starttime][assname]["School"]={"name":sname}
          if aggtext not in self.data["analytics"][classname][starttime][assname]["School"]:
            self.data["analytics"][classname][starttime][assname]["School"][aggtext]=aggsum
          else:
            self.data["analytics"][classname][starttime][assname]["School"][aggtext]=self.data["analytics"][classname][starttime][assname]["School"][aggtext]+float(aggsum)


        for classname in self.data["analytics"]:
          for starttime in self.data["analytics"][classname]:
            for assname in self.data["analytics"][classname][starttime]:
              for aggtext in self.data["analytics"][classname][starttime][assname]["School"]:
                if aggtext=="name":
                  continue
                self.data["analytics"][classname][starttime][assname]["School"][aggtext]=round((float(self.data["analytics"][classname][starttime][assname]["School"][aggtext])/float(self.count[classname][assname]))*100.0,2)
 

        schoolboundaries={"district":self.districtid,"block":self.blockid,"cluster":self.clusterid}
        preschoolboundaries={"preschooldistrict":self.districtid,"project":self.blockid,"circle":self.clusterid}

        boundaries=schoolboundaries
        if self.type=="preschool":
          boundaries=preschoolboundaries

        for boundary in boundaries:
          boundarytotal={}
          btype=boundary
          query='get_assessmentinfo_'+btype
          cursor.execute(statements[query],(self.pid,boundaries[boundary],))
          result = cursor.fetchall()
          bname=""
          for row in result:
            classname=str(row[1]).strip()
            assname=row[2]
            classsum=row[3]
            if classname not in boundarytotal:
              boundarytotal[classname]={}
            boundarytotal[classname][assname]=classsum


        for boundary in boundaries:
          btype=boundary
          query='get_progress_'+btype
          cursor.execute(statements[query],(self.pid,boundaries[boundary],))
          result = cursor.fetchall()
          for row in result:
            boundary=boundary.capitalize()
            bname=row[1].capitalize()
            classname=str(row[2]).strip()
            aggtext=row[3]
            assname=row[4]
            aggsum=row[5]
            starttime=str(row[6])
            if classname not in self.data["analytics"]:
              continue
            if starttime not in self.data["analytics"][classname]:
              continue
            if assname not in self.data["analytics"][classname][starttime]:
              continue
            if boundary not in self.data["analytics"][classname][starttime][assname]:
              self.data["analytics"][classname][starttime][assname][boundary]={"name":bname}
            if aggtext not in self.data["analytics"][classname][starttime][assname][boundary]:
              if aggsum==0:
                self.data["analytics"][classname][starttime][assname][boundary][aggtext]=round(float(aggsum),2)
              else:
                self.data["analytics"][classname][starttime][assname][boundary][aggtext]=round((float(aggsum)/float(boundarytotal[classname][assname]))*100,2)

        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

class assessmentData(baseAssessment):
    def getBaselineAssessmentInfo(self):
      self.getBaselineGeneral()
      self.getBaselineGender()
      self.getBaselineMT()

    def getData(self):
      self.getProgramInfo()
      self.getBasicAssessmentInfo()
      self.getBaselineAssessmentInfo()
      self.getProgressInfo()
      if self.type =="school" or self.type=="preschool":
        self.getAnalyticsInfo()
      DbManager.getMainCon().commit()
      return self.data

class CommonSchoolUtil:
  
  @staticmethod
  def getSchoolInfo(id):
    data = {}
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_school_info'],(id,))
    result = cursor.fetchall()
    for row in result:
      data["b"]=row[0].capitalize()
      data["b1"]=row[1].capitalize()
      data["b2"]=row[2].capitalize()
      data["name"]=row[3].capitalize()
      data["type"]=CommonSchoolUtil.checkEmpty(row[4],'-')
      data["cat"]=CommonSchoolUtil.checkEmpty(row[5],'-')
      data["sex"]=CommonSchoolUtil.checkEmpty(row[6],'-')
      data["moi"]=CommonSchoolUtil.checkEmpty(row[7],'Kannada')
      data["mgmt"]=CommonSchoolUtil.checkEmpty(row[8],'-')
      data["dise_code"]=CommonSchoolUtil.checkEmpty(row[9],'-')
      data["status"]=row[10]
    DbManager.getMainCon().commit()
    cursor.close()
    return data;
 
  @staticmethod 
  def checkEmpty(data,rpldata):
    if data == None:
      return rpldata
    else:
      return str(data).capitalize()

class SchoolPage:
  
  def GET(self,type,id):
    data={'name':'','type':'','id':'','sysdate':[],'tab':''}
    data["type"]=str(type)
    data["id"]=int(id)
    i = web.input()
    is_ajax = "false"
    if 'is_ajax' in i.keys():
      is_ajax = web.input()['is_ajax']
    tab = 'basics' 
    if 'tab' in i.keys():
      tab = web.input()['tab']
    data["tab"] = tab
    #print type + '|' + str(id) + '|' + str(tab)
    try: 
      data.update(CommonSchoolUtil.getSchoolInfo(id))
      if tab == 'basics':
        data.update(self.getBasicData(id))
        data.update(self.getSYSImages(id))
      elif tab == 'demographics':
      	data.update(self.getDemographicData(id))
      elif tab == 'programmes':
        data.update(self.getProgrammeData(id,type))  
      elif tab == 'finances':
        if type=='school':
          data.update(self.getFinData(id))
      elif tab == 'infrastructure':
        if type=='school':
          data.update(self.getDiseData(id))
          data.update(self.getLibraryData(id))
        if type=='preschool':
          data.update(self.getAngInfraData(id))
      elif tab == 'nutrition':
        if type=='school':
          data.update(self.getMidDayMealData(id))
      elif tab == 'stories' :
        data.update(self.getSYSData(id))
      else:
        data.update(self.getBasicData(id))
        data.update(self.getSYSImages(id))
      if is_ajax == "true":
        web.header('Content-Type', 'application/json; charset=utf-8')
        return jsonpickle.encode(data)
      else:
        web.header('Content-Type','text/html; charset=utf-8')
        return render_plain.schoolpage(jsonpickle.encode(data))
    except:
      traceback.print_exc(file=sys.stderr)
      DbManager.getMainCon().rollback()
      DbManager.getSysCon().rollback()

  def getBasicData(self,id):
    data = {}
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_school_address_info'],(id,))
    result = cursor.fetchall()
    data["address"]='-'
    for row in result:
      data["address"]=CommonSchoolUtil.checkEmpty(row[0],'-')
      data["area"]=CommonSchoolUtil.checkEmpty(row[1],'-')
      data["postcode"]=CommonSchoolUtil.checkEmpty(row[2],'-')
      data["landmark_1"]=CommonSchoolUtil.checkEmpty(row[3],'-')
      data["inst_id_1"]=CommonSchoolUtil.checkEmpty(row[4],'-')
      data["inst_id_2"]=CommonSchoolUtil.checkEmpty(row[5],'-')
      data["bus_no"]=CommonSchoolUtil.checkEmpty(row[6],'-')
    DbManager.getMainCon().commit()

    cursor.execute(statements['get_school_mpmla'],(id,))
    result = cursor.fetchall()
    for row in result:
      data["mla"] = CommonSchoolUtil.checkEmpty(row[0],'Not available')
      data["mp"] = CommonSchoolUtil.checkEmpty(row[1],'Not available')
      data["ward"] = CommonSchoolUtil.checkEmpty(row[6],'Not available')
      data["mlaname"] = CommonSchoolUtil.checkEmpty(row[2]+' ('+row[3]+')','Not available')
      data["mpname"] = CommonSchoolUtil.checkEmpty(row[4]+' ('+row[5]+')','Not available')
      data["wardname"] = CommonSchoolUtil.checkEmpty(row[7]+' ('+row[8]+')','Not available')
    DbManager.getMainCon().commit()
      
    cursor.execute(statements['get_school_point'],(id,))
    result = cursor.fetchall()
    for row in result:
      match = re.match(r"POINT\((.*)\s(.*)\)",row[0])
      data["lon"] = match.group(1)
      data["lat"] = match.group(2)
    cursor.close()
    DbManager.getMainCon().commit()
    return data
  
  def getSYSImages(self,id):
    data = {}
    #Added to query images from tb_sys_images
    imgpath = ConfigReader.getConfigValue('Pictures','htmlpicpath')
    data["image_dir"] = "/" + imgpath
    syscursor = DbManager.getSysCon().cursor()
    syscursor.execute(statements['get_school_images'],(id,))
    result = syscursor.fetchall()
    data["images"]=[]
    for row in result:
      data["images"].append(row[0])
    DbManager.getSysCon().commit()
    syscursor.close()
    return data
 
  def getDemographicData(self,id):
    data = {}
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_school_gender'],(id,))
    result = cursor.fetchall()
    for row in result:
      if row[1] == "female":
        data["numGirls"]=int(row[2])
      if row[1] == "male":
        data["numBoys"]=int(row[2])
    if "numGirls" not in data.keys():
      data["numGirls"] = 0
    if "numBoys" not in data.keys():
      data["numBoys"] = 0
    data["numStudents"]= data["numBoys"]+data["numGirls"]
    DbManager.getMainCon().commit()

    cursor.execute(statements['get_school_mt'],(id,))
    result = cursor.fetchall()
    tabledata = {}
    invertdata = {}
    order_lst = []
    for row in result:
      invertdata[int(row[2])] = str(row[1].strip().title())
    if len(invertdata.keys()) > 0:
      checklist = sorted(invertdata)
      others = 0
      for i in checklist[0:len(checklist)-4]:
        others = others + i
        del invertdata[i]
      invertdata[others] = 'Others'
      tabledata = dict(zip(invertdata.values(),invertdata.keys()))
      if 'Other' in tabledata.keys():
        tabledata['Others'] = tabledata['Others'] + tabledata['Other']
        del tabledata['Other']
    for i in sorted(tabledata,key=tabledata.get,reverse=True):
      order_lst.append(i)
    if len(tabledata.keys()) > 0:
      data["school_mt_tb"] = tabledata
      data["school_mt_ord"] = order_lst
    cursor.close()
    DbManager.getMainCon().commit()
    
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_dise_stuinfo'],(id,))
    result = cursor.fetchall()
    for row in result:
      data['boys_count'] = str(row[0])
      data['girls_count'] = str(row[1])
      data['student_count'] = str(int(row[1]) + int(row[0]))
    DbManager.getMainCon().commit()
    return data
 
  def getMidDayMealData(self,klpid):
    tabledata = {}
    try:
      cursor = DbManager.getMainCon().cursor()
      cursor.execute(statements['get_apmdm'],(klpid,))
      result = cursor.fetchall()
      for row in result:
        if row[0] in tabledata:
	  tabledata[row[0]][row[1]]=[row[2],row[3]]
        else:
          tabledata[row[0]]={row[1]:[row[2],row[3]]}
      DbManager.getMainCon().commit()
      cursor.close()
      return {'ap_mdm':tabledata};
    except:
      DbManager.getMainCon().rollback()
      cursor.close()
      traceback.print_exc(file=sys.stderr)
      return tabledata;  

  def getLibraryData(self, klpid):
    tabledata = {}
    try:
      cursor = DbManager.getMainCon().cursor()
      cursor.execute(statements['get_lib_infra'],(klpid,))
      result = cursor.fetchall()
      for row in result:
        tabledata['Status of the Library'] = CommonSchoolUtil.checkEmpty(row[0],'-')
        tabledata['Type in Hub-Spoke model'] = CommonSchoolUtil.checkEmpty(row[1],'-')
        tabledata['Number of Books'] = CommonSchoolUtil.checkEmpty(row[2],'-')
        tabledata['Number of Racks'] = CommonSchoolUtil.checkEmpty(row[3],'-')
        tabledata['Number of Tables'] = CommonSchoolUtil.checkEmpty(row[4],'-')
        tabledata['Number of Chairs'] = CommonSchoolUtil.checkEmpty(row[5],'-')
        tabledata['Number of Computers'] = CommonSchoolUtil.checkEmpty(row[6],'-')
        tabledata['Number of UPS(s)'] = CommonSchoolUtil.checkEmpty(row[7],'-')
      DbManager.getMainCon().commit()
      cursor.close()
      return {'lib_infra':tabledata};
    except:
      DbManager.getMainCon().rollback()
      cursor.close()
      traceback.print_exc(file=sys.stderr)
      return tabledata;  

  def getDiseData(self, klpid):
    tabledata = {}
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_dise_ptr'],(klpid,))
    result = cursor.fetchall()
    for row in result:
      tabledata['teacher_count'] = str(row[0])
      tabledata['boys_count'] = str(row[1])
      tabledata['girls_count'] = str(row[2])
      tabledata['student_count'] = str(int(row[1]) + int(row[2]))
      tabledata['classroom_count'] = str(row[3])
      tabledata['acyear'] = str(row[4])
      tabledata['lowest_class'] = str(row[5])
      tabledata['highest_class'] = str(row[6])
      tabledata['dise_books'] = str(row[7])
    DbManager.getMainCon().commit()
    cursor.execute(statements['get_dise_facility'],(klpid,))
    result = cursor.fetchall()
    facilities = {}
    for row in result:
      if row[2] in facilities:
        facilities[row[2]][row[0]]=int(str(row[1]))
      else:
        facilities[row[2]]={row[0]:int(str(row[1]))}
    tabledata['dise_facility'] = facilities
    DbManager.getMainCon().commit()
    cursor.execute(statements['get_dise_rte'],(klpid,))
    result = cursor.fetchall()
    rte = {}
    for row in result:
      if row[2] in rte:
        rte[row[2]][row[0]]=str(row[1])
      else:
        rte[row[2]]={row[0]:str(row[1])}
    tabledata['dise_rte'] = rte 
    DbManager.getMainCon().commit()
    cursor.close()
    return tabledata;

  def getAngInfraData(self, klpid):
    tabledata = {}
    try:
      cursor = DbManager.getMainCon().cursor()
      cursor.execute(statements['get_ang_infra'],(klpid,))
      result = cursor.fetchall()
      facilities = {}
      for row in result:
        if row[2] in facilities:
	  facilities[row[2]][row[0]]=int(str(row[1]))
        else:
          facilities[row[2]]={row[0]:int(str(row[1]))}
      tabledata['ang_infra'] = facilities
      DbManager.getMainCon().commit()
      cursor.close()
      return tabledata;
    except:
      DbManager.getMainCon().rollback()
      cursor.close()
      traceback.print_exc(file=sys.stderr)
      return tabledata;  

  def getFinData(self, klpid):
    tabledata = {}
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_tlmgrant_sch'],(klpid,))
    result = cursor.fetchall()
    for row in result:
      tabledata['tlm_amount'] = str(row[2])
      tabledata['tlm_recd'] = str(row[3])
      tabledata['tlm_expnd'] = str(row[4])
      tabledata['teacher_count'] = str(int(row[2])/int(row[1]))
    DbManager.getMainCon().commit()
    cursor.execute(statements['get_mtncgrant_sch'],(klpid,))
    result = cursor.fetchall()
    for row in result:
      tabledata['smg_amount'] = str(row[2])
      tabledata['classroom_count'] = str(row[1])
    DbManager.getMainCon().commit()
    cursor.execute(statements['get_annualgrant_sch'],(klpid,))
    result = cursor.fetchall()
    for row in result:
      tabledata['sg_amount'] = str(row[2])
      tabledata['sg_recd'] = str(row[3])
      tabledata['sg_expnd'] = str(row[4])
    DbManager.getMainCon().commit()
    #tabledata['dise_fin'] = tabledata
    cursor.close()
    return tabledata;
    
  def getProgrammeData(self,id,type):
    data = {}
    query='get_assessmentinfo_'+type
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements[query],(id,))
    result = cursor.fetchall()
    assessments= ""
    first=1
    for row in result:
      if first:
        assessments=assessments+row[0]+"|"+str(row[1]).split("-")[0]+"|"+str(row[2])+"|"+str(row[3])
        first=0
      else:
        assessments=assessments+","+row[0]+"|"+str(row[1]).split("-")[0]+"|"+str(row[2])+"|"+str(row[3])
    data["assessments"]=assessments
    cursor.close()
    DbManager.getMainCon().commit()
    return data
      
  def getSYSData(self,id):
    data = {}
    syscursor = DbManager.getSysCon().cursor()
    syscursor.execute(statements['get_sys_info'],(id,))
    result = syscursor.fetchall()
    sysdates =  []
    syscomments = {}
    sysids = []
    data["syscount"]=0
    count=0
    for row in result:
      if row[0] != None:
        if row[0].strip().replace('/','-') not in sysdates:
          sysdates.append(row[0].strip().replace('/','-'))
        data["syscount"]=data["syscount"]+1
      if row[1] != None:
        syscomments[count]={"name":row[3],"timestamp":row[4],"comments":row[1],"images":[],"id":row[2]}
        syscursor.execute(statements['get_sys_images'],(row[2],))
        imgresult = syscursor.fetchall()
        for img in imgresult:
          syscomments[count]["images"].append(img[0]) 
      sysids.append(row[2])
      count=count+1
    data["sysdate"] = sysdates
    data["syscomment"] = syscomments
    DbManager.getSysCon().commit()

    sysdata = {}
    if count>0:
      syscursor.execute(statements['get_sys_qans'],[tuple(sysids)])
      result = syscursor.fetchall()
      pos_ans = ["yes","available and functional","available but not functional"]
      for row in result:
        if row[0] in sysdata.keys():
          if row[1].lower() not in pos_ans:
            sysdata[row[0]] = "No or Not known"
        else:
          if row[1].lower() in pos_ans:
            sysdata[row[0]] = "Yes" 
          else:
            sysdata[row[0]] = "No or Not known"
      if len(sysdata.keys()) > 0:
        data["sysdata"] = []
        for (k,v) in sysdata.items():
          data["sysdata"].append(k +'|'+v);
    DbManager.getSysCon().commit()
    syscursor.close()
    return data


class shareyourstory:
  def GET(self,type):
    questions=[]
    try:
      syscursor = DbManager.getSysCon().cursor()
      syscursor.execute(statements['get_sys_'+type+'_questions'])
      result = syscursor.fetchall()
      for row in result:
        questions.append({"id":row[0],"text":row[2],"field":row[3],"type":row[4],"options":row[5]})
      syscursor.close()
      DbManager.getSysCon().commit()
    except:
      syscursor.close()
      DbManager.getSysCon().rollback()
      traceback.print_exc(file=sys.stderr)
    web.header('Content-Type','text/html; charset=utf-8')
    return render_plain.shareyourstory(questions)

class text:
  def GET(self, name):
    web.header('Content-Type','text/html; charset=utf-8')
    textlinks = {'library': 'library', 'maths': 'maths', 'preschool': 'preschool', 'reading': 'reading', 'partners': 'partners','aboutus':'aboutus','credits':'credits', 'reports':'reports'}

    try:
      return eval('render.' + textlinks[name] + '()')
    except KeyError:
      return web.badrequest()

class getBoundaryInfo:
  def GET(self,type,id):
    boundaryInfo ={}
    boundaryInfo["id"]=id
    boundaryInfo["numBoys"]=0
    boundaryInfo["numGirls"]=0
    boundaryInfo["numSchools"]=0
    boundaryInfo["assessments"]=""

    try:
      cursor = DbManager.getMainCon().cursor()
      cursor.execute(statements['get_'+type+'_assessmentinfo'],(id,))
      result = cursor.fetchall()
      assessments= ""
      first=1
      for row in result:
        if first:
          assessments=assessments+row[0]+"|"+str(row[1]).split("-")[0]+"|"+str(row[2])+"|"+str(row[3])
          first=0
        else:
          assessments=assessments+","+row[0]+"|"+str(row[1]).split("-")[0]+"|"+str(row[2])+"|"+str(row[3])
      boundaryInfo["assessments"]=str(assessments)

      cursor.execute(statements['get_'+type+'_info'],(id,))
      result = cursor.fetchall()
      for row in result:
        boundaryInfo["numSchools"]=str(row[0])
        boundaryInfo["name"]=str(row[1])
   
      cursor.execute(statements['get_'+type+'_gender'],(id,))
      result = cursor.fetchall()
      for row in result:
        if row[0] == "female":
          boundaryInfo["numGirls"]=row[1]
        if row[0] == "male":
          boundaryInfo["numBoys"]=row[1]
      boundaryInfo["numStudents"]= boundaryInfo["numBoys"]+boundaryInfo["numGirls"]
      cursor.close()
      DbManager.getMainCon().commit()
    except:
      traceback.print_exc(file=sys.stderr)
      cursor.close()
      DbManager.getMainCon().rollback()
    web.header('Content-Type', 'application/json')
    return jsonpickle.encode(boundaryInfo)

class getSchoolInfo:
  def GET(self,id):
    schoolInfo={}
    schoolInfo["id"]=id
    schoolInfo["numStories"]=0
    schoolInfo["numBoys"]=0
    schoolInfo["numGirls"]=0
    schoolInfo["numStudents"]=0
    encodedschoolInfo=""


    try:
      cursor = DbManager.getMainCon().cursor()
      cursor.execute(statements['get_school_gender'],(id,))
      result = cursor.fetchall()
      for row in result:
        schoolInfo["name"]=row[0]
        if row[1] == "female":
          schoolInfo["numGirls"]=row[2]
        if row[1] == "male":
          schoolInfo["numBoys"]=row[2]

      schoolInfo["numStudents"]= schoolInfo["numBoys"]+schoolInfo["numGirls"]
      cursor.close()
      DbManager.getMainCon().commit()
    except:
      traceback.print_exc(file=sys.stderr)
      cursor.close()
      DbManager.getMainCon().rollback()
    
    try:
      syscursor = DbManager.getSysCon().cursor()
      syscursor.execute(statements['get_num_stories'],(id,))
      result = syscursor.fetchall()
      for row in result:
        schoolInfo["numStories"]=row[0]
      syscursor.close()
      DbManager.getSysCon().commit()
    except:
      traceback.print_exc(file=sys.stderr)
      syscursor.close()
      DbManager.getSysCon().rollback()
    web.header('Content-Type', 'application/json; charset=utf-8')
    return jsonpickle.encode(schoolInfo)


class getBoundaryPoints: 
  def GET(self,type,id):
    boundaryInfo =[]
    try:
      cursor = DbManager.getMainCon().cursor()
      cursor.execute(statements['get_'+type+'_points'],(id,))
      result = cursor.fetchall()
      for row in result:
        data={"id":row[0],"name":row[1].capitalize()}
        boundaryInfo.append(data)
      cursor.close()
      DbManager.getMainCon().commit()
    except:
      traceback.print_exc(file=sys.stderr)
      cursor.close()
      DbManager.getMainCon().rollback()
    web.header('Content-Type', 'application/json')
    return jsonpickle.encode(boundaryInfo)
 
class getSchoolBoundaryInfo:
  def GET(self,id):
    schoolInfo = {"district":"","block":"","cluster":"","schoolname":"","type":""}
    try:
      cursor = DbManager.getMainCon().cursor()
      cursor.execute(statements['get_school_boundary_info'],(id,))
      result = cursor.fetchall()
      for row in result:
        schoolInfo ={"district":row[0].capitalize(),"block":row[1].capitalize(),"cluster":row[2].capitalize(),"schoolname":row[3].capitalize(),"type":row[4]}
      cursor.close()
      DbManager.getMainCon().commit()
    except:
      traceback.print_exc(file=sys.stderr)
      cursor.close()
      DbManager.getMainCon().rollback()
    web.header('Content-Type', 'application/json')
    return jsonpickle.encode(schoolInfo)

class insertSYS:
  def GET(self,query):
    try:
      syscursor = DbManager.getSysCon().cursor()
      syscursor.execute(query)
      syscursor.close()
      DbManager.getSysCon().commit()
    except:
      traceback.print_exc(file=sys.stderr)
      syscursor.close()
      DbManager.getSysCon().rollback()

class ConfigReader:

  @staticmethod
  def getConfigValue(section,key):
    from ConfigParser import SafeConfigParser
    try:
      config = SafeConfigParser()
      config_fp = open(os.path.join(os.getcwd(),'config/klpconfig.ini'),'r')
      config.readfp(config_fp)
      value = config.get(section,key)
      config_fp.close()
      return value 
    except:
      print "Unexpected error:", sys.exc_info()
      print "Exception in user code:"
      print '-'*60
      traceback.print_exc(file=sys.stdout)
      print '-'*60

class postSYS:
 
  def getQuestionDict(self):
    qidsdict = {}
    try:
      syscursor = DbManager.getSysCon().cursor()
      syscursor.execute(statements['get_sys_qids'])
      result = syscursor.fetchall()
      for row in result:
        qidsdict[row[1]] = row[0]
      syscursor.close()
      DbManager.getSysCon().commit()
      return qidsdict
    except:
      traceback.print_exc(file=sys.stderr)
      syscursor.close()
      DbManager.getSysCon().rollback()
      return None

  def sendMail(self, recipient, sub, body,file = None):
    #if ccrecipient!='':
    cc = ['feedback@klp.org.in']
    to = [recipient]
    subject = sub
    sender = ConfigReader.getConfigValue('Mail','senderid')
    senderpwd = ConfigReader.getConfigValue('Mail','senderpwd')
    smtpport = ConfigReader.getConfigValue('Mail','smtpport') 
    smtpserver = ConfigReader.getConfigValue('Mail','smtpserver')

    # create html email
    html = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" '
    html +='"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml">'
    html +='<body style="font-size:14px;font-family:Verdana"><p>' + body + '</p>'
    html += "</body></html>"
 
    emailMsg = email.MIMEMultipart.MIMEMultipart('alternative')
    emailMsg['Subject'] = subject
    emailMsg['From'] = sender
    emailMsg['To'] = ', '.join(to)
    emailMsg['Cc'] = ", ".join(cc)
    emailMsg.attach(email.mime.text.MIMEText(html,'html'))
      
    if file != None: 
      ctype, encoding = mimetypes.guess_type(file)

      if ctype is None or encoding is not None:
        ctype = 'application/octet-stream'
        maintype, subtype = ctype.split('/', 1)
        fp = open(file)
        fileMsg = email.mime.text.MIMEText(fp.read(), _subtype=subtype)
        fp.close()
        email.encoders.encode_base64(fileMsg)
        fileMsg.add_header('Content-Disposition','attachment;filename='+file.lstrip(filedir))
        emailMsg.attach(fileMsg)

    server = smtplib.SMTP(smtpserver,smtpport)
    server.ehlo()
    server.starttls()
    server.ehlo
    server.login(sender,senderpwd)
    server.sendmail(sender,to+cc,emailMsg.as_string())
    server.close()

  def populateImages(self,selectedfile,schoolid,sysid):
      #Getting path to picture files from the config file
      import hashlib
      savepath = ConfigReader.getConfigValue('Pictures','origpicpath')
      hashed_filename = ''
      if selectedfile.filename != "":
        ext = selectedfile.filename.rpartition('.')[2]
        try:
          if(os.path.exists(savepath+selectedfile.filename)):
            savefilename = selectedfile.filename.split('.')[0] + '-' + schoolid + '.' + ext 
          else:
            savefilename = selectedfile.filename
          wf=open(savepath + savefilename,'w')
          wf.write(selectedfile.file.read())
          wf.close()
          hashed_filename = hashlib.md5(open(savepath +savefilename,'r').read()).hexdigest() + '.'+ ext
          import shutil
          shutil.move(savepath + savefilename,savepath + hashed_filename)
        except IOError:
          traceback.print_exc(file=sys.stderr)
        imagequery = "insert into tb_sys_images(schoolid,original_file,hash_file,sysid,verified) values( %s , %s, %s, %s, %s)"
        try:
          syscursor = DbManager.getSysCon().cursor()
          syscursor.execute(imagequery,(schoolid,savefilename,hashed_filename,sysid,'N')) #Images coming in from this flow are yet to be verified
          syscursor.close()
          DbManager.getSysCon().commit()
        except:
          traceback.print_exc(file=sys.stderr)
          syscursor.close()
          DbManager.getSysCon().rollback()

  def POST(self,type):
    success = True
    recipient = None
    try:
      syscursor = DbManager.getSysCon().cursor()
      schoolid=0
      if type=="school":
        form = mySchoolform()
        #print >> sys.stderr, "Type is school"
      else:
        form = myPreSchoolform()
        #print >> sys.stderr, "Type is preschool :"+type
      if not form.validates(): 
         for k in form.inputs: 
           return "id = ", k.id
      count=0
      sysid = None
      query="insert into tb_sys_data"
      qansquery = "insert into tb_sys_qans(sysid,qid,answer) values( %(sysid)s,%(qid)s,%(answer)s)"
      data={}
      qdata={}
      qarray=[]
      qiddict = self.getQuestionDict()
      for k in form.inputs: 
        if not(k.id.startswith('file')) and k.value != '' and k.value != None:
          if k.id in ('schoolid','name','email','telephone','dateofvisit','comments'):
            data[k.id] = k.value.strip('\n\r\t')
            if k.id == 'email':
              recipient = k.value 
          else:
            if k.id == 'chkboxes':
              qarray = k.value.split(',')
              for q in qarray:
                iparr = q.split('|')
                qdata[qiddict[iparr[0]]]=iparr[1]
              print >> sys.stderr, str(qdata)

      if 'comments' in data.keys() and len(data['comments']) > 0:
        data['verified'] = 'N'
      else:
        data['verified'] = 'Y'

      fields = ', '.join(data.keys())
      values = ', '.join(['%%(%s)s' % x for x in data])
      query=query+"("+fields+") values("+values+")"
      #print >> sys.stderr, str(query)
      #print >> sys.stderr, "Questions:-"+str(qdata)
      #return query+" Data:"+str(data)
      syscursor.execute("BEGIN")
      syscursor.execute("LOCK TABLE tb_sys_data IN ROW EXCLUSIVE MODE");
      syscursor.execute(query,data)
      syscursor.execute("select currval('tb_sys_data_id_seq')")
      result = syscursor.fetchall()
      syscursor.execute("COMMIT")
      for row in result:
        sysid=row[0]
      for q in qdata.keys():
        syscursor.execute(qansquery,{'sysid':sysid,'qid':q,'answer':qdata[q]})
      syscursor.close()    
      DbManager.getSysCon().commit()
    except:
      print >> sys.stderr, str(query)
      print >> sys.stderr, "Questions:-"+str(qdata)
      print >> sys.stderr, "Other:-"+str(data)
      traceback.print_exc(file=sys.stderr)
      syscursor.close() 
      DbManager.getSysCon().rollback()
      success = False
    #add photos
    try:
      schoolid= form['schoolid'].value
      x = web.input(file1={})
      self.populateImages(x.file1,schoolid,sysid)
      x = web.input(file2={})
      self.populateImages(x.file2,schoolid,sysid)
      x = web.input(file3={})
      self.populateImages(x.file3,schoolid,sysid)
      x = web.input(file4={})
      self.populateImages(x.file4,schoolid,sysid)
      x = web.input(file5={})
      self.populateImages(x.file5,schoolid,sysid)
    except:
      traceback.print_exc(file=sys.stderr)
      syscursor.close() 
      DbManager.getSysCon().rollback()
      success = False
 
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_school_info'],(schoolid,))
    result = cursor.fetchall()
    for row in result:
      dist=row[0].capitalize()
      blk=row[1].capitalize()
      clust=row[2].capitalize()
      sname=row[3].upper()
    cursor.close()
    DbManager.getMainCon().commit()
    if success:
      body = "Thank you for taking the time and sharing your experience when visiting " + sname 
      body = body + " in " + blk + ", " + clust + ". Your inputs have been successfully recorded."
      body = body + "<br/><br/> For future reference, information on the school you visited can be found here:" 
      if type == 'school':
        body = body + web.ctx.env['HTTP_HOST'] + "/schoolpage/school/" + str(schoolid) 
      else:
        body = body + web.ctx.env['HTTP_HOST'] + "/schoolpage/preschool/" + str(schoolid) 
      body = body + "<br/><br/>It will take a little while for your comments and inputs to show up as they need to be approved by a moderator. We appreciate your continued help in ensuring that every child is in school and learning well. Thank you and please spread the word! <br/>~ Team KLP<br/><br/> PS: You can reply to this email and we will respond soonest!"
      sub = "Your story on " + sname + " has been saved."
    else:
      body = "Thank you for taking the time and sharing your experience.<br/>However, there was an error because "
      body = body + "of which your form did not get saved. It would be of great help if you could send the information to us by email. Our email address is: dev@klp.org.in "
      body = body + ". Thanks again."
      sub = "Error while sharing your story on " + sname + " (" + str(schoolid) + ")."
    if recipient != None:
      self.sendMail(recipient, sub, body)
      #pass

    web.header('Content-Type','text/html; charset=utf-8')
    return render_plain.sys_submitted()
   
class listFiles:
  def GET(self,type):
    fileList = {}
    if len(type) > 1:
      reqp = type.split('|')
      type = reqp[0]
      mp = reqp[1]
      mla = reqp[2]
    path = ""
    if (int(type) == 1 or int(type) == 3):
      mpfilenames = []
      mlafilenames = []
      path = "/reports"
      fileList["reptype"] = ["demographics","finances","infrastructure"]
      fileList["subdir1"] = "/Kannada"
      fileList["subdir2"] = "/English"
      fileList["directory"] = path
      try:
        dirList=os.listdir(os.getcwd() + path + "/demographics/English")
        if int(type) == 3:
          ucList = {}
          for fn in dirList:
            ucList[fn.upper()] = fn
          
          fname = difflib.get_close_matches('mp_' + mp.replace(' ','_').upper(), ucList.keys())
          mpfilenames.append(ucList[fname[0]])
          fname = difflib.get_close_matches('mla_' + mla.replace(' ','_').upper(), ucList.keys())
          mlafilenames.append(ucList[fname[0]])
          fileList["listtype"] = '3'
        else:
          for fname in dirList:
            if '.zip' in fname:
              pass
            else:
              if 'MP_' in fname:
                mpfilenames.append(fname)
              else:
                mlafilenames.append(fname)
          fileList["listtype"] = '1'
        fileList["mpnames"] = mpfilenames
        fileList["mlanames"] = mlafilenames
      except:
        traceback.print_exc(file=sys.stderr)
    if (int(type) == 2):
      path = "/rawdata"
      rawfilenames =[]
      try:
        dirList=os.listdir(os.getcwd() + path)
        for fname in dirList:
          rawfilenames.append(fname)
        fileList["directory"] = path
        fileList["rawfiles"] = rawfilenames
        fileList["listtype"] = '2'
      except:
        traceback.print_exc(file=sys.stderr)
    if int(type) == 4:
      path = "/reports/ig"
      subdir = ["/2008_09","/2009_10","/2010_11"]
      filenames =[]
      try:
        dirList=os.listdir(os.getcwd() + path + subdir[0])
        for fname in dirList:
          filenames.append(fname)
        fileList["directory"] = path
        fileList["subdir"]= subdir
        fileList["ig_files"] = filenames
        fileList["listtype"] = '4'
      except:
        traceback.print_exc(file=sys.stderr)
      
    web.header('Content-Type','text/html; charset=utf-8')
    return render_plain.listFiles(fileList)
