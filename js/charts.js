var previousPoint = null;
var datasets;
var choiceContainer;
var info;

google.load('visualization', '1', {'packages':['corechart','table','imagechart']});

var pdomain={"Reading":{"O":0,"L":2,"W":4,"S":6,"P":8},
            "Reading2006":{"0":0,"L":2,"W":4,"S":6,"P":8},
            "NNG":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},
            "Reading-Dharwad":{"O":0,"L":2,"W":4,"S":6,"P":8},
           };


var classdomain={"Anganwadi":{"Age between 3-5":{"Gross Motor":0,"Fine Motor":1,"Socio-Emotional":2,"General Awareness":3},
                              "Age >=5":{"Language":0,"Intellectual Development":1,"Socio-Emotional":2,"Pre-Academic":3}},
                 "English2009":{"5":{'Can recognizes the objects in picture':0,'Picture Reading-Can construct  simple sentences':1,'Can read words':2,'Can read simple passage':3,'Can give one word  answer orally':4},
                                "6":{'Can recognizes the objects in picture':0,'Picture Reading-Can construct  simple sentences':1,'Can read words':2,'Can read simple passage':3,'Can write one word  answers':4}},
                 "English2010":{"3":{'Can write alphabets':0,'Can follow simple instruction':1,'Can give one word answer':2},
                                "4":{'Picture reading':0,'Can answer in sentence':1,'Can read a simple sentence':2}},
                };

var levels={
               "1":{"type":"pdomain","index":"Reading2006"},
               "2":{"type":"pdomain","index":"NNG"},
               "3":{"type":"pdomain","index":"NNG"},
               "5":{"type":"classdomain","index":"Anganwadi"},
               "6":{"type":"classdomain","index":"English2009"},
               "7":{"type":"pdomain","index":"Reading"},
               "8":{"type":"pdomain","index":"Reading-Dharwad"},
               "9":{"type":"pdomain","index":"NNG"},
               "14":{"type":"pdomain","index":"NNG"},
               "15":{"type":"classdomain","index":"English2010"},
               "18":{"type":"classdomain","index":"Anganwadi"},
               "19":{"type":"pdomain","index":"Reading"},
            };


var color={"0":"red","O":"red","L":"orange","W":"#ffe438","S":"blue","P":"green","Boys":"blue","Girls":"pink"};

var preschooltypeIndex={"Preschooldistrict":0,"Project":1,"Circle":2,"School":3};
var typeIndex={"District":0,"Block":1,"Cluster":2,"School":3};

var generalChart={"Pie":{1:1,2:1,3:1,7:1,8:1,9:1,10:1,11:1,12:1,13:1,14:1,19:1},"Bar":{5:1,6:1,15:1,18:1}};


var tabberOptions = {

  /* Optional: instead of letting tabber run during the onload event,
     we'll start it up manually. This can be useful because the onload
     even runs after all the images have finished loading, and we can
     run tabber at the bottom of our page to start it up faster. See the
     bottom of this page for more info. Note: this variable must be set
     BEFORE you include tabber.js.
  */
  'manualStartup':true,

  /* Optional: code to run after each tabber object has initialized */

  'onLoad': function(argsObj) {
    /* Display an alert only after tab2 */
    if (argsObj.tabber.id == 'tab2') {
      alert('Finished loading tab2!');
    }
  },

  /* Optional: code to run when the user clicks a tab. If this
     function returns boolean false then the tab will not be changed
     (the click is canceled). If you do not return a value or return
     something that is not boolean false, */

  'onClick': function(argsObj) {

    var t = argsObj.tabber; /* Tabber object */
    var id = t.id; /* ID of the main tabber DIV */
    var i = argsObj.index; /* Which tab was clicked (0 is the first tab) */
    var e = argsObj.event; /* Event object */

    if (id == 'tab2') {
      return confirm('Swtich to '+t.tabs[i].headingText+'?\nEvent type: '+e.type);
    }
  },

  /* Optional: set an ID for each tab navigation link */
  'addLinkId': true

};


