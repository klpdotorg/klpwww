import web
import psycopg2
import decimal
import jsonpickle
import csv
import re
import difflib
import geojson
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
     '/schoolsinfo/', 'getSchoolsInfo',
     '/assessment/(.*)/(.*)/(.*)','assessments',
     '/map*','map',
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
     '/schools', 'schools_bound',
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
              "5":[23],
              "6":[25],
              "7":[27],
              "8":[30],
              "9":[33],
              "14":[41,43,45,47],
              "15":[49],
              "18":[56],
              "23":[65,66,67],
              "24":[68,69],
              "25":[70],
              "26":[71],
              "28":[81,84],
              "29":[87,90,93],
              "30":[96,99],
              "31":[102,105,108]
              }

types={'district':'district','block':'block','cluster':'cluster','school':'school','preschooldistrict':'district','project':'block','circle':'cluster','preschool':'school'}


statements = {'get_district':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='District' and b.id=bcoord.id_bndry order by b.name",
              'get_preschooldistrict':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='PreSchoolDistrict' and b.id=bcoord.id_bndry order by b.name",
              'get_block':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='Block' and b.id=bcoord.id_bndry order by b.name",
              'get_cluster':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='Cluster' and b.id=bcoord.id_bndry order by b.name",
              'get_project':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='Project' and b.id=bcoord.id_bndry order by b.name",
              'get_circle':"select bcoord.id_bndry,ST_AsText(bcoord.coord),initcap(b.name) from vw_boundary_coord bcoord, tb_boundary b where bcoord.type='Circle' and b.id=bcoord.id_bndry order by b.name",
              'get_school':"select inst.instid, ST_AsText(inst.coord), upper(s.name), s.cat from vw_inst_coord inst, tb_school s,tb_boundary b where s.id=inst.instid and s.bid=b.id and b.type='1' order by s.name",
              'get_preschool':"select inst.instid ,ST_AsText(inst.coord),upper(s.name) from vw_inst_coord inst, tb_school s,tb_boundary b where s.id=inst.instid and s.bid=b.id and b.type='2' order by s.name",
              'get_district_points':"select distinct b1.id, b1.name from tb_boundary b, tb_boundary b1, tb_boundary b2,tb_bhierarchy hier where b.id=b1.parent and b1.id=b2.parent and b.hid=hier.id and b.type=1 and b.id=%s order by b1.name",
              'get_preschooldistrict_points':"select distinct b1.id, b1.name from tb_boundary b, tb_boundary b1,tb_boundary b2,tb_bhierarchy hier where b2.parent=b1.id and b1.parent = b.id and b.hid = hier.id and b.type=2 and b.id=%s",
              'get_block_points':"select distinct b2.id, b2.name from tb_boundary b, tb_boundary b1, tb_boundary b2,tb_bhierarchy hier where b.id=b1.parent and b1.id=b2.parent  and b.hid = hier.id and b.type=1 and b1.id=%s order by b2.name",
              'get_cluster_points':"select distinct s.id, s.name from tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s,tb_bhierarchy hier where b.id=b1.parent and b1.id=b2.parent and s.bid=b2.id and b.hid = hier.id and b.type=1 and b2.id=%s order by s.name",
              'get_project_points':"select distinct b2.id, b2.name from tb_boundary b, tb_boundary b1, tb_boundary b2,tb_bhierarchy hier where b.id=b1.parent and b1.id=b2.parent  and b.hid = hier.id and b.type=2 and b1.id=%s order by b2.name",
              'get_circle_points':"select distinct s.id, s.name from tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s,tb_bhierarchy hier where b.id=b1.parent and b1.id=b2.parent and s.bid=b2.id and b.hid = hier.id and b.type=2 and b2.id=%s order by s.name",
              'get_district_gender':"select sv.sex, sum(sv.num) from tb_institution_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b.id and b.parent = b1.id and b1.parent = b2.id and b2.id = %s group by sv.sex",
              'get_district_info':"select count(distinct sv.id),b2.name from tb_institution_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b.id and b.parent = b1.id and b1.parent = b2.id and b2.id = %s group by b2.name",
              'get_block_gender':"select sv.sex, sum(sv.num) from tb_institution_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b.id and b.parent = b1.id and b1.parent = b2.id and b1.id = %s group by sv.sex",
              'get_block_info':"select count(distinct sv.id),b1.name from tb_institution_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b.id and b.parent = b1.id and b1.parent = b2.id and b1.id = %s group by b1.name",
              'get_cluster_gender':"select sv.sex, sum(sv.num) from tb_institution_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b.id and b.parent = b1.id and b1.parent = b2.id and b.id = %s group by sv.sex",
              'get_cluster_info':"select count(distinct sv.id),b.name from tb_institution_agg sv, tb_boundary b, tb_boundary b1, tb_boundary b2 where sv.bid = b.id and b.parent = b1.id and b1.parent = b2.id and b.id = %s group by b.name",
              'get_school_gender':"select sv.name, sv.sex, sum(sv.num) from tb_institution_agg sv where sv.id = %s group by sv.name, sv.sex",
              'get_school_mt':"select sv.name, sv.mt, sum(sv.num) from tb_institution_agg sv where sv.id = %s group by sv.name, sv.mt",
              'get_school_boundary_info':"select b2.name, b1.name, b.name, s.name,b.type from tb_boundary b, tb_boundary b1, tb_boundary b2, tb_school s,tb_bhierarchy h where s.id = %s and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.hid=h.id",
              'get_num_stories':"select count(*) from tb_sys_data where schoolid= %s",
              'get_sys_qids':"select id, qfield from tb_sys_questions order by id",
              'get_sys_qtext':"select id, qtext from tb_sys_questions order by id",
              'get_sys_school_questions':"select * from tb_sys_displayq where hiertype=1 order by id",
              'get_sys_preschool_questions':"select * from tb_sys_displayq where hiertype=2 order by id",
              'get_programme_info':"select p.name,p.start,partner.name from tb_programme p,tb_partner partner where p.partnerid=partner.id and p.id =%s",
              'get_assessmentinfo_school':"select distinct p.name,p.start,p.id,pn.name from tb_programme p, tb_assessment ass, tb_institution_assessment_agg agg, tb_partner pn where agg.sid =%s  and ass.id = agg.assid and p.id = ass.pid and p.partnerid=pn.id",
              'get_district_assessmentinfo':"select distinct p.name, p.start,p.id,pn.name from tb_programme p, tb_assessment ass, tb_institution_assessment_agg agg, tb_boundary b, tb_boundary b1, tb_boundary b2, tb_school s, tb_partner pn where s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s and b.type=1 and agg.sid = s.id and ass.id = agg.assid and p.id = ass.pid and p.partnerid=pn.id",
              'get_block_assessmentinfo':"select distinct p.name, p.start,p.id ,pn.name from tb_programme p, tb_assessment ass, tb_institution_assessment_agg agg, tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s, tb_partner pn where s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.type=1 and agg.sid = s.id and ass.id = agg.assid and p.id = ass.pid and b1.id=%s  and p.partnerid=pn.id",
              'get_cluster_assessmentinfo':"select distinct p.name, p.start,p.id,pn.name from tb_programme p, tb_assessment ass, tb_institution_assessment_agg agg, tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s, tb_partner pn where s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.type=1 and agg.sid = s.id and ass.id = agg.assid and p.id = ass.pid and b.id=%s  and p.partnerid=pn.id",
              'get_basic_assessmentinfo_school':"select info.assid,info.studentgroup,info.sex,s.name, sum(info.num),b2.id,b1.id,b.id from tb_institution_basic_assessment_info info,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=%s and s.id=info.sid and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id group by info.sex,s.name,b2.id,b1.id,b.id, info.assid,info.studentgroup",
              'get_basic_assessmentinfo_district':"select info.assid,info.studentgroup,info.sex,b2.name, sum(info.num) from tb_institution_basic_assessment_info info ,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by info.sex,b2.name,info.assid,info.studentgroup",
              'get_basic_assessmentinfo_block':"select info.assid,info.studentgroup,info.sex,b1.name, sum(info.num) from tb_institution_basic_assessment_info info,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by info.sex,b1.name,info.assid,info.studentgroup",
              'get_basic_assessmentinfo_cluster':"select info.assid,info.studentgroup,info.sex,b.name, sum(info.num) from tb_institution_basic_assessment_info info,tb_assessment ass,tb_school s,tb_boundary b,tb_boundary b1, tb_boundary b2 where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by info.sex,b.name,info.assid,info.studentgroup",
              'get_assessmentpertext_school':"select agg.assid,agg.studentgroup,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass where ass.pid=%s and agg.assid=ass.id and agg.sid=%s group by agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_assessmentpertext_district':"select agg.assid,agg.studentgroup,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by agg.studentgroup,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid",
              'get_assessmentpertext_block':"select agg.assid,agg.studentgroup,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_assessmentpertext_cluster':"select agg.assid,agg.studentgroup,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_assessmentgender_school':"select agg.assid,agg.studentgroup,agg.sex,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass where ass.pid=%s and agg.assid=ass.id and agg.sid=%s group by agg.sex,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_assessmentgender_district':"select agg.assid,agg.studentgroup,agg.sex,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by agg.sex,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_assessmentgender_block':"select agg.assid,agg.studentgroup,agg.sex,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by agg.sex,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_assessmentgender_cluster':"select agg.assid,agg.studentgroup,agg.sex,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by agg.sex,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_assessmentmt_count_school':"select info.assid,info.studentgroup,info.mt,sum(info.num) from tb_institution_basic_assessment_info info,tb_assessment ass where ass.pid=%s and info.assid=ass.id and info.sid=%s group by info.mt,info.assid,info.studentgroup",
              'get_assessmentmt_count_district':"select info.assid,info.studentgroup,info.mt,sum(info.num) from tb_institution_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by info.mt,info.assid,info.studentgroup",
              'get_assessmentmt_count_block':"select info.assid,info.studentgroup,info.mt,sum(info.num) from tb_institution_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by info.mt,info.assid,info.studentgroup",
              'get_assessmentmt_count_cluster':"select info.assid,info.studentgroup,info.mt,sum(info.num) from tb_institution_basic_assessment_info info,tb_assessment ass,tb_boundary b,tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by info.mt,info.assid,info.studentgroup",
              'get_assessmentmt_school':"select agg.assid,agg.studentgroup,agg.mt,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass where ass.pid=%s and agg.assid=ass.id and agg.sid=%s group by agg.mt,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_assessmentmt_district':"select agg.assid,agg.studentgroup,agg.mt,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by agg.mt,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_assessmentmt_block':"select agg.assid,agg.studentgroup,agg.mt,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by agg.mt,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_assessmentmt_cluster':"select agg.assid,agg.studentgroup,agg.mt,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order, sum(agg.aggval) from tb_institution_assessment_agg agg,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by agg.mt,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,agg.assid,agg.studentgroup",
              'get_progress_count_school':"select info.assid,info.studentgroup,ass.name,sum(info.cohortsnum),ass.start from tb_institution_basic_assessment_info_cohorts info,tb_assessment ass where ass.pid=%s and info.assid=ass.id and info.sid=%s group by ass.name,ass.start,info.assid,info.studentgroup order by ass.start,info.studentgroup",
              'get_progress_count_district':"select info.assid,info.studentgroup,ass.name,  sum(info.cohortsnum),ass.start from tb_institution_basic_assessment_info_cohorts info,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id=%s group by ass.name,ass.start,info.assid,info.studentgroup  order by ass.start,info.studentgroup",
              'get_progress_count_block':"select info.assid,info.studentgroup,ass.name,  sum(info.cohortsnum),ass.start from tb_institution_basic_assessment_info_cohorts info,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id=%s group by ass.name,ass.start,info.assid,info.studentgroup order by ass.start,info.studentgroup",
              'get_progress_count_cluster':"select info.assid,info.studentgroup,ass.name,  sum(info.cohortsnum),ass.start from tb_institution_basic_assessment_info_cohorts info,tb_assessment ass,tb_boundary b,tb_boundary b1,tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id=%s group by ass.name,ass.start,info.assid,info.studentgroup  order by ass.start,info.studentgroup",
              'get_progress_school':"select agg.assid,s.name,agg.studentgroup,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,ass.name,  sum(agg.cohortsval),ass.start from tb_institution_assessment_agg_cohorts agg,tb_assessment ass,tb_school s where ass.pid=%s and agg.assid=ass.id and agg.sid=%s and s.id = agg.sid group by s.name,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,ass.name,ass.start,agg.assid,agg.studentgroup  order by ass.start,agg.studentgroup",
              'get_progress_district':"select agg.assid,b2.name,agg.studentgroup,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,ass.name,   sum(agg.cohortsval),ass.start from tb_institution_assessment_agg_cohorts agg,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and ass.pid=%s and b2.id=%s group by b2.name,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,ass.name,ass.start,agg.assid,agg.studentgroup",
              'get_progress_block':"select agg.assid,b1.name,agg.studentgroup,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,ass.name,   sum(agg.cohortsval),ass.start from tb_institution_assessment_agg_cohorts agg,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and ass.pid=%s and b1.id=%s group by b1.name,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,ass.name,ass.start,agg.assid,agg.studentgroup",
              'get_progress_cluster':"select agg.assid,b.name,agg.studentgroup,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,ass.name,   sum(agg.cohortsval),ass.start from tb_institution_assessment_agg_cohorts agg,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where agg.assid=ass.id and agg.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and ass.pid=%s and b.id=%s group by b.name,agg.domain,agg.domain_order,agg.aggtext,agg.aggtext_order,ass.name,ass.start,agg.assid,agg.studentgroup",
              'get_assessmentinfo_district':"select b2.name,info.studentgroup,ass.name,sum(info.cohortsnum) from tb_institution_basic_assessment_info_cohorts info,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b2.id = %s group by b2.name,info.studentgroup,ass.name",
              'get_assessmentinfo_block':"select b1.name,info.studentgroup,ass.name,sum(info.cohortsnum) from tb_institution_basic_assessment_info_cohorts info,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b1.id = %s group by b1.name,info.studentgroup,ass.name",
              'get_assessmentinfo_cluster':"select b.name,info.studentgroup,ass.name,sum(info.cohortsnum) from tb_institution_basic_assessment_info_cohorts info,tb_assessment ass,tb_boundary b, tb_boundary b1, tb_boundary b2,tb_school s where ass.pid=%s and info.assid=ass.id and info.sid=s.id and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id and b.id = %s group by b.name,info.studentgroup,ass.name",
              'get_school_info':"select b2.name, b1.name, b.name, s.name,b.type,s.cat,s.sex,s.moi,s.mgmt,s.dise_code,s.status from tb_boundary b, tb_boundary b1, tb_boundary b2, tb_school s where s.id = %s and s.bid=b.id and b.parent=b1.id and b1.parent=b2.id",
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
              'get_bounded_schools':"select inst.instid ,ST_AsText(inst.coord),upper(s.name) from vw_inst_coord inst, tb_school s,tb_boundary b where ST_Contains(ST_MakeEnvelope(%s,%s,%s,%s,-1), inst.coord) and s.id=inst.instid and s.bid=b.id and b.type='1' order by s.name;",
              'get_bounded_preschools':"select inst.instid ,ST_AsText(inst.coord),upper(s.name) from vw_inst_coord inst, tb_school s,tb_boundary b where ST_Contains(ST_MakeEnvelope(%s,%s,%s,%s,-1), inst.coord) and s.id=inst.instid and s.bid=b.id and b.type='2' order by s.name",

}

