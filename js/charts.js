var previousPoint = null;
var datasets;
var choiceContainer;
var info;


var levels={"Reading":{"0":0,"L":2,"W":4,"S":6,"P":8},"English":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},"NNG":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},"NNG3":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},"Ramanagara-NNG1":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},"Ramanagara-NNG2":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},"Anganwadi":{"General awareness":0,"Gross motor":1,"Fine motor":2,"Language":3,"Intellectual":4,"Socio-emotional":5,"Pre-academic":6},"Target NNG":{"Rung1":0,"Rung2":1,"Rung3":2,"Rung4":3,"Rung5":4},"Target Reading":{"0":0,"L":2,"W":4,"S":6,"P":8}};

var timeLabel= {"1":{"Pre test":0,"Post test":4},"2":{"20th day test":0,"60th day test":4},"3":{"20th day test":0,"60th day test":4},"4":{"Pre test":0,"Post test":4},"5":{"Baseline":0,"15th day test":4,"30th day test":8,"45th day test":12},"6":{"Pre test":0,"Post test":4},"7":{"Pre test":0,"Mid test":4,"Post test":8},"8":{"Pre test":0,"Post test":4},"9":{"Pre test":0,"Post test":4},"10":{"Pre test":0,"Post test":4},"11":{"NNG2":4},"12":{"Reading":4}};

var color={"0":"red","O":"red","L":"orange","W":"yellow","S":"blue","P":"green","Boys":"blue","Girls":"pink"};

var typeIndex={"District":0,"Block":1,"Cluster":2,"School":3};

function initCap(str)
{
  str = str.substring(0,1).toUpperCase() + str.substring(1,str.length).toLowerCase();
 return str;
}

function initialise(data)
{
   info= data;
   info["name"]=info["name"].toUpperCase();
   if( info["programme"]["name"] == "Anganwadi" )
   {
      chartPreSchoolData(info["programme"]["pid"],info["programme"]["name"]);

   }
   else
   { 
     if( info["type"] == "school" )
     {
       chartData(info["programme"]["pid"],info["programme"]["name"]);
     }
     else
     {
       chartBoundaryData(info["programme"]["pid"],info["programme"]["name"]);
     }
   }
}

function chartPreSchoolData(pid,programme)
{
  document.getElementById("preschool").style.display="inline"
  document.getElementById("school").style.display="none"
  document.getElementById("boundary").style.display="none"
  YUI().use('tabview',function(Y){
    var tabview = new Y.TabView({
      srcNode: '#preschool'
    });
    tabview.render();
  })
  enrollment("preschool",pid,programme);
  baselinepreschooldata(programme);
  preschoolprogressdata(pid,programme);
}


function chartData(pid,programme)
{
  if( pid !=11 && pid !=12)
  {
    document.getElementById("school-progress-tab").style.display="inline-block"
  }
  document.getElementById("school").style.display="inline"
  document.getElementById("preschool").style.display="none"
  document.getElementById("boundary").style.display="none"
  YUI().use('tabview',function(Y){
    var tabview = new Y.TabView({
      srcNode: '#school'
    });
    tabview.render();
  })
  enrollment("school",pid,programme);
  baselinedata("school",programme);
  if( pid != 11 && pid!=12)
    progressdata("school",pid,programme); //no progress data for target
  analyticsdata("school",programme);
}

function chartBoundaryData(pid,programme)
{
  document.getElementById("boundary").style.display="inline"
  document.getElementById("preschool").style.display="none"
  document.getElementById("school").style.display="none"
  YUI().use('tabview',function(Y){
    var tabview = new Y.TabView({
      srcNode: '#boundary'
    });
    tabview.render();
  })
  enrollment("boundary",pid,programme);
  baselinedata("boundary",programme);
  progressdata("boundary",pid,programme);
}