function initCap(str)
{
  str = str.substring(0,1).toUpperCase() + str.substring(1,str.length).toLowerCase();
 return str;
}

function initialise(data)
{
   info= data;
document.getElementById("tabview-heading").innerHTML="Assessments (<i>Partner:"+info["programme"]["partner"]+"</i>)";
if( info["type"] == "school" || info["type"] == "preschool")//show analytics
{
var maintab=document.getElementById('maintab');
var analtab=document.createElement('div');
analtab.setAttribute('id','analytics');
analtab.setAttribute('class','tabbertab');
maintab.appendChild(analtab);
document.getElementById("analytics").innerHTML='<h2>Analytics</h2> <div id="school-analytics-info"> </div> <div id="school-analytics-content"> </div>';
}
tabberAutomatic(tabberOptions);
chartData(info["programme"]["pid"],info["programme"]["name"]);
}

function chartData(pid,programme)
{
enrollment("school",pid,programme);
baselinedata("school",programme);
progressdata("school",pid,programme); 
if ( info["type"]=="school" || info["type"]=="preschool")
{
analyticsdata("school",programme);
}
}

function enrollment(schooltype,pid,programme)
{
syear = Number(info["programme"]["year"]);
eyear = syear+1;
document.getElementById("program-school_name").innerHTML='<br><b>'+programme+' Program, enrollment data for '+info["name"]+'('+initCap(info["type"])+') in '+syear+'-'+eyear+':-</b><br>'
tablecontent='<br><table class=\"chart-table\" width=\"550\" border=\"1\" style=\"border-width:1px; border-style:dotted; border-color:#CCCCCC;\"><tr><td>Class/ Age-Group</td><td>Number of Boys</td><td>Number of Girls</td><td>Total</td></tr>';

classnames=[];
for(classname in info["base"])
{
classnames.push(classname);
}
classnames.sort();
for(var i = 0; i < classnames.length; i++)
{
var classname=classnames[i];
var total=parseInt(info["base"][classname]["Boys"])+parseInt(info["base"][classname]["Girls"]);
tablecontent=tablecontent+"<tr><td>"+classname+"</td><td>"+info["base"][classname]["Boys"]+"</td><td>"+info["base"][classname]["Girls"]+"</td><td>"+total+"</td></tr>";
}
tablecontent=tablecontent+"</table>";
document.getElementById("numchild").innerHTML=tablecontent;

if(pid=="1" || pid=="4" || pid=="7" || pid=="8" ||pid=="13" || pid=="19")
{
document.getElementById("programinfo").innerHTML='<br><hr/><br>The <a href=\"/text/reading\"><b>Reading program</b></a> measures the competency of a child using the following levels:<br><ul><li>0:- Child not able to read</li><li>L:- Child able to read letters</li><li>W:- Child able to read words</li><li>S:- Child able to read sentences</li><li>P:- Child able te read Paragaphs</li></ul>'
  }
  if(pid=="2" || pid=="3" || pid=="9" || pid=="10"|| pid=="11" || pid=="12" || pid=="14" || pid=="16")
  {
    document.getElementById("programinfo").innerHTML='<br><hr/><br>The <a href=\"/text/maths\"><b>Math program</b></a> measures the competency of a child using the following levels:<br><ul><li>Rung1:- 0-20</li><li>Rung2:- 21-40 </li><li>Rung3: -41-60 </li><li>Rung4:- 61-80 </li><li>Rung5:- 81-100</li></ul>';
  }
  if(pid=="6")
  {
    document.getElementById("programinfo").innerHTML='<br><hr/><br>The <a href=\"/text/english\"><b>English program</b></a> measures the competency of a child using the following levels:<br><ul><b>For Class 5:</b><li>Can recognizes the objects in picture</li><li>Picture Reading-Can construct simple sentences</li><li>Can read words</li><li>Can read simple passage</li><li>Can give one word answer orally</li></ul><br><ul><b>For Class 6:</b><li>Can recognizes the objects in picture</li><li>Picture Reading-Can construct simple sentences</li><li>Can read words</li><li>Can read simple passage</li><li>Can write one word answers</li></ul>';
  }
  if(pid=="15")
  {
    document.getElementById("programinfo").innerHTML='<br><hr/><br>The <a href=\"/text/english\"><b>English program</b></a> measures the competency of a child using the following levels:<br><ul><b>For Class 3:</b><li>Can write letters of the alphabet</li><li>Can follow simple instruction</li><li>Can give one word answer</li></ul><br><ul><b>For Class 4:</b><li>Picture label Reading</li><li>Can answer in sentence</li><li>Can read a simple sentence</li></ul>';
  }
  if(pid=="5" || pid=="18")
  {
    document.getElementById("programinfo").innerHTML='<br><hr/><br>The <a href=\"/text/preschool\"><b>Anganwadi Program'+"'s</b></a> diagnostic test measures children's abilities across the following competencies:<br><ul><li>General awareness</li><li>Gross Motor</li><li>Fine Motor</li><li>Language</li><li>Intellectual</li><li>Socio-emotional</li><li>Pre-academic</li></ul>";
  }
}