sqlstatements={"selectlevelagg":"select year,class as clas,month, cast(coalesce(sum(\"GREEN\"),0) as text) as \"GREEN\" , cast(coalesce(sum(\"ORANGE\"),0) as text) as \"ORANGE\" , cast(coalesce(sum(\"WHITE\"),0) as text) as \"WHITE\" , cast(coalesce(sum(\"YELLOW\"),0) as text) as \"YELLOW\" , cast(coalesce(sum(\"NONE\"),0) as text) as \"NONE\" , cast(coalesce(sum(\"RED\"),0) as text) as \"RED\" , cast(coalesce(sum(\"BLUE\"),0) as text) as \"BLUE\" from ( select year,class,month, (case when trim(book_level)='GREEN' then child_count else NULL end) as \"GREEN\", (case when trim(book_level)='ORANGE' then child_count else NULL end) as \"ORANGE\", (case when trim(book_level)='WHITE' then child_count else NULL end) as \"WHITE\", (case when trim(book_level)='YELLOW' then child_count else NULL end) as \"YELLOW\", (case when trim(book_level)='NONE' then child_count else NULL end) as \"NONE\", (case when trim(book_level)='RED' then child_count else NULL end) as \"RED\", (case when trim(book_level)='BLUE' then child_count else NULL end) as \"BLUE\" from (select year,class,month,book_level,sum(child_count) as child_count from vw_lib_level_agg where klp_school_id=$schlid group by month,book_level,class,year) as t) as t group by month,class,year",
        "selectlangagg":"select year,class as clas,month, cast(coalesce(sum(\"URDU\"),0) as text) as \"URDU\" , cast(coalesce(sum(\"KANNADA\"),0) as text) as \"KANNADA\" , cast(coalesce(sum(\"HINDI\"),0) as text) as \"HINDI\" , cast(coalesce(sum(\"ENGLISH\"),0) as text) as \"ENGLISH\" , cast(coalesce(sum(\"E/H\"),0) as text) as \"E/H\" , cast(coalesce(sum(\"E/K\"),0) as text) as \"E/K\" , cast(coalesce(sum(\"TAMIL\"),0) as text) as \"TAMIL\" , cast(coalesce(sum(\"TELUGU\"),0) as text) as \"TELUGU\" from ( select year,class,month, (case when trim(book_lang)='URDU' then child_count else NULL end) as \"URDU\", (case when trim(book_lang)='KANNADA' then child_count else NULL end) as \"KANNADA\", (case when trim(book_lang)='HINDI' then child_count else NULL end) as \"HINDI\", (case when trim(book_lang)='ENGLISH' then child_count else NULL end) as \"ENGLISH\", (case when trim(book_lang)='E/H' then child_count else NULL end) as \"E/H\", (case when trim(book_lang)='E/K' then child_count else NULL end) as \"E/K\", (case when trim(book_lang)='TAMIL' then child_count else NULL end) as \"TAMIL\", (case when trim(book_lang)='TELUGU' then child_count else NULL end) as \"TELUGU\" from (select year,class,month,book_lang,sum(child_count) as child_count from vw_lib_lang_agg where klp_school_id=$schlid group by month,book_lang,class,year) as t) as t group by month,class,year",
        "selectborrow":"select trans_year,cast(class as text) as clas,getmonth(split_part(issue_date,\'/\',2)) as month,school_name, count(klp_child_id) from vw_lib_borrow where klp_school_id=$schlid group by klp_school_id,month,trans_year,class,school_name",
        "selectyear":"select distinct year from vw_lib_level_agg where class is not null and klp_school_id=$schlid",
        "selecttotalstudents":"select trim(sg.name) as clas,count(distinct stu.id) as total,acyear.name as academic_year from tb_student_class stusg, tb_class sg,tb_student stu, tb_academic_year as acyear where stu.id=stusg.stuid and stusg.clid=sg.id and sg.sid=$schlid and stu.status=2 and acyear.id=stusg.ayid and acyear.name in (select distinct year from vw_lib_level_agg)  group by clas,academic_year"
}