function enrollment(schooltype,pid,programme)
{
  syear = Number(info["programme"]["year"])
  eyear = syear+1
  tablecontent=""
  if(pid=="5" || pid=="6" || pid=="7" || pid=="12")
  {
    tablecontent='<br><b>'+programme+' Programmes enrollment data for '+info["name"]+'('+initCap(info["type"])+') in '+syear+'-'+eyear+':-</b><br><table class=\"chart-table\" width=\"350\" border=\"1\" style=\"border-width:1px; border-style:dotted; border-color:#CCCCCC;\"><tr><td>Num of Boys:</td><td>'+info["Boys"]+'</td></tr><tr><td>Num of Girls:</td><td>'+info["Girls"]+'</td></tr></table><br><hr/><br>The <a href=\"/text/reading\">Reading program</a> measures the competency of a child using the following levels:<br><ul><li>0:- Child not able to read</li><li>L:- Child able to read letters</li><li>W:- Child able to read words</li><li>S:- Child able to read sentences</li><li>P:- Child able te read Paragaphs</li></ul>'
  }
  if(pid=="2" || pid=="3" || pid=="4" || pid=="9" || pid=="10"|| pid=="11")
  {
    tablecontent='<br><b>'+programme+' Programmes enrollment data for '+info["name"]+' ('+initCap(info["type"])+') in '+syear+'-'+eyear+':-</b><br><table class=\"chart-table\" width=\"350\" border=\"1\" style=\"border-width:1px; border-style:dotted; border-color:#CCCCCC;\"><tr><td>Num of Boys:</td><td>'+info["Boys"]+'</td></tr><tr><td>Num of Girls:</td><td>'+info["Girls"]+'</td></tr></table><br><hr/><br>The <a href=\"/text/maths\">Math program</a> measures the competency of a child using the following levels:<br><ul><li>Rung1:- 0-20</li><li>Rung2:- 21-40 </li><li>Rung3: -41-60 </li><li>Rung4:- 61-80 </li><li>Rung5:- 81-100</li></ul>'
  }
  if(pid=="8")
  {
    tablecontent='<br><b>English Programmes enrollment data for '+info["name"]+' ('+initCap(info["type"])+') in '+syear+'-'+eyear+':-</b><br><table class=\"chart-table\" width=\"350\" border=\"1\" style=\"border-width:1px; border-style:dotted; border-color:#CCCCCC;\"><tr><td>Num of Boys:</td><td>'+info["Boys"]+'</td></tr><tr><td>Num of Girls:</td><td>'+info["Girls"]+'</td></tr></table><br><hr/><br>The <a href=\"/text/english\">English program</a> measures the competency of a child using the following levels:<br><ul><li>Rung1:- 0-20</li><li>Rung2:- 21-40 </li><li>Rung3: -41-60 </li><li>Rung4:- 61-80 </li><li>Rung5:- 81-100</li></ul>'
  }
  if(pid=="1")
  {
    tablecontent='<br><b>Anganwadi Programmes enrollment data for '+info["name"]+' ('+initCap(info["type"])+') in '+syear+'-'+eyear+':-</b><br><table class=\"chart-table\" width=\"350\" border=\"1\" style=\"border-width:1px; border-style:dotted; border-color:#CCCCCC;\"><tr><td>Num of Boys:</td><td>'+info["Boys"]+'</td></tr><tr><td>Num of Girls:</td><td>'+info["Girls"]+'</td></tr></table><br><hr/><br>The <a href=\"/text/preschool\">Anganwadi program</a> measures the competency of a child using the following levels:<br><ul><li>General awareness</li><li>Gross Motor</li><li>Fine Motor</li><li>Language</li><li>Intellectual</li><li>Socio-emotional</li><li>Pre-academic</li></ul>'
  }
  document.getElementById(schooltype+"-enrollment").innerHTML= tablecontent;  
}

function baselinepreschooldata(programme)
{
   preschoollevelbar(programme,info["baseline"],"gender");
   preschoollevelbar(programme,info["baseline"],"mt");
}


function baselinedata(divtype,programme)
{
   levelbar(divtype,programme,info["baseline"],"gender");
   levelbar(divtype,programme,info["baseline"],"mt");
   levelbar(divtype,programme,info["baseline"],"class");
   basegeneral(divtype,programme);
}

function basegeneral(type,programme)
{
   var datageneral=[]

   for(text in levels[programme])
   {
     if(text in info["assessPerText"])
     {
       if (text in color)
       {
         datageneral.push({label:text,data:info["assessPerText"][text],color:color[text]})
       }
       else
       {
         datageneral.push({label:text,data:info["assessPerText"][text]})
       }
     }
     else
     {
       datageneral.push({label:text,data:0,color:color[text]})
     }
   }
   $.plot(document.getElementById(type+"-general-content"),datageneral,
    {
      series: {
        pie: { 
          show: true
	}
      },
      legend:{
        show:false
      }
    });
}