function baselinedata(divtype,programme)
{
   if(info["programme"]["pid"] in generalChart["Pie"])
   {
     basegeneral(divtype,programme,"Pie");
   }
   else
   {
     basegeneral(divtype,programme,"Bar");
   }
   levelbar(divtype,programme,info["baseline"],"gender");
   levelbar(divtype,programme,info["baseline"],"mt");
}

function basegeneral(type,programme,graphtype)
{
   var count=0;
   var classcount=0;
   var classnames=[];
   var grid=12;
   for(classname in info["assessPerText"])
   {
     classnames.push(classname);
     classcount=classcount+1;
   }
   classnames.sort();
   grid=grid/2;
   var width=400;
   var numgraphs=2
   if(info['type']=='preschool'|| info['type']=='project' || info['type']=='circle' || info['type']=='preschooldistrict')
   {
      width=600;
      numgraphs=1
   }
   if(info["programme"]["pid"]==6 || info["programme"]["pid"]==15)
   {
      width=700;
      numgraphs=1
   }
   var height=300;
   var count=0;
   for(var i = 0; i < classnames.length; i++)
   {
     count=count+1;
     var classname=classnames[i];
     var data=new google.visualization.DataTable();
     data.addColumn('string',"Rung");
     data.addColumn('number',"% of students");
     var colors=[]
     if (levels[info["programme"]["pid"]]["type"]=="pdomain")
       plevels=pdomain[levels[info["programme"]["pid"]]["index"]];
     else
       plevels=classdomain[levels[info["programme"]["pid"]]["index"]][classname];
     
     for(text in plevels)
     {
       var value=0;
       if(text in info["assessPerText"][classname])
       {
         value=Math.round(info["assessPerText"][classname][text]);
       }
       if (graphtype=="Pie")
       {
         data.addRow([text,value]);
       }
       else
       {
         data.addRow([text+" ("+value+")",value]);
       }
       if(text in color)
       {
         colors.push(color[text]);
       }
     }
     var general_div=document.getElementById(type+"-general-content");
     var divIdName = type+"-"+classname+"-general";
     var newdiv=document.createElement('div');
     newdiv.setAttribute('id',divIdName);
     newdiv.setAttribute('class','grid_'+grid);
     general_div.appendChild(newdiv);
     var options = {
          title: 'Class-'+classname,
          width: width, height: height,
          backgroundColor: {stroke:'#000000',strokeWidth:'1',fill:'#F4E193'},
          colors: ['006D2C','31A354','74C476','BAE4B3','EDF8E9']
        };

    if( graphtype=="Pie")
    {
      if(colors.length >0 )
      {
        options['colors']=colors;
      }  
      options['pieSliceTextStyle']={'color':'black'};
      var chart = new google.visualization.PieChart(document.getElementById(divIdName));
    }
    else
    {
      options['hAxis']={'title':'% of students','maxValue':100,'minValue':0};
      options['chartArea']={'width':200};
      var chart = new google.visualization.BarChart(document.getElementById(divIdName));
    }
    if(info["programme"]["pid"]==15)
    {
          options['chartArea']['left']='225';
         options['chartArea']['width']='40%';
    }
    if(info["programme"]["pid"]==6)
    {
       options['chartArea']['left']='350';
       options['chartArea']['width']='30%';
    }
    if(info['type']=="preschool"|| info['type']=='project' || info['type']=='circle' || info['type']=='preschooldistrict')
    {
       options['title']=classname;
    }
    chart.draw(data,options);

    if(count==numgraphs)
    {
      var br=document.createElement('div');
      br.setAttribute('style','height:14px');
      br.setAttribute('class','grid_12');
      general_div.appendChild(br);
      count=0;
    }

  }
}



