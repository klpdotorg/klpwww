var previousPoint = null;
var datasets;
var choiceContainer;
var info;

google.load('visualization', '1', {'packages':['corechart','table','imagechart']});

var levels={"Reading":{"0":0,"L":2,"W":4,"S":6,"P":8},
            "NNG":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},
            "Anganwadi":{"General awareness":0,"Gross motor":1,"Fine motor":2,"Language":3,"Intellectual":4,"Socio-emotional":5,"Pre-academic":6},
            "English":{"Can Read":0,"Cannot Read":1,"Can Write":2,"Cannot Write":3,"Can Speak":4,"Cannot Speak":5},
            "Reading-Ramnagara":{"0":0,"L":2,"W":4,"S":6,"P":8},
            "Reading-Dharwad":{"0":0,"L":2,"W":4,"S":6,"P":8},
            "NNG3":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},
            "Ramanagara-NNG1":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},
            "Ramanagara-NNG2":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},
            "Target NNG":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},
            "Target Reading":{"0":0,"L":2,"W":4,"S":6,"P":8},
            "NNGSupport":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},
            "NNG10by10":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},
            "Akshara English":{"Can Read":0,"Cannot Read":1,"Can Write":2,"Cannot Write":3,"Can Speak":4,"Cannot Speak":5},
            "Class1-CarryThrough":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},
            "Third Party Anganwadi":{"General awareness":0,"Gross motor":1,"Fine motor":2,"Language":3,"Intellectual":4,"Socio-emotional":5,"Pre-academic":6},
            };

var color={"0":"red","O":"red","L":"orange","W":"yellow","S":"blue","P":"green","Boys":"blue","Girls":"pink"};

var typeIndex={"District":0,"Block":1,"Cluster":2,"School":3};


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
   if( info["type"] == "school" )//show analytics
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
  if( pid != 12 && pid!=13 && pid!=17 && pid!=20)
    progressdata("school",pid,programme); //no progress data for target
  if( info["type"]=="school")
  {
    analyticsdata("school",programme);
  }
}

function enrollment(schooltype,pid,programme)
{
  syear = Number(info["programme"]["year"])
  eyear = syear+1
  tablecontent=""
  if(pid=="1" || pid=="4" || pid=="7" || pid=="8" ||pid=="13" || pid=="19")
  {
    tablecontent='<br><b>'+programme+' Programmes enrollment data for '+info["name"]+'('+initCap(info["type"])+') in '+syear+'-'+eyear+':-</b><br><table class=\"chart-table\" width=\"350\" border=\"1\" style=\"border-width:1px; border-style:dotted; border-color:#CCCCCC;\"><tr><td>Num of Boys:</td><td>'+info["Boys"]+'</td></tr><tr><td>Num of Girls:</td><td>'+info["Girls"]+'</td></tr></table><br><hr/><br>The <a href=\"/text/reading\">Reading program</a> measures the competency of a child using the following levels:<br><ul><li>0:- Child not able to read</li><li>L:- Child able to read letters</li><li>W:- Child able to read words</li><li>S:- Child able to read sentences</li><li>P:- Child able te read Paragaphs</li></ul>'
  }
  if(pid=="2" || pid=="3" || pid=="9" || pid=="10"|| pid=="11" || pid=="12" || pid=="14" || pid=="16")
  {
    tablecontent='<br><b>'+programme+' Programmes enrollment data for '+info["name"]+' ('+initCap(info["type"])+') in '+syear+'-'+eyear+':-</b><br><table class=\"chart-table\" width=\"350\" border=\"1\" style=\"border-width:1px; border-style:dotted; border-color:#CCCCCC;\"><tr><td>Num of Boys:</td><td>'+info["Boys"]+'</td></tr><tr><td>Num of Girls:</td><td>'+info["Girls"]+'</td></tr></table><br><hr/><br>The <a href=\"/text/maths\">Math program</a> measures the competency of a child using the following levels:<br><ul><li>Rung1:- 0-20</li><li>Rung2:- 21-40 </li><li>Rung3: -41-60 </li><li>Rung4:- 61-80 </li><li>Rung5:- 81-100</li></ul>'
  }
  if(pid=="6" || pid=="15")
  {
    tablecontent='<br><b>English Programmes enrollment data for '+info["name"]+' ('+initCap(info["type"])+') in '+syear+'-'+eyear+':-</b><br><table class=\"chart-table\" width=\"350\" border=\"1\" style=\"border-width:1px; border-style:dotted; border-color:#CCCCCC;\"><tr><td>Num of Boys:</td><td>'+info["Boys"]+'</td></tr><tr><td>Num of Girls:</td><td>'+info["Girls"]+'</td></tr></table><br><hr/><br>The <a href=\"/text/english\">English program</a> measures the competency of a child using the following levels:<br><ul><li>Whether the child can Read</li><li>Whether the child can Write</li><li>Whether the child can Speak</li></ul>'
  }
  if(pid=="5" || pid=="18")
  {
    tablecontent='<br><b>Anganwadi Programmes enrollment data for '+info["name"]+' ('+initCap(info["type"])+') in '+syear+'-'+eyear+':-</b><br><table class=\"chart-table\" width=\"350\" border=\"1\" style=\"border-width:1px; border-style:dotted; border-color:#CCCCCC;\"><tr><td>Num of Boys:</td><td>'+info["Boys"]+'</td></tr><tr><td>Num of Girls:</td><td>'+info["Girls"]+'</td></tr></table><br><hr/><br>The <a href=\"/text/preschool\">Anganwadi program</a> measures the competency of a child using the following levels:<br><ul><li>General awareness</li><li>Gross Motor</li><li>Fine Motor</li><li>Language</li><li>Intellectual</li><li>Socio-emotional</li><li>Pre-academic</li></ul>'
  }
  document.getElementById(schooltype+"-enrollment").innerHTML= tablecontent;  
}