function analyticsdata(divtype,programme)
{
  var divs="";
  var links="";
  var count=1;
  var width="400px";
  var numAssessments = info["analytics"].length;
  var legendclass="legend";
  for( num in info["analytics"])
  {
    for(category in info["analytics"][num])
    {
      var pagebreak=''
      if( count%2 == 1 )
      {
        classtype="leftContent";
      }
      else
      {
        classtype="rightContent";
      }
      if(numAssessments == 1)
      {
        classtype="centerContent";
        width="700px";
        legendclass="centerLegend";
      }
      if( count%3 == 0 )
      {
        pagebreak='<div class="\midcontent\"><p align=\"center\"><a href=\"#top\">Back to Top</a></p></div>';
      }
      links = links+'<li><a href=\"#'+divtype+'-analytics-'+category+'\">'+category+'</a></li><br>'
      divs=divs+pagebreak+'<div id=\"'+divtype+'-analytics-'+category+'\" class=\"'+classtype+'\"><p align=\"left\"><b>'+category+'</b></p><div id=\"'+divtype+'-'+category+'-content\" class=\"leftside\"  style=\"height:300px; width:'+width+'\"></div><div id=\"'+divtype+'-'+category+'-legend\" class=\"rightside\">Legend<div id=\"'+divtype+'-'+category+'-legend-content\" class=\"'+legendclass+'\"></div></div></div>'
      count=count+1;
    }
  }
  document.getElementById(divtype+"-analytics").style.height=(count/2)*500+100;
  document.getElementById(divtype+"-analytics").innerHTML='<ul>'+links+'</ul><br><br><hr/>'+divs
    
  for( num in info["analytics"])
  {
  for( category in info["analytics"][num])
  {
    analyticslevelbar(divtype,programme,info["analytics"][num],category)
  }
 }
}

function preschoollevelbar(programme,assesstype,category)
{
  var data=[];
  var y_axis=[];
  count=1;
  var align=["left","right","center"];
  var assessmenttype=[]
  assessmenttype=getSortedCategory(assesstype[category]);
  for( index in assessmenttype)
  {
    var type=assessmenttype[index];
    var dataplot=[];
    for( text in assesstype[category][type])
    {   
        var datapoint =[];
        datapoint.push(assesstype[category][type][text]);
        datapoint.push(levels[programme][text]);
        dataplot.push(datapoint);
    }
    data.push({label:type,data:dataplot,bars:{barWidth:0.22, show:true,horizontal:true,align:align[count-1]},color:color[type]});
    count=count+1;
  }
  for( num in levels[programme])
  {
    var y_tick=[];
    y_tick.push(levels[programme][num]); 
    y_tick.push(num);
    y_axis.push(y_tick);
  }
  id = "preschool-"+category+"-content";
  $.plot(document.getElementById(id), data,{yaxis:{ticks:y_axis,autoscaleMargin:0.0},xaxis:{autoscaleMargin:0.0},legend:{show:true,container:document.getElementById("preschool-"+category+"-legend-content")}});

}

function getSortedCategory(list)
{
 var catlist=[];
 var otherpresent=0;
 for( type in list )
 {
   if( type == "Other")
   {
     otherpresent=1;
   }
   else
   {
     catlist.push(type);
   }
 }
 catlist.sort();
 if( otherpresent == 1)
   catlist.push("Other");
 return catlist;
}


function levelbar(divtype,programme,assesstype,category)
{
  var data=[];
  var x_axis=[];
  count=1;
  var assessmenttype=[]
  assessmenttype=getSortedCategory(assesstype[category]);
  for( index in assessmenttype)
  {
    var type=assessmenttype[index];
    var dataplot=[];
    for( text in assesstype[category][type])
    {   
        var datapoint =[];
        datapoint.push(levels[programme][text]);
        datapoint.push(assesstype[category][type][text]);
        dataplot.push(datapoint);
    }
    data.push({label:type,data:dataplot,bars:{barWidth:0.22, order:count,show:true},color:color[type]});
    count=count+1;
  }
  for( num in levels[programme])
  {
    var x_tick=[];
    x_tick.push(levels[programme][num]); 
    x_tick.push(num);
    x_axis.push(x_tick);
  }
  id = divtype+"-"+category+"-content";
  $.plot(document.getElementById(id), data,{xaxis:{ticks:x_axis,autoscaleMargin:0.0},yaxis:{autoscaleMargin:0.0},legend:{show:true,container:document.getElementById(divtype+"-"+category+"-legend-content")}});

}

function getType(type)
{
  var temp = type.split("(");
  var index = temp.length - 1;
  var btype=type.split("(")[index].split(")")[0];
  return btype;
}