function analyticsdata(divtype,programme)
{
  var count=0;
  var classcount=0;
  var classnames=[];
  var grid=12;
  for(classname in info["analytics"])
  {
     classnames.push(classname);
     classcount=classcount+1;
  }
  classnames.sort();
  grid=grid/2;
  var width=400;
  var height=300;
  var numgraphs=2;
  if(info["programme"]["pid"]==6 || info["programme"]["pid"]==15 || info["programme"]["pid"]==5 || info["programme"]["pid"]==18)
  {
      width=750;
      numgraphs=1
  }

  var count=0;
  var analyticsinfo="<ul>"
  for(var i = 0; i < classnames.length; i++)
  {
    var classname=classnames[i];
    analyticsinfo=analyticsinfo+'<li><a href="#'+divtype+"-analytics-class-"+classname+'"><b>Class-'+classname+"</b></a></li>"
    var general_div=document.getElementById(divtype+"-analytics-content");
    var parentdivIdName = divtype+"-analytics-class-"+classname
    var newdiv=document.createElement('div');
    newdiv.setAttribute('id',parentdivIdName);
    newdiv.setAttribute('class','grid_12');
    general_div.appendChild(newdiv);

    var parent_div=document.getElementById(parentdivIdName);
    var headerdiv=document.createElement('div')
    headerdiv.setAttribute('id',parentdivIdName+"-header");
    parent_div.appendChild(headerdiv)
   
    document.getElementById(parentdivIdName+"-header").innerHTML='<p>Class-'+classname+'  <a href="#top"><b>(Back to Top)</b></a></p>';
   
    var starttimes=[];
    for( starttime in info["analytics"][classname])
    {
      starttimes.push(starttime);
    }
    starttimes.sort();

    for(var j=0;j< starttimes.length;j++)
    {
      var starttime=starttimes[j];
      count=count+1;
      var data=new google.visualization.DataTable();
      data.addColumn('string',"level");
      for( test in info["analytics"][classname][starttime])
      {
        types=typeIndex;
        if( info["type"]=="preschool")
          types=preschooltypeIndex;
        for(type in  types)//info["analytics"][classname][test]) 
        {
          data.addColumn('number',info["analytics"][classname][starttime][test][type]["name"]+"("+type+")");
        }  
        if (levels[info["programme"]["pid"]]["type"]=="pdomain")
          plevels=pdomain[levels[info["programme"]["pid"]]["index"]];
        else
          plevels=classdomain[levels[info["programme"]["pid"]]["index"]][classname];
     
        for(text in plevels)
        {
          var rowdata=[];
          rowdata.push(text);
          for(type in  types)
          {
            if(text in info["analytics"][classname][starttime][test][type])
            {
              rowdata.push(info["analytics"][classname][starttime][test][type][text]);
            }
            else
            {
              rowdata.push(0);
            }
          }
          data.addRow(rowdata);
        }       
        var divIdName = divtype+"-analytics-"+classname+"-"+test;
        var newdiv=document.createElement('div');
        newdiv.setAttribute('id',divIdName);
        newdiv.setAttribute('class','grid_'+grid);
        parent_div.appendChild(newdiv);
        var options = {
          title: 'Class-'+classname+" ("+test+")",
          width: width, height: height,
          chartArea: {width:"40%",height:"75%",left:"50"},
          backgroundColor: {stroke:'#000000',strokeWidth:'1',fill:'#F4E193'},
          hAxis:{'title':'% of students','maxValue':100,'minValue':0},
          colors: ['006D2C','31A354','74C476','BAE4B3','EDF8E9']
        };
        if(info["programme"]["pid"]==5 || info["programme"]["pid"]==18)
        {
          options['chartArea']['left']='200';
          options['chartArea']['width']='30%';
        }
        if(info["programme"]["pid"]==6)
        {
          options['chartArea']['left']='325';
         options['chartArea']['width']='30%';
        }
        if(info["programme"]["pid"]==15)
        {
          options['chartArea']['left']='225';
         options['chartArea']['width']='40%';
        }
        var chart = new google.visualization.BarChart(document.getElementById(divIdName));
        chart.draw(data,options);
        if(count==numgraphs)
        {
          var br=document.createElement('div');
          br.setAttribute('style','height:14px');
          br.setAttribute('class','grid_12');
          parent_div.appendChild(br);
          count=0
        }
      }
    }
  }
  analyticsinfo=analyticsinfo+'</ul>'
  document.getElementById(divtype+"-analytics-info").innerHTML=analyticsinfo;

}