render = web.template.render('templates/', base='base')
render_plain = web.template.render('templates/')

application = web.application(urls,globals()).wsgifunc()


class mainmap:
  """Returns the main template"""
  def GET(self):
    web.header('Content-Type','text/html; charset=utf-8')
    return render.klp()

class schools_bound:
  def GET(self):
    bounds = web.input('bounds').bounds.split(',')
    cursor = DbManager.getMainCon().cursor()
    for i in range(bounds.__len__()):
      bounds[i] = bounds[i].strip('"')

    pointInfo={"schools":[],"preschools":[]}
    count = 0
    for type in pointInfo:
      if type != 'count':
        features = []
        cursor.execute(statements['get_bounded_'+type] %(bounds[0],bounds[1],bounds[2],bounds[3],))
        result = cursor.fetchall()
        count = count + result.__len__()
        for row in result:
          match = re.match(r"POINT\((.*)\s(.*)\)",row[1])
          coord = [float(match.group(1)), float(match.group(2))]
          feature = geojson.Feature(id=row[0], geometry=geojson.Point(coord), properties={"name":row[2]})
          features.append(feature)

        feature_collection = geojson.FeatureCollection(features)
        pointInfo[type].append(geojson.dumps(feature_collection))
        DbManager.getMainCon().commit()
    cursor.close()
    pointInfo.update({'count': count})
    web.header('Content-Type', 'application/json')
    return jsonpickle.encode(pointInfo)