function analyticslevelbar(divtype,programme,assesstype,category)
{
  var data=[];
  var x_axis=[];
  count=1;
   
  var boundary=[];
  for( type in assesstype[category])
  {
    boundary[typeIndex[getType(type)]]=type;
  }
  
  for( bval in boundary)
  {
    type = boundary[bval];
    var dataplot=[];
    for( text in assesstype[category][type])
    {   
        var datapoint =[];
        datapoint.push(levels[programme][text]);
        datapoint.push(assesstype[category][type][text]);
        dataplot.push(datapoint);
    }
    data.push({label:type,data:dataplot,bars:{barWidth:0.22, order:count,show:true},color:color[type]});
    count=count+1;
  }
  for( num in levels[programme])
  {
    var x_tick=[];
    x_tick.push(levels[programme][num]); 
    x_tick.push(num);
    x_axis.push(x_tick);
  }
  id = divtype+"-"+category+"-content";
  $.plot(document.getElementById(id), data,{xaxis:{ticks:x_axis,autoscaleMargin:0.0},yaxis:{autoscaleMargin:0.0},legend:{show:true,container:document.getElementById(divtype+"-"+category+"-legend-content")}});

}

function preschoolprogressdata(pid,programme)
{
  document.getElementById("preschool-progress").innerHTML='<p align=\"left\"><b>Progress performance for '+info["name"]+' (Average Scores)</b></p><div id=\"preschool-progress-content\" class=\"leftside\" style=\"height:400px; width:700px\"></div><br><br><div id=\"preschool-progress-legend\" class=\"rightside\">Legend<div id=\"preschool-progress-legend-content\" class=\"centerLegend\"></div></div>'

  var data=[];
  var y_axis=[];
  count=1;
  var align=["left","right","center"];
  for( type in info["progress"])
  {
    var dataplot=[];
    for( text in info["progress"][type])
    {   
        var datapoint =[];
        datapoint.push(info["progress"][type][text]);
        datapoint.push(levels[programme][text]);
        dataplot.push(datapoint);
    }
    data.push({label:type,data:dataplot,bars:{barWidth:0.22, show:true,horizontal:true,align:align[count-1]},color:color[type]});
    count=count+1;
  }
  for( num in levels[programme])
  {
    var y_tick=[];
    y_tick.push(levels[programme][num]); 
    y_tick.push(num);
    y_axis.push(y_tick);
  }
  id = "preschool-progress-content";
  $.plot(document.getElementById(id), data,{yaxis:{ticks:y_axis,autoscaleMargin:0.0},xaxis:{min:0,autoscaleMargin:0.0},legend:{show:true,container:document.getElementById("preschool-progress-legend-content")}});

}

function progressdata(divtype,pid,programme)
{
  document.getElementById(divtype+"-progress").innerHTML='<p align=\"left\"><b>Progress performance for '+info["name"]+'</b></p><div id=\"'+divtype+'-progress-content\" class=\"leftside\" style=\"height:400px; width:700px\"></div><br><br><div id=\"'+divtype+'-progress-legend\" class=\"rightside\">Legend<div id=\"'+divtype+'-progress-legend-content\" class=\"centerLegend\"></div></div>'

  var data=[];
  //var data1=[];
  var x_axis=[];
  count=1;
  //for( type in info["progress"])
  for( type in levels[programme])
  {
    var dataplot=[];
    if( type in info["progress"])
    {
    for( text in info["progress"][type])
    {   
        var datapoint =[];
        datapoint.push(timeLabel[pid][text]);
        datapoint.push(info["progress"][type][text]);
        dataplot.push(datapoint);
    }
    }
    else
    {
      for( text in info["progress"][type])
      {   
        var datapoint =[];
        datapoint.push(timeLabel[pid][text]);
        datapoint.push(0);
        dataplot.push(datapoint);
      }
    }
    if (type=="0")
    {
      type="O"
    }
    data.push({label:type,data:dataplot,bars:{barWidth:0.4, order:count,show:true},color:color[type]});
    //data1.push({label:type,data:dataplot,lines:{show:true}});
    count=count+1;
  }
  for( num in timeLabel[pid])
  {
    var x_tick=[];
    x_tick.push(timeLabel[pid][num]); 
    x_tick.push(num);
    x_axis.push(x_tick);
  }
  id = divtype+"-progress"+"-content";
  $.plot(document.getElementById(id), data,{xaxis:{ticks:x_axis},legend:{show:true,container:document.getElementById(divtype+"-progress-legend-content")}});

}
