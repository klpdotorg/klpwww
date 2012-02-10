var info;
var map;
var type;
var image={"school":"school.png","preschool":"preschool.png"}

// Load the Visualization API and the piechart package.
//google.load('visualization', '1', {'packages':['table','piechart']});

if (!Array.prototype.indexOf)
{
  Array.prototype.indexOf = function(elt /*, from*/)
  {
    var len = this.length;

    var from = Number(arguments[1]) || 0;
    from = (from < 0)
         ? Math.ceil(from)
         : Math.floor(from);
    if (from < 0)
      from += len;

    for (; from < len; from++)
    {
      if (from in this &&
          this[from] === elt)
        return from;
    }
    return -1;
  };
}


function initialise(data)
{
  info=data;
  //alert(document.location.href);
  //alert(document.location.host);
  info["name"]=info["name"].toUpperCase();
  if (info["type"]==2)
  {
    type="preschool";
    document.getElementById("school_info_heading").innerHTML = "Preschool Information";
    document.getElementById("school_hier_heading").innerHTML = "Preschool District Information";
    document.getElementById("school_visits_heading").innerHTML = "Preschool Visits";
    document.getElementById("sys_data_heading").innerHTML = "Information from Preschool Visits";
    document.title = "Preschool Information";
  }
  else
  {
    type="school";
    document.getElementById("school_info_heading").innerHTML = "School Information";
    document.getElementById("school_hier_heading").innerHTML = "School District Information";
    document.getElementById("school_visits_heading").innerHTML = "School Visits";
    document.getElementById("sys_data_heading").innerHTML = "Information from School Visits";
    document.title = "School Information";
  }

  document.getElementById("sys_comments_heading").innerHTML = "Visitors' Comments";
  document.getElementById("student_info_heading").innerHTML = "Student Information";
  document.getElementById("const_info_heading").innerHTML = "Constituency Information";
  document.getElementById("assmt_info_heading").innerHTML = "Programme Information";
  var latlng = new google.maps.LatLng(info["lat"],info["lon"]);
  var myOptions = {
      zoom: 14,
      center: latlng,
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      disableDoubleClickZoom:false
  };
  map = new google.maps.Map(document.getElementById("map"),myOptions);
  var marker = new google.maps.Marker({
        position: latlng,
        title:info["name"],
        icon:"/images/"+image[type]
      });
                  
  marker.setMap(map);  
  
  document.getElementById("school_name").innerHTML= info["name"];
  address = '<div class="div-table">'
  add = '<div class="div-table">'

  if (info["address"] != "-")
  {
        add = add + '<div class="div-table-row">' +
                        '<div id="div-col-90width" class="div-table-col" >District</div>' +
                        '<div class="div-table-col">:' + info["b"] +'</div>' +
                        '</div>' 
        
        add = add + '<div class="div-table-row">' 
        if(info["type"] != 2)
        {
          add = add + '<div id="div-col-90width" class="div-table-col" >Block</div>' 
        }else{
          add = add + '<div id="div-col-90width" class="div-table-col" >Project</div>' 
        }
        add = add + '<div class="div-table-col">:' + info["b1"] +'</div>' +
                            '</div>'


        add = add + '<div class="div-table-row">' 
        if(info["type"] != 2)
        {
          add = add + '<div id="div-col-90width" class="div-table-col" >Cluster</div>' 
        }else{
          add = add + '<div id="div-col-90width" class="div-table-col" >Circle</div>' 
        }
        add = add + '<div class="div-table-col">:' + info["b2"] +'</div>' +
                            '</div>'

        address = address + '<div class="div-table-row">' + 
                            '<div id="div-col-90width" class="div-table-col" >Address</div>' +
                            '<div class="div-table-col">:'+info["address"]+ "-" + info["postcode"]+'</div></div>' 
        address = address + '<div class="div-table-row">' +
                            '<div id="div-col-90width" class="div-table-col" >Landmark</div>' +
                            '<div class="div-table-col">:'+ info["landmark_1"] + '</div></div>' 
        address = address + '<div class="div-table-row">' + 
                            '<div id="div-col-90width" class="div-table-col" >Identifiers</div>' +
                            '<div class="div-table-col">:'+info["inst_id_1"] + ',' + info["inst_id_2"] + '</div></div>' 
        address = address + '<div class="div-table-row">' + 
                            '<div id="div-col-90width" class="div-table-col" >Buses</div>' +
                            '<div class="div-table-col">:'+info["bus_no"] + '</div></div>' 
  }else{
        address = address + '<div class="div-table-row">' + 
                            '<div id="div-col-90width" class="div-table-col" >Address</div>' +
                            '<div class="div-table-col">:'+info["address"]+'</div></div>' 
  }
        address=address+'</div>'
        add=add+'</div>'
        document.getElementById("school_geo").innerHTML= address;
        document.getElementById("school_hier").innerHTML= add;


  infotable = '<div class="div-table">'
  if(info["status"] == 0){
    if(info["type"] != 2) {
      infotable = infotable + '<div class="div-table-row"><div class="div-table-col">' 
      infotable = infotable + 'This School is reported to have been CLOSED.</div></div>' 
    } else {
      infotable = infotable + '<div class="div-table-row"><div class="div-table-col">' 
      infotable = infotable + 'This Preschool is reported to have been CLOSED.</div></div>' 
    }      
  }
  infotable = infotable + '<div class="div-table-row">' + 
                          '<div id="div-col-125width" class="div-table-col">Category</div>' 
  infotable = infotable + '<div class="div-table-col">:'+info["cat"]+'</div></div>' 
  if(info["type"] !=2)
  {
    infotable = infotable + '<div class="div-table-row">' + 
                            '<div id="div-col-125width" class="div-table-col">Gender</div>' 
    infotable = infotable + '<div class="div-table-col">:'+info["sex"]+'</div></div>' 
    infotable = infotable + '<div class="div-table-row">' +
                            '<div id="div-col-125width" class="div-table-col">Medium of Instruction</div>' 
    infotable = infotable + '<div class="div-table-col">:'+info["moi"]+'</div></div>' 
  }
  infotable = infotable + '</div>'
	document.getElementById("school_info").innerHTML= infotable;

  var data = new google.visualization.DataTable();
  data.addColumn('string', "Gender");
  data.addColumn('number', "Count");
  data.addRows([
    ['Boys' + ' (' + info["numBoys"] + ')', info["numBoys"]],
    ['Girls' + ' (' + info["numGirls"] + ')', info["numGirls"]],
    //[Math.round(info["numGirls"]/info["numStudents"]*100) + '% are Girls', info["numGirls"]],
  ]);
  //var table2 = new google.visualization.Table(document.getElementById('gendsch_tb'));
  //table2.draw(data,{width:350, height: 120});
  //var chart1 = new BarsOfStuff(document.getElementById('student_gend'));
  //chart1.draw(data, {width:400, height: 240, title:"Gender Profile"});
  var chart1 = new google.visualization.PieChart(document.getElementById('student_gend'));
  chart1.draw(data, {width: 450, height: 260, title:  'Gender Profile', backgroundColor: 'transparent', pieSliceText:'label', colors: ['D78103','F49406','E35804','F7AA33','FBBC59']});
 
  var data = new google.visualization.DataTable();
  data.addColumn('string', 'Language');
  data.addColumn('number', 'Number of Students');
  for (var key in info["school_mt_tb"]){
    data.addRow([key + ' (' + info["school_mt_tb"][key] + ')', parseInt(info["school_mt_tb"][key])]);
  }
  //var table = new google.visualization.Table(document.getElementById('mtsch_tb'));
  //table.draw(data,{width: 400});
  var chart2 = new google.visualization.PieChart(document.getElementById('student_mt'));
  chart2.draw(data, {width: 450, height: 260, title:  'Mother Tongue Profile', backgroundColor: 'transparent', pieSliceText:'label', colors: ['D78103','F49406','E35804','F7AA33','FBBC59']});

  systable = '<div class="div-table">' +
             '<div class="div-table-row">No. of Visits:' + info["syscount"] + '</div>';
  systable = systable+ 'If you have visited this school, please' + '<div class="div-table-row"><b><a href=\"javascript:void(0);\" onclick=window.open("../../shareyourstory'+type+'?type='+type+'?id='+info["id"]+'","_blank") style="color:#43AD2F">share your experience </a></b>here.</div>';
            if( info["syscount"]>0)
            {
              systable = systable+'<div class="div-table-row">Dates of Visit</div><div class="div-table-row"><b>';
              for(entry in info["sysdate"])
              {
                date = info["sysdate"][entry];
                if(date !="") 
                  systable = systable + date + '&nbsp;&nbsp;'
              }
              systable = systable + '</b></div>';
            }
  document.getElementById("sys_info").innerHTML= systable;

  if(info["images"])
  {
    school_pics= '<a href=\"' + info["image_dir"] + info["images"][0]+'\" rel=\"lightbox['+ info['id']+']\"><img class="album" src=\"' + info["image_dir"] + info["images"][0]+'\"></img></a>'
    for(i=1;i<info["images"].length;i++)
    {
      school_pics = school_pics+'<a href=\"' + info["image_dir"] + info["images"][i] +'\" rel=\"lightbox['+ info['id']+']\"></a>' 
    }
  }else{
    school_pics='This school does not have a picture album yet.<br/><br/>'
  }
  document.getElementById("school_pics").innerHTML=school_pics;
  //alert('mla' in info)
 
  const_table = '<div class="div-table">' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MLA Constituency</div>' + 
                '<div class="div-table-col">:' + 'mla' in info == false ? '&nbsp;&nbsp;Not Available': info['mla'].toUpperCase() + '</div>' ;
  if ('mla' in info){
    const_table = const_table + '<div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MLA Details</div>' + 
                '<div class="div-table-col">:' + info['mlaname'].toUpperCase() + '</div><div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MP Constituency</div>' + 
                '<div class="div-table-col">:' + info['mp'].toUpperCase() + '</div><div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MP Details</div>' + 
                '<div class="div-table-col">:' + info['mpname'].toUpperCase() + '</div>' +
                '</div></div>';
    report_links = '<a href="" onclick="javascript:popwindow(\'/listFiles/3|'+info['mp'] +'|'+info['mla'] + '\')" style="color:#43AD2F">Please find Constituency Reports here.</a>';
  }
  else{
    const_table = const_table + '</div>';
    report_links = '';
  }
  document.getElementById("school_const").innerHTML = const_table;
  document.getElementById("reportlinks").innerHTML = report_links;
  if(info.assessments) {
    var assessArr = info.assessments.split(",");
    var assdict = {};
    var asskeys = [];
    var assessmentInfo = '';
    var assessment = []; 
    for( num in assessArr)
    {
       assessment = assessArr[num].split("|");
       assdict[assessment[1]+'-'+assessment[2]] = [assessment[3]+'-'+assessment[0],assessment[2]];
       asskeys.push(assessment[1]+'-'+assessment[2]);
    }
    asskeys.sort();
    var asstext = ''; 
    var asstype = '';
    var each = '';
    for(var i = 0; i< asskeys.length; i++)
    {
       each = asskeys[i];
       asstext = assdict[each][0] + ' (' + each.split("-")[0] + ')';
       asstype = assdict[each][1];
       assessmentInfo = assessmentInfo+'<a href=\"javascript:void(0);\" onclick=window.open("../../assessment/'+type+'/'+asstype+'/'+info['id']+'","_blank")><span style="color:#43AD2F">'+asstext+'</span></a><br/><br/>'
    }
  } else {
    assessmentInfo = 'No Programmes\' information yet.'
  }

  document.getElementById("assessment_info").innerHTML = '<div class="div-table">' +
                '<div class="div-table-row">' + assessmentInfo + '</div><div>' +
                '</div>';

  if(info["syscomment"]){
    var syscomm = '<div class="div-table">';
    for(entry in info["syscomment"]){
      syscomm = syscomm + '<div class="div-table-row">\"' + info["syscomment"][entry] + '\"</div>';}
    syscomm = syscomm + '</div>'
  } else {
    syscomm = "<div class='div-table'><div class='div-table-row'>No remarks yet.</div></div>"
  } 
  document.getElementById("sys_comments").innerHTML = syscomm;


  if(info["sysdata"]){
    var sysdata = '<div class="div-table">';
    sysdata = sysdata + '<div class="div-table-caption">This data is gathered from vistors sharing their experiences. It indicates whether or not the school has facilities under the headings below: </div>'
    for(entry in info["sysdata"]){
      tdata = info["sysdata"][entry].split('|');
      sysdata = sysdata + '<div class="div-table-row" id="div-row-border"><div class="div-table-col" id="div-col-350width">' + tdata[0] + '</div>'
                      + '<div class="div-table-col">:' + tdata[1] + '</div></div>'
    }
    sysdata = sysdata + '</div>'
  } else {
    sysdata = "<div class='div-table'><div class='div-table-row'>No information available from visits yet.</div></div>"
  }
  document.getElementById("sys_data").innerHTML = sysdata;
    
  
}