class getPointInfo:
  def GET(self):
    pointInfo={"district":[],"preschooldistrict":[], "block":[],"cluster":[],"project":[],"circle":[]}
    try:
      cursor = DbManager.getMainCon().cursor()
      for type in pointInfo:
        features = []
        cursor.execute(statements['get_'+type])
        result = cursor.fetchall()
        for row in result:
          try:
            match = re.match(r"POINT\((.*)\s(.*)\)",row[1])
          except:
            traceback.print_exc(file=sys.stderr)
            continue
          coord = [float(match.group(1)), float(match.group(2))]
          feature = geojson.Feature(id=row[0], geometry=geojson.Point(coord), properties={"name":row[2]})
          features.append(feature)
        feature_collection = geojson.FeatureCollection(features)
        pointInfo[type].append(geojson.dumps(feature_collection))
        DbManager.getMainCon().commit()
      cursor.close()
    except:
      traceback.print_exc(file=sys.stderr)
      cursor.close()
      DbManager.getMainCon().rollback()
    web.header('Content-Type', 'application/json')
    return jsonpickle.encode(pointInfo)

class getSchoolsInfo:
  def GET(self):
    pointInfo={"school":[],"preschool":[]}
    try:
      cursor = DbManager.getMainCon().cursor()
      for type in pointInfo:
        features = []
        cursor.execute(statements['get_'+type])
        result = cursor.fetchall()
        for row in result:
          try:
            match = re.match(r"POINT\((.*)\s(.*)\)",row[1])
          except:
            traceback.print_exc(file=sys.stderr)
            continue
          coord = [float(match.group(1)), float(match.group(2))]
          if type == "school":
            feature = geojson.Feature(id=row[0], geometry=geojson.Point(coord), properties={"name":row[2], "cat":row[3]})
          else:
            feature = geojson.Feature(id=row[0], geometry=geojson.Point(coord), properties={"name":row[2]})
          features.append(feature)
        feature_collection = geojson.FeatureCollection(features)
        pointInfo[type].append(geojson.dumps(feature_collection))
        DbManager.getMainCon().commit()
      cursor.close()
    except:
      traceback.print_exc(file=sys.stderr)
      cursor.close()
      DbManager.getMainCon().rollback()
    web.header('Content-Type', 'application/json')
    return jsonpickle.encode(pointInfo)