function baselinedata(divtype,programme)
{
   basegeneral(divtype,programme);
   levelbar(divtype,programme,info["baseline"],"gender");
   levelbar(divtype,programme,info["baseline"],"mt");
}

function basegeneral(type,programme)
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
   if(info['type']=='preschool')
   {
      width=600;
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
     for(text in levels[programme])
     {
       if(text in info["assessPerText"][classname])
       {
         data.addRow([text,info["assessPerText"][classname][text]]);
       }
       else
       {
         data.addRow([text,0]);
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
          backgroundColor: {stroke:'#000000',strokeWidth:'1',fill:'#F4E193'}
        };
    if(info['type']=="preschool")
    {
       options['title']='Preschool';
    }
     if(colors.length >0 )
     {
      options['colors']=colors;
     } 
 
    
     var chart = new google.visualization.PieChart(document.getElementById(divIdName));
     chart.draw(data,options);

     if(count==2)
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

  var count=0;
  var analyticsinfo="<ul>"
  for(var i = 0; i < classnames.length; i++)
  {
    var classname=classnames[i];
    analyticsinfo=analyticsinfo+'<li><a href="#'+divtype+"-analytics-class-"+classname+'">Class-'+classname+"</a></li>"
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
   
    document.getElementById(parentdivIdName+"-header").innerHTML='<p>Class-'+classname+'  <a href="#top">(Back to Top)</a></p>';
   
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
        for(type in  typeIndex)//info["analytics"][classname][test]) 
        {
          data.addColumn('number',info["analytics"][classname][starttime][test][type]["name"]+"("+type+")");
        }
        for(text in levels[programme])
        {
          var rowdata=[];
          rowdata.push(text);
          for(type in  info["analytics"][classname][starttime][test]) 
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
          chartArea: {width:"50%",height:"75%",left:"100"},
          backgroundColor: {stroke:'#000000',strokeWidth:'1',fill:'#F4E193'}
        };
        var chart = new google.visualization.BarChart(document.getElementById(divIdName));
        chart.draw(data,options);
        if(count==2)
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
  if(info['type']=='preschool')
  {
     width=600;
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
    for(text in levels[programme])
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
       backgroundColor: {stroke:'#000000',strokeWidth:'1',fill:'#F4E193'}
    };
    if(info['type']=="preschool")
    {
       options['title']='Preschool';
       options['chartArea']['left']='200';
    }
    if(colors.length >0 )
    {
      options['colors']=colors;
    } 
    var chart = new google.visualization.BarChart(document.getElementById(divIdName));
    chart.draw(data,options);
    if(count==2)
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
  if(info['type']=='preschool')
  {
     width=600;
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
    for(text in levels[programme])
    {
      var rowdata=[];
      rowdata.push(text);
      for(starttime in  info["progress"][classname])
      {
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
       chartArea: {width:"50%",height:"75%",left:"100"},
       backgroundColor: {stroke:'#000000',strokeWidth:'1',fill:'#F4E193'}
    };
    if(info['type']=="preschool")
    {
       options['title']='Preschool';
       options['chartArea']['left']='200';
    }
    var chart = new google.visualization.BarChart(document.getElementById(divIdName));
    chart.draw(data,options);
    if(count==2)
    {
      var br=document.createElement('div');
      br.setAttribute('style','height:14px');
      br.setAttribute('class','grid_12');
      general_div.appendChild(br);
      count=0;
    }

  }
}