function levelbar(divtype,programme,assesstype,category)
{
  var count=0;
  var classcount=0;
  var classnames=[];
  var grid=12;
  for(classname in assesstype[category])
  {
     classnames.push(classname);
     classcount=classcount+1;
  }
  classnames.sort();
  grid=grid/2;
  var width=400;
  var numgraphs=2;
  if(info['type']=='preschool'|| info['type']=='project' || info['type']=='circle' || info['type']=='preschooldistrict')
  {
     width=600;
      numgraphs=1
  }
  if(info["programme"]["pid"]==6 || info["programme"]["pid"]==15)
  {
      width=700;
      numgraphs=1
  }
  var height=300;

  var count=0;
  for(var i = 0; i < classnames.length; i++)
  {
    count=count+1;
    var classname=classnames[i];
    var data=new google.visualization.DataTable();
    data.addColumn('string',"Rung");
    var colors=[]
    for(type in  assesstype[category][classname]) 
    {
       data.addColumn('number',type);
       if(type in color)
       {
         colors.push(color[type]);
       }
    }
    if (levels[info["programme"]["pid"]]["type"]=="pdomain")
      plevels=pdomain[levels[info["programme"]["pid"]]["index"]];
    else
      plevels=classdomain[levels[info["programme"]["pid"]]["index"]][classname];
     
    for(text in plevels)
    {
      var rowdata=[];
      rowdata.push(text);
      for(type in  assesstype[category][classname]) 
      {
        if(text in assesstype[category][classname][type])
        {
          rowdata.push(assesstype[category][classname][type][text]);
        }
        else
        {
          rowdata.push(0);
        }
      }
      data.addRow(rowdata);
    } 
    var general_div=document.getElementById(divtype+"-"+category+"-content");
    
    var divIdName = divtype+"-"+category+"-"+classname;
    var newdiv=document.createElement('div');
    newdiv.setAttribute('id',divIdName);
    newdiv.setAttribute('class','grid_'+grid);
    general_div.appendChild(newdiv);
    var options = {
       title: 'Class-'+classname,
       width: width, height: height,
       chartArea: {width:"50%",height:"75%",left:"100"},
       backgroundColor: {stroke:'#000000',strokeWidth:'1',fill:'#F4E193'},
       hAxis:{'title':'% of students','maxValue':100,'minValue':0},
       colors: ['006D2C','31A354','74C476','BAE4B3','EDF8E9']
    };
    if(info['type']=="preschool"|| info['type']=='project' || info['type']=='circle' || info['type']=='preschooldistrict')
    {
       options['title']=classname
       options['chartArea']['left']='200';
    }
    if(info["programme"]["pid"]==15)
    {
          options['chartArea']['left']='225';
         options['chartArea']['width']='40%';
    }
    if(info["programme"]["pid"]==6)
    {
       options['chartArea']['left']='350';
       options['chartArea']['width']='30%';
    }
    if(colors.length >0 )
    {
      options['colors']=colors;
    } 
    var chart = new google.visualization.BarChart(document.getElementById(divIdName));
    chart.draw(data,options);
    if(count==numgraphs)
    {
      var br=document.createElement('div');
      br.setAttribute('style','height:14px');
      br.setAttribute('class','grid_12');
      general_div.appendChild(br);
      count=0;
    }
  }
}