class map:
  def GET(self):
    web.header('Content-Type','text/html; charset=utf-8')
    return render_plain.map()



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
    self.id=id
    self.pid=pid
    self.data= {"programme":{"pid":int(self.pid),"name":"","year":"","partner":""},"assessment":{}}
  def getData(self):
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_pratham_assessment_info'],(self.pid,))
    result=cursor.fetchall()
    for row in result:
      self.data["programme"]["name"]=row[0]
      self.data["programme"]["partner"]=row[1]
      self.data["programme"]["year"]=row[2]
    cursor.execute(statements['get_pratham_assessment_questions'],(self.id,))
    result=cursor.fetchall()
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
      self.assesstext={}
      self.data= {"programme":{"pid":int(self.pid),"name":"","year":"","partner":""},"type":self.type,"name":"","Boys":0,"Girls":0,"baseline":{},"progress":{},"analytics":{},"base":{"classes":{},"gender":{},"mt":{},"progress":{}}}

    def getProgramInfo(self):
      try:
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements['get_programme_info'],(self.pid,))
        result = cursor.fetchall()
        for row in result:
          self.data["programme"]["name"]=str(row[0])
          self.data["programme"]["year"]=str(row[1]).split("-")[0]
          self.data["programme"]["partner"]=str(row[2])
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getBasicAssessmentInfo(self):
      try:
        qtype=types[self.type]
        query='get_basic_assessmentinfo_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          self.data["name"]=str(row[3]).capitalize()
          if row[0] not in baseassess[self.pid]:
            if qtype=='school' or qtype=='preschool':
              self.districtid=row[5]
              self.blockid=row[6]
              self.clusterid=row[7]
            continue
          classname=str(row[1]).strip()
          if classname not in self.data["base"]["classes"]:
            self.data["base"]["classes"][classname]={"Boys":0,"Girls":0}
          if row[2] == "female":
            gender="Girls"
          else:
            gender="Boys"
          if gender not in self.data["base"]["classes"][classname]:
            self.data["base"]["classes"][classname][gender]=int(row[4])
          else:
            self.data["base"]["classes"][classname][gender]=self.data["base"]["classes"][classname][gender]+int(row[4])

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

        for classname in self.data["base"]["classes"]:
          for gender in self.data["base"]["classes"][classname]:
            self.data[gender]=self.data[gender]+self.data["base"]["classes"][classname][gender]
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getBaselineGeneral(self):
      try:
        qtype=types[self.type]
        query='get_assessmentpertext_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          if row[0] not in baseassess[self.pid]:
            continue
          classname=str(row[1]).strip()
          if classname not in self.data["baseline"]:
             self.data["baseline"][classname]={}

          domain=str(row[2])
          domain_order=int(row[3])
          asstext=str(row[4])
          asstext_order=int(row[5])
          assval=int(row[6])
          if domain not in self.data["baseline"][classname]:
            self.data["baseline"][classname][domain]={"order":domain_order}
          if asstext not in self.data["baseline"][classname][domain]:
            self.data["baseline"][classname][domain][asstext]={"order":asstext_order,"value":assval,"gender":{},"mt":{}}
          else:
            self.data["baseline"][classname][domain][asstext]["value"]=self.data["baseline"][classname][domain][asstext]["value"]+assval


          if classname not in self.assesstext:
             self.assesstext[classname]={}
          if asstext_order not in self.assesstext[classname]:
             self.assesstext[classname][asstext_order]=asstext

        for classname in  self.data["baseline"]:
          for domain in self.data["baseline"][classname]:
            for asstext in self.data["baseline"][classname][domain]:
               if asstext=='order':
                 continue
               self.data["baseline"][classname][domain][asstext]["actual_value"]=int(self.data["baseline"][classname][domain][asstext]["value"])
               self.data["baseline"][classname][domain][asstext]["value"]=round((float(self.data["baseline"][classname][domain][asstext]["value"])/float(self.total[classname]))*100.0,2)
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getBaselineGender(self):
      try:
        qtype=types[self.type]
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

          domain=str(row[3])
          domain_order=int(row[4])
          asstext=str(row[5])
          asstext_order=int(row[6])
          assval=int(row[7])
     

          if gender not in self.data["baseline"][classname][domain][asstext]["gender"]:
            self.data["baseline"][classname][domain][asstext]["gender"][gender]=float(assval)
          else:
              self.data["baseline"][classname][domain][asstext]["gender"][gender]=float(self.data["baseline"][classname][domain][asstext]["gender"][gender])+float(assval)

          if classname not in self.assesstext:
             self.assesstext[classname]={}
          if asstext_order not in self.assesstext[classname]:
             self.assesstext[classname][asstext_order]=asstext

          if gender not in self.data["base"]["gender"]:
             self.data["base"]["gender"][gender]=1


        for classname in self.data["baseline"]:
          for domain in self.data["baseline"][classname]:
            for asstext in self.data["baseline"][classname][domain]:
              if asstext=='order':
                continue
              for gender in self.data["baseline"][classname][domain][asstext]["gender"]:
                if self.data["baseline"][classname][domain][asstext]["gender"][gender]==0.0:
                  continue
                self.data["baseline"][classname][domain][asstext]["gender"][gender]=round((float(self.data["baseline"][classname][domain][asstext]["gender"][gender])/float(self.data["baseline"][classname][domain][asstext]["actual_value"]))*100.0,2)

        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getBaselineMTCount(self,type):
      try:
        type=types[self.type]
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
        qtype=types[self.type]
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
          domain=str(row[3])
          domain_order=int(row[4])
          asstext=str(row[5])
          asstext_order=int(row[6])
          assval=int(row[7])
          if mt not in self.data["baseline"][classname][domain][asstext]["mt"]:
            self.data["baseline"][classname][domain][asstext]["mt"][mt]=float(assval)
          else:
              self.data["baseline"][classname][domain][asstext]["mt"][mt]=float(self.data["baseline"][classname][domain][asstext]["mt"][mt])+float(assval)

          if classname not in self.assesstext:
             self.assesstext[classname]={}
          if asstext_order not in self.assesstext[classname]:
             self.assesstext[classname][asstext_order]=asstext

          if mt not in self.data["base"]["mt"]:
             self.data["base"]["mt"][mt]=1


        for classname in self.data["baseline"]:
          for domain in self.data["baseline"][classname]:
            for asstext in self.data["baseline"][classname][domain]:
              if asstext=='order':
                continue
              for mt in self.data["baseline"][classname][domain][asstext]["mt"]:
                if self.data["baseline"][classname][domain][asstext]["mt"][mt]==0.0:
                  continue
                self.data["baseline"][classname][domain][asstext]["mt"][mt]=round((float(self.data["baseline"][classname][domain][asstext]["mt"][mt])/float(self.data["baseline"][classname][domain][asstext]["actual_value"]))*100.0,2)
 
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getProgressCount(self,qtype):
      try:
        query='get_progress_count_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          classname=str(row[1]).strip()
          assname=str(row[2])
          count=int(row[3])
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
        qtype=types[self.type]
        self.getProgressCount(qtype)
        query='get_progress_'+qtype
        cursor = DbManager.getMainCon().cursor()
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          classname=str(row[2]).strip()
          domain=str(row[3])
          domain_order=int(row[4])
          aggtext=str(row[5])
          aggtext_order=int(row[6])
          assname=str(row[7])
          sum=int(row[8])
          starttime=str(row[9])

          if classname not in self.data["progress"]:
            self.data["progress"][classname]={}
          if domain not in self.data["progress"][classname]:
            self.data["progress"][classname][domain]={"order":domain_order}
          if aggtext not in self.data["progress"][classname][domain]:
            self.data["progress"][classname][domain][aggtext]={"order":aggtext_order}
     
          if starttime not in self.data["progress"][classname][domain][aggtext]:
            self.data["progress"][classname][domain][aggtext][starttime]={}
          if assname not in self.data["progress"][classname][domain][aggtext][starttime]:
            self.data["progress"][classname][domain][aggtext][starttime][assname]=sum
          else:
            self.data["progress"][classname][domain][aggtext][starttime][assname]=self.data["progress"][classname][domain][aggtext][starttime][assname]+sum

          if classname not in self.assesstext:
             self.assesstext[classname]={}
          if aggtext_order not in self.assesstext[classname]:
             self.assesstext[classname][aggtext_order]=aggtext

          if classname not in self.data["base"]["progress"]:
             self.data["base"]["progress"][classname]={}
          if starttime not in self.data["base"]["progress"][classname]:
             self.data["base"]["progress"][classname][starttime]=assname

          if classname not in self.data["base"]["classes"]:
            self.data["base"]["classes"][classname]={"Boys":0,"Girls":0}

        for classname in self.data["progress"]:
          for domain in self.data["progress"][classname]:
            for aggtext in self.data["progress"][classname][domain]:
              if aggtext=='order':
                continue
              for starttime in self.data["progress"][classname][domain][aggtext]:
                if starttime=='order':
                  continue
                for assname in self.data["progress"][classname][domain][aggtext][starttime]:
                  self.data["progress"][classname][domain][aggtext][starttime][assname]=round((float(self.data["progress"][classname][domain][aggtext][starttime][assname])/float(self.count[classname][assname]))*100.0,2)
        cursor.close()
        DbManager.getMainCon().commit()
      except:
        traceback.print_exc(file=sys.stderr)
        cursor.close()
        DbManager.getMainCon().rollback()

    def getAnalyticsInfo(self):
      name=self.data["name"].capitalize()+" (School)"
      try:
        schoolinfo={"type":self.type,"id":int(self.id),"order":3,"name":self.data["name"].capitalize()}
        cursor = DbManager.getMainCon().cursor()
        qtype=types[self.type]
        query='get_progress_'+qtype
        cursor.execute(statements[query],(self.pid,self.id,))
        result = cursor.fetchall()
        for row in result:
          sname=str(row[1]).capitalize()
          classname=str(row[2]).strip()
          domain=str(row[3])
          domain_order=int(row[4])
          aggtext=str(row[5])
          aggtext_order=int(row[6])
          assname=str(row[7])
          aggsum=float(row[8])
          starttime=str(row[9])

          if classname not in self.data["analytics"]:
            self.data["analytics"][classname]={}
          if starttime not in self.data["analytics"][classname]:
            self.data["analytics"][classname][starttime]={}
          if assname not in self.data["analytics"][classname][starttime]:
            self.data["analytics"][classname][starttime][assname]={}
          if domain not in self.data["analytics"][classname][starttime][assname]:
            self.data["analytics"][classname][starttime][assname][domain]={"order":domain_order}
          if aggtext not in self.data["analytics"][classname][starttime][assname][domain]:
            self.data["analytics"][classname][starttime][assname][domain][aggtext]={"order":aggtext_order,"value":{}}
          self.data["analytics"][classname][starttime][assname][domain][aggtext]["value"][self.type]={"name":sname,"value":round(float(aggsum/float(self.count[classname][assname]))*100.0,2),"type":qtype.capitalize()}

          if classname not in self.data["base"]["classes"]:
            self.data["base"]["classes"][classname]={"Boys":0,"Girls":0}

          if classname not in self.assesstext:
             self.assesstext[classname]={}
          if aggtext_order not in self.assesstext[classname]:
             self.assesstext[classname][aggtext_order]=aggtext

    
        schoolboundaries=[{"type":"district","id":self.districtid,"order":0},{"type":"block","id":self.blockid,"order":1},{"type":"cluster","id":self.clusterid,"order":2}]
        preschoolboundaries=[{"type":"preschooldistrict","id":self.districtid,"order":0},{"type":"project","id":self.blockid,"order":1},{"type":"circle","id":self.clusterid,"order":2}]

        boundaries=schoolboundaries
        if self.type=="preschool":
          boundaries=preschoolboundaries
        self.data["base"]["analytics"]=boundaries

        boundarytotal={}
        for boundary in boundaries:
          boundarytotal[boundary["id"]]={}
          btype=boundary["type"]
          query='get_assessmentinfo_'+types[btype]
          cursor.execute(statements[query],(self.pid,boundary["id"],))
          result = cursor.fetchall()
          bname=""
          for row in result:
            classname=str(row[1]).strip()
            assname=str(row[2])
            classsum=int(row[3])
            if classname not in boundarytotal[boundary["id"]]:
              boundarytotal[boundary["id"]][classname]={}
            boundarytotal[boundary["id"]][classname][assname]=classsum


        count=0
        for boundary in boundaries:
          btype=types[boundary["type"]]
          query='get_progress_'+btype
          cursor.execute(statements[query],(self.pid,boundary["id"],))
          result = cursor.fetchall()
          for row in result:
            boundarytype=boundary["type"].capitalize()
            bname=str(row[1]).capitalize()
            classname=str(row[2]).strip()
            domain=str(row[3])
            domain_order=int(row[4])
            aggtext=str(row[5])
            aggtext_order=int(row[6])
            assname=str(row[7])
            aggsum=float(row[8])
            starttime=str(row[9])


            self.data["base"]["analytics"][count]["name"]=bname
            if classname not in self.data["analytics"]:
              self.data["analytics"][classname]={}
            if starttime not in self.data["analytics"][classname]:
              self.data["analytics"][classname][starttime]={}
            if assname not in self.data["analytics"][classname][starttime]:
              self.data["analytics"][classname][starttime][assname]={}
            if domain not in self.data["analytics"][classname][starttime][assname]:
              self.data["analytics"][classname][starttime][assname][domain]={}
            if aggtext not in self.data["analytics"][classname][starttime][assname][domain]:
              self.data["analytics"][classname][starttime][assname][domain][aggtext]={"order":aggtext_order,"value":{}}
            self.data["analytics"][classname][starttime][assname][domain][aggtext]["value"][boundary["type"]]={"name":bname,"value":round((float(aggsum)/float(boundarytotal[boundary["id"]][classname][assname]))*100,2),"type":boundarytype}

            if classname not in self.data["base"]["classes"]:
              self.data["base"]["classes"][classname]={"Boys":0,"Girls":0}

            if classname not in self.assesstext:
               self.assesstext[classname]={}
            if aggtext_order not in self.assesstext[classname]:
               self.assesstext[classname][aggtext_order]=aggtext

          count=count+1

        self.data["base"]["analytics"].append(schoolinfo)

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
      for classname in self.assesstext:
        for assessorder in self.assesstext[classname]:
          if "assesstext" not in self.data["base"]["classes"][classname]:
            self.data["base"]["classes"][classname]["assesstext"]=[]
          self.data["base"]["classes"][classname]["assesstext"].append(self.assesstext[classname][assessorder])
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
  def getKlpEnrolment(id):
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
    return data;


  @staticmethod
  def getDiseEnrolment(id):
    data = {}
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_dise_stuinfo'],(id,))
    result = cursor.fetchall()
    for row in result:
      data['boys_count'] = str(row[0])
      data['girls_count'] = str(row[1])
      data['student_count'] = str(int(row[1]) + int(row[0]))
    DbManager.getMainCon().commit()
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
      data.update(self.getacyear(id))
      if tab == 'basics':
        data.update(self.getBasicData(id))
        data.update(self.getSYSImages(id))
      elif tab == 'demographics':
        data.update(CommonSchoolUtil.getKlpEnrolment(id))
      	data.update(self.getDemographicData(id))
        if type=='school':
          data.update(CommonSchoolUtil.getDiseEnrolment(id))
      elif tab == 'programmes':
        data.update(self.getProgrammeData(id,type))  
      elif tab == 'finances':
        if type=='school':
          data.update(self.getFinData(id))
      elif tab == 'infrastructure':
        if type=='school':
          data.update(self.getDiseData(id))
          #data.update(self.getLibraryData(id))
        if type=='preschool':
          data.update(self.getAngInfraData(id))
      elif tab == 'nutrition':
        if type=='school':
          data.update(self.getMidDayMealData(id))
          data.update(CommonSchoolUtil.getKlpEnrolment(id))
          data.update(CommonSchoolUtil.getDiseEnrolment(id))
      elif tab == 'library':
        # Library chart data
        data.update(self.getLibraryChartData(id))
	data.update(self.getLibraryData(id))
      elif tab == 'stories' :
        data.update(self.getSYSData(id))
        data.update(self.getSYSImages(id))
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

  def getacyear(self,klpid):
    tabledata={}
    cursor = DbManager.getMainCon().cursor()
    cursor.execute(statements['get_dise_ptr'],(klpid,))
    result = cursor.fetchall()
    for row in result:
      tabledata['acyear'] = str(row[4])
      tabledata['dise_books'] = str(row[7])
    DbManager.getMainCon().commit()
    cursor.close()
    return tabledata
 

  #library chart function
  def getLibraryChartData(self,schlid):
    data={}
    #db=web.database()
    db=KLPDB.getWebDbConnection()
    resultlevel=[['year','clas','month','GREEN','RED','ORANGE','WHITE','BLUE','YELLOW']]
    resultlang=[['year','clas','month','URDU','KANNADA','HINDI','ENGLISH','E/H','E/K','TAMIL','TELUGU']]
    resultborrow=[['academic_year','clas','month','school_name','count']]
    classtotals=[['clas','total','acyear']]
    clas=[1,2,3,4,5,6,7]
    year=[]
    for row in db.query(sqlstatements["selectlevelagg"],{"schlid":schlid}):
        resultlevel.append([row.year,row.clas,row.month,row.GREEN,row.RED,row.ORANGE,row.WHITE,row.BLUE,row.YELLOW])
    for row in db.query(sqlstatements["selectlangagg"],{"schlid":schlid}):
        resultlang.append([row.year,row.clas,row.month,row.KANNADA,row.URDU,row.HINDI,row.ENGLISH,getattr(row,'E/H'),getattr(row,'E/K'),row.TAMIL,row.TELUGU])
    for row in db.query(sqlstatements["selectborrow"],{"schlid":schlid}):
        resultborrow.append([row.trans_year,row.clas,row.month,row.school_name,row.count])
    for row in db.query(sqlstatements["selectyear"],{"schlid":schlid}):
        year.append(row.year)
    for row in db.query(sqlstatements["selecttotalstudents"],{"schlid":schlid}):
        classtotals.append([row.clas,row.total,row.academic_year])
    #return render.libchart(schlid,resultlevel,resultlang,resultborrow,clas,year,classtotal)
    data["resultlevel"]=resultlevel
    data["resultlang"]=resultlang
    data["resultborrow"]=resultborrow
    data["clas"]=clas
    data["year"]=year
    data["classtotal"]=classtotals
    #print data
    return data
    #End of library funciton
    
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
      #tabledata['acyear'] = str(row[4])
      tabledata['lowest_class'] = str(row[5])
      tabledata['highest_class'] = str(row[6])
      #tabledata['dise_books'] = str(row[7])
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
    query='get_assessmentinfo_'+types[type]
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
    textlinks = {'library': 'library', 'maths': 'maths', 'preschool': 'preschool', 'reading': 'reading', 'partners': 'partners','aboutus':'aboutus','credits':'credits', 'reports':'reports', 'disclaimer':'disclaimer'}

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
      type=types[type]
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
        if type == 'cluster':
          parts = row[1].split()
          name = parts[0].upper()+' '+parts[1].capitalize()
          data={"id":row[0],"name":name}
        else:
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
      path = ConfigReader.getConfigValue('Reports','klpreports')
      fileList["reptype"] = ["demographics","finances","infrastructure","library"]
      fileList["subdir1"] = "/Kannada"
      fileList["subdir2"] = "/English"
      fileList["directory"] = path
      try:
        dirList=os.listdir(os.path.dirname(os.getcwd()) + path + "/demographics/English")
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
      path = ConfigReader.getConfigValue('Reports','rawdata')
      rawfilenames =[]
      try:
        dirList=os.listdir(os.path.dirname(os.getcwd()) + path)
        for fname in dirList:
          rawfilenames.append(fname)
        fileList["directory"] = path
        fileList["rawfiles"] = rawfilenames
        fileList["listtype"] = '2'
      except:
        traceback.print_exc(file=sys.stderr)
    if int(type) == 4:
      path = ConfigReader.getConfigValue('Reports','igreports')
      subdir = ["/2008_09","/2009_10","/2010_11"]
      filenames =[]
      try:
        dirList=os.listdir(os.path.dirname(os.getcwd()) + path + subdir[0])
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