function progressdata(divtype,pid,programme)
{
  document.getElementById(divtype+"-progress-info").innerHTML='<p align=\"left\"><b>Progress performance for '+info["name"]+'</b></p>';

  var count=0;
  var classcount=0;
  var classnames=[];
  var grid=12;
  for(classname in info["progress"])
  {
     classnames.push(classname);
     classcount=classcount+1;
  }
  classnames.sort();
  grid=grid/2;
  var width=400;
  var numgraphs=2;
  if(info['type']=='preschool'|| info['type']=='project' || info['type']=='circle' || info['type']=='preschooldistrict')
  {
     width=600;
     numgraphs=1
  }
  if(info["programme"]["pid"]==6 || info["programme"]["pid"]==15)
  {
      width=700;
      numgraphs=1
  }
  var height=300;

  var count=0;
  for(var i = 0; i < classnames.length; i++)
  {
    count=count+1;
    var classname=classnames[i];
    var data=new google.visualization.DataTable();
    data.addColumn('string',"level");
    var starttimes=[]
    for(starttime in  info["progress"][classname]) 
    {
       starttimes.push(starttime);
    }

    starttimes.sort();

    for(var j=0; j<starttimes.length;j++)
    {
       starttime=starttimes[j]
       for (type in  info["progress"][classname][starttime])
       {
         data.addColumn('number',type);
       }
    }
    if (levels[info["programme"]["pid"]]["type"]=="pdomain")
      plevels=pdomain[levels[info["programme"]["pid"]]["index"]];
    else
      plevels=classdomain[levels[info["programme"]["pid"]]["index"]][classname];
     
    for(text in plevels)
    {
      var rowdata=[];
      rowdata.push(text);
      for(var j=0; j<starttimes.length;j++)
      {
        starttime=starttimes[j]
        for(type in  info["progress"][classname][starttime]) 
        {
          if(text in info["progress"][classname][starttime][type])
          {
            rowdata.push(info["progress"][classname][starttime][type][text]);
          }
          else
          {
            rowdata.push(0);
          }
        }
      }
      data.addRow(rowdata);
    } 
    var general_div=document.getElementById(divtype+"-progress-content");
    var divIdName = divtype+"-progress-"+classname;
    var newdiv=document.createElement('div');
    newdiv.setAttribute('id',divIdName);
    //newdiv.setAttribute('style','height:300px; width:300px');
    newdiv.setAttribute('class','grid_'+grid);
    general_div.appendChild(newdiv);
    var options = {
       title: 'Class-'+classname,
       width: width, height: height,
       chartArea: {width:"40%",height:"75%",left:"50"},
       backgroundColor: {stroke:'#000000',strokeWidth:'1',fill:'#F4E193'},
       hAxis:{'title':'% of students','maxValue':100,'minValue':0},
       colors: ['006D2C','31A354','74C476','BAE4B3','EDF8E9']
    };
    if(info['type']=="preschool"|| info['type']=='project' || info['type']=='circle' || info['type']=='preschooldistrict')
    {
       options['title']=classname
       options['chartArea']['left']='200';
    }
    if(info["programme"]["pid"]==15)
    {
          options['chartArea']['left']='225';
         options['chartArea']['width']='40%';
    }
    if(info["programme"]["pid"]==6)
    {
       options['chartArea']['left']='350';
       options['chartArea']['width']='30%';
    }
    var chart = new google.visualization.BarChart(document.getElementById(divIdName));
    chart.draw(data,options);
    if(count==numgraphs)
    {
      var br=document.createElement('div');
      br.setAttribute('style','height:14px');
      br.setAttribute('class','grid_12');
      general_div.appendChild(br);
      count=0;
    }

  }
}
