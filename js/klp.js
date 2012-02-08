//Globals
var map;
var lastWindow;
var geocoder;
var districtMarkers ={};
var preschooldistrictMarkers ={};
var blockMarkers={};
var clusterMarkers={};
var schoolMarkers={};
var preschoolMarkers={};
var projectMarkers={};
var circleMarkers={};
var types = ["district","block","cluster","school","preschooldistrict","project","circle","preschool"];
var zoomInfo = {"district":7,"preschooldistrict":7,"block":9,"cluster":11,"school":13,"project":9,"circle":11,"preschool":13};
var images = {"district":"district.png","preschooldistrict":"district.png","block":"block.png","cluster":"cluster.png","circle":"circle.png","project":"project.png","school":"school.png","preschool":"preschool.png"};
var center={"lat":12.971606,"lon":77.594376};
var defaultid="8877";
var childInfo=[];
var distanceWidget = null;


function initializesys(){
  YUI({base: 'yui/build/',
    timeout: 50000}).use("io-base","json-parse",
    function(Y, result) {
      if (!result.success) {
        Y.log('Load failure: ' + result.msg, 'warn', 'program');
      }
      var callback = {
        on: { success: 
          function(id, o) {
            var sysinfo;
            try {  
              sysinfo= Y.JSON.parse(o.responseText);
            } catch (e) {
              Y.log('Could not parse json'+type, 'error', 'sysinfo');
              return;
            }
            document.getElementById("systext").innerHTML='<p>Number of Stories Shared :'+sysinfo["numstories"]+'</p><p>Number of Photos Shared :'+sysinfo["numimages"]+'</p><br><a href="visualization?type=school">Please Share Your Experience</a>';
          },
          failure: function(id, o) {
            Y.log('Could not retrieve sysinfo data ','error','sysinfo');
          }  
        }
      };
      url = "sysinfo";
      var request = Y.io(url, callback);
    });

}


function initialiseSchool(){
  var displayschooldiv="inline";
  var displaypreschooldiv="none";
  var query= window.location.search.substring(1);
  var pos = query.indexOf('=');
  var key = query.substring(0,pos);
  type= query.substring(pos+1);
  if( type=="preschool")
  {
    displayschooldiv="none";
    displaypreschooldiv="inline";
  }
  document.getElementById("schooldiv").style.display=displayschooldiv;
  document.getElementById("preschooldiv").style.display=displaypreschooldiv;
  var latlng = new google.maps.LatLng(center["lat"],center["lon"]);
  //var latlng = new google.maps.LatLng(13.04583,77.62138);
  var myOptions = {
    zoom: 13,
    center: latlng,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    disableDoubleClickZoom:false
  };
  map = new google.maps.Map(document.getElementById("map_canvas"),myOptions);
  geocoder = new google.maps.Geocoder();
  getPoints();

  google.maps.event.addListener(map, 'zoom_changed',zoomChanged);
      
  distanceWidget = new DistanceWidget(map)
  google.maps.event.addListener(distanceWidget, 'distance_changed', function() {
        displayInfo(distanceWidget);
  });
   google.maps.event.addListener(distanceWidget, 'position_changed', function() {
        displayInfo(distanceWidget);
  });

}

function initCap(str)
{
  str = str.substring(0,1).toUpperCase() + str.substring(1,str.length).toLowerCase(); 
 return str; 
} 

function geocode() {
    var address = document.getElementById("address").value;
    geocoder.geocode({
      'address': address,
      'partialmatch': true}, geocodeResult);
}
 
function geocodeResult(results, status) {
    if (status == 'OK' && results.length > 0) {
      map.fitBounds(results[0].geometry.viewport);
      map.setCenter(results[0].geometry.location);
      distanceWidget.set('position', map.getCenter());
      markers = preschoolMarkers;
    for (var p in pointInfo[type]) {
      var point = pointInfo[type][p];
      var pos = new google.maps.LatLng(point.lat, point.lon);
      markers[point.id] = new google.maps.Marker({
        position: pos,
        map: map,
        title: point.name,
        visible:visible,
        icon:"images/"+image
      });
      displayPointInfo(markers[point.id],point.id,point.name,type)
    
    }
    if( type=='district')
      populateDistricts(pointInfo[type]);
    if( type=='preschooldistrict')
      populatePreSchoolDistricts(pointInfo[type]);
  }
}
function closeWindow()
{
  if( typeof(lastWindow) == 'object' )
  {
    lastWindow.close();
  }
}

function zoomChanged()
{
  closeWindow();
  var zoom = map.getZoom();
  if (zoom < zoomInfo["block"] )
  {
     makeVisible(districtMarkers);
     makeVisible(preschooldistrictMarkers);
     makeInvisible(blockMarkers);
     makeInvisible(clusterMarkers);
     makeInvisible(projectMarkers);
     makeInvisible(schoolMarkers);
     makeInvisible(preschoolMarkers);
     makeInvisible(circleMarkers);
   }
   else if (zoom >= zoomInfo["block"] && zoom < zoomInfo["cluster"])
   {
     makeVisible(blockMarkers);
     makeVisible(projectMarkers);
     makeInvisible(clusterMarkers);
     makeInvisible(circleMarkers);
     makeInvisible(districtMarkers);
     makeInvisible(preschooldistrictMarkers);
     makeInvisible(schoolMarkers);
     makeInvisible(preschoolMarkers);
   }
   else if (zoom >= zoomInfo["cluster"] && zoom < zoomInfo["school"])
   {
     makeVisible(clusterMarkers);
     makeVisible(circleMarkers);
     makeInvisible(preschooldistrictMarkers);
     makeInvisible(blockMarkers);
     makeInvisible(schoolMarkers);
     makeInvisible(preschoolMarkers);
   }
   else if (map.getZoom() >= zoomInfo["school"])
   {
     makeVisible(schoolMarkers);
     makeVisible(preschoolMarkers);
     makeInvisible(districtMarkers);
     makeInvisible(preschooldistrictMarkers);
     makeInvisible(blockMarkers);
     makeInvisible(clusterMarkers);
     makeInvisible(projectMarkers);
     makeInvisible(circleMarkers);
   }
}

function makeVisible(markers)
{
  for (m in markers)
  {
    marker = markers[m];
    if (marker.getVisible() == false){
      marker.setVisible(true);
    }
  }
}

function makeInvisible(markers)
{
  for (m in markers)
  {
    marker = markers[m];
    if (marker.getVisible() == true){
      marker.setVisible(false);
    }
  }
}

function getPoints()
{
  YUI({base: 'yui/build/',
    timeout: 50000}).use("io-base","json-parse",
    function(Y, result) {
      if (!result.success) {
        Y.log('Load failure: ' + result.msg, 'warn', 'program');
      }
      var callback = {
        on: { success:
          function(id, o) {
            var points;
            try {
              points= Y.JSON.parse(o.responseText);
            } catch (e) {
              Y.log('Could not parse json', 'error', 'points');
              return;
            }
            plotPoints(points);
          },
          failure: function(id, o) {
            Y.log('Could not retrieve point data ','error','points');
          }
        }
      };
      url = "pointinfo/"
      var request = Y.io(url, callback);
    });
}

function plotPoints(pointInfo)
{
  for( type in pointInfo)
  {
    visible=false;
    zoom =zoomInfo[type];
    var image = images[type];
    currentzoom = map.getZoom();
    if(currentzoom == zoom)
      visible=true;
    if(type=="district")
      markers = districtMarkers;
    if(type=="block")
      markers = blockMarkers;
    if(type=="cluster")
      markers = clusterMarkers;
    if(type=="school")
      markers = schoolMarkers;
    if(type=="preschooldistrict")
      markers = preschooldistrictMarkers;
    if(type=="project")
      markers = projectMarkers;
    if(type=="circle")
      markers = circleMarkers;
    if(type=="preschool")
      markers = preschoolMarkers;
    for (var p in pointInfo[type]) {
      var point = pointInfo[type][p];
      var pos = new google.maps.LatLng(point.lat, point.lon);
      markers[point.id] = new google.maps.Marker({
        position: pos,
        map: map,
        title: point.name,
        visible:visible,
        icon:"images/"+image
      });
      displayPointInfo(markers[point.id],point.id,point.name,type)

    }
    if( type=='district')
      populateDistricts(pointInfo[type]);
    if( type=='preschooldistrict')
      populatePreSchoolDistricts(pointInfo[type]);
  }
}

function displayPointInfo(marker,id,name,type)
{
  google.maps.event.addListener(marker, 'click', function(event) {
    getInfo(marker,id,name,type);
  });
}

function openInfoWindow(message,marker)
{
  closeWindow();
  lastWindow = message;
  message.open(map, marker);
}

function getInfo(marker,id,name,type)
{
   var message = new google.maps.InfoWindow({content:'Loading...'});
   openInfoWindow(message,marker);
   YUI({base: 'yui/build/',
    timeout: 50000}).use("io-base","json-parse",
    function(Y, result) {
      if (!result.success) {
        Y.log('Load failure: ' + result.msg, 'warn', 'program');
      }
      var callback = {
        on: { success: 
          function(id, o) {
            var info;
            try {  
              info= Y.JSON.parse(o.responseText);
            } catch (e) {
              Y.log('Could not parse json', 'error', 'info');
              return;
            }
            var pointInfo = createInfoData(info,type,info.id,name);
            message.setContent(pointInfo);
          },
          failure: function(id, o) {
            Y.log('Could not retrieve info data ','error','info');
          }  
        }
      };
      url = "info/"+type+"/"+id;
      var request = Y.io(url, callback);
    });
}

function createInfoData(info,type,id,name)
{
  var tableContent
  if (type=="school" || type=="preschool")
    tableContent = createSchoolInfo(type,info,id,name);
  else
  {
    var numSchools = info.numSchools;
    var numStudents = info.numStudents;
    if(info.assessments){ 
        var assessArr = info.assessments.split(",");
        var assdict = {};
        var asskeys = [];
        var assessmentInfo = '';
        var assessment = [];
        for( num in assessArr)
        {
          assessment = assessArr[num].split("|");
          assdict[assessment[1]] = [assessment[3]+'-'+assessment[0],assessment[2]];
          asskeys.push(assessment[1]);
        }
        asskeys.sort();
        var asstext = '';
        var asstype = '';
        var each = '';
        for(var i = 0; i< asskeys.length; i++)
        {
          each = asskeys[i];
          asstext = assdict[each][0] + ' (' + each + ')';
          asstype = assdict[each][1];
          assessmentInfo = assessmentInfo+'<a href=\"javascript:void(0);\" onclick=window.open("../../assessment/'+type+'/'+asstype+'/'+info['id']+'","_blank")><span style="color:#43AD2F">'+asstext+'</span></a><br/>'
        }
    } else {
        assessmentInfo = 'Programmes\' Information not available'
    }

    /*var assessmentInfo ="";
    var assessArr = info.assessments.split(";");
    for( num in assessArr)
    {
     var assessment = assessArr[num].split(",");
     var asstext = assessment[2]+'-'+assessment[0]
     assessmentInfo = assessmentInfo+'<a href=\"javascript:void(0);\" onclick=window.open("assessment/'+type+'/'+assessment[1]+'/'+id+'","mywindow")>'+asstext+'</a><br>'
    }*/
    schooltext="Schools"
    if (type=="project" || type=="circle" || type=="preschooldistrict")
      schooltext="Preschools"
    tableContent= '<div style="display:block">' + 
      '<div style="color:#439C1E;font-size:10pt;font-weight:bold">' + name.toUpperCase() + '</div>' +
      '<div style="display:table;font-size:8pt;font-weight:normal;margin-bottom:-10px;">' +
      '<div style="display:table-row">' + 
        '<div style="display:table-cell"> Number of '+ schooltext+': '+ numSchools + '</div>' +
        '<div style="display:table-cell;padding-left:5px;"> Number of Girls: ' + info.numGirls + '</div>' +
      '</div><div style="display:table-row">' +  
        '<div style="display:table-cell"> Number of Students: ' + numStudents + '</div>' +
        '<div style="display:table-cell;padding-left:5px;"> Number of Boys: '+ info.numBoys + '</div></div>' +
      '</div><hr/><div style="display:table;font-size:8pt;font-weight:normal;margin-top:-10px;margin-bottom:5px;">' +
      '<div style="display:table-row">' + 
        '<div style="display:table-cell"> Intervention Programs:</div>' +
        '<div style="display:table-cell;padding-left:5px;"> ' + assessmentInfo + '</div> </div> </div>'; // +
      //'<div style="color:#222;font-size:7pt;font-weight:normal;float:left"> Partner: Akshara Foundation</div>';

  }
  return tableContent;
}

function createSchoolInfo(type,info,schoolId,name)
{
   var numStories = info.numStories;
   var sysText;
   if( numStories == 0)
   {
     sysText = 'No visits to this '+type+' yet. Be the <b><a href=\"javascript:void(0);\" onclick=window.open("shareyourstory'+type+'?type='+type+'?id='+schoolId+'","mywindow") style="color:#439C1E">First to Share your Experience!</a></b>';
   }
   else
   {
     sysText = numStories+' visits by the community. <b><a href=\"javascript:void(0);\" onclick=window.open("shareyourstory'+type+'?type='+type+'?id='+schoolId+'","mywindow") style="color:#439C1E">Share your Experience!</a></b>';
   }
   var numStudents = info.numStudents;
   var tableContent= '<div style="display:block">' +
      '<div><a href=\"javascript:void(0);\" onclick=window.open("schoolpage/'+type+'/'+schoolId+'","mywindow")<span  style="color:#439C1E;font-size:10pt;font-weight:normal"><b>' + name.toUpperCase() + '</b></span></a><span style="color:black"><i> Know more...</i></span></div>'+
      '<div style="display:table;font-size:8pt;font-weight:normal;margin-bottom:-10px;">' +
      '<div style="display:table-row">' +
        '<div style="display:table-cell"> Number of Students: ' + numStudents + '</div>' +
      '</div><div style="display:table-row">' +
        '<div style="display:table-cell"> Number of Girls: ' + info.numGirls + '</div>' +
        '<div style="display:table-cell;padding-left:5px;"> Number of Boys: '+ info.numBoys + '</div></div></div><hr/>' +
      '<div style="display:table;font-size:8pt;font-weight:normal;margin-top:-10px;margin-bottom:5px;">' +
      '<div style="display:table-row;">' + sysText + '</div>' + 
      '</div>'; //<div style="color:#222;font-size:7pt;font-weight:normal;float:left"> Partner: Akshara Foundation</div>';
   return tableContent;
}

function populateDistricts(districtInfo)
{
  var select = document.getElementById("district");
  var count=1;
  for( var d in districtInfo){
    select.options[count] = new Option(districtInfo[d].name,districtInfo[d].id);
    count = count+1;
  }
}

function populatePreSchoolDistricts(districtInfo)
{
  var selectpreschool = document.getElementById("preschooldistrict");
  var count=1;
  for( var d in districtInfo){
    selectpreschool.options[count] = new Option(districtInfo[d].name,districtInfo[d].id);
    count = count+1;
  }
}


function changeSelection()
{
  closeWindow();
  var selection = document.getElementById("selection").value;
  if (selection == "school")
  {
     document.getElementById("schooldiv").style.display="inline"
     document.getElementById("preschooldiv").style.display="none"
  }
  else
  {
     document.getElementById("schooldiv").style.display="none"
     document.getElementById("preschooldiv").style.display="inline"
  }
}

function getOtherMarker(markers)
{
  for(var b in childInfo)
  {
     if (childInfo[b].id in markers)
     {
       return markers[b.id];
     }
  }
  return districtMarkers[defaultid];
}

function changeFocus(parentType,childType)
{
  closeWindow();
  var id= document.getElementById(parentType).value;
  if (parentType != "school" && parentType != "preschool")
    getBoundary(id,parentType,childType)
  var marker;
  if(parentType =="district")
  {
    if(id in districtMarkers)
      marker = districtMarkers[id];
    else
      marker = getOtherMarker(blockMarkers);
  }
  else if( parentType=="preschooldistrict")
  {
    if(id in preschooldistrictMarkers)
      marker = preschooldistrictMarkers[id];
    else
      marker = getOtherMarker(projectMarkers);
  }
  else if(parentType =="block")
  {
    if(id in blockMarkers)
      marker = blockMarkers[id];
    else
      marker = getOtherMarker(clusterMarkers);
  }
  else if(parentType =="project")
  {
    if( id in projectMarkers)
      marker = projectMarkers[id];
    else
      marker = getOtherMarker(circleMarkers);
  }
  else if(parentType =="cluster")
  {
    if (id in clusterMarkers)
      marker = clusterMarkers[id];
    else
      marker = getOtherMarker(schoolMarkers);
  }
  else if(parentType =="circle")
  {
    if( id in circleMarkers)
      marker = circleMarkers[id];
    else
      marker = getOtherMarker(preschoolMarkers);
  }
  else if(parentType =="school")
  {
    if (id in schoolMarkers)
      marker = schoolMarkers[id];
    else
      marker = getOtherMarker(schoolMarkers);
  }
  else if(parentType =="preschool")
  {
    if (id in preschoolMarkers)
      marker = preschoolMarkers[id];
    else
      marker = getOtherMarker(preschoolMarkers);
  }
  else
    marker=districtMarkers[defaultid]
  map.setCenter(marker.getPosition())
  if(parentType =="school" || parentType=="preschool")
    map.setZoom(zoomInfo["school"]+4);
  else
    map.setZoom(zoomInfo[childType])
}


function clearSelection(type)
{
  var select = document.getElementById(type);
  //dropDownList.removeChild(select);
  select.options.length = 0;
  select.options[0] = new Option("Select","");
}


function populateBoundary(boundaryInfo, type)
{
  childInfo = boundaryInfo;
  var select = document.getElementById(type);
  var count=1;
  for( var b in boundaryInfo){
    select.options[count] = new Option(boundaryInfo[b].name,boundaryInfo[b].id);
    count = count+1;
  }
  if (type == "block")
  {
     clearSelection("cluster");
     clearSelection("school");
  }
  if (type =="cluster")
  {
     clearSelection("school");
  }
  if (type == "project")
  {
     clearSelection("circle");
     clearSelection("preschool");
  }
  if (type =="circle")
  {
     clearSelection("preschool");
  }
}


function getBoundary(parentId,parentType,childType)
{
  YUI({base: 'yui/build/',
    timeout: 50000}).use("io-base","json-parse",
    function(Y, result) {
      if (!result.success) {
        Y.log('Load failure: ' + result.msg, 'warn', 'program');
      }
      var callback = {
        on: { success:
          function(parentId, o) {
            var info;
            try {
              info= Y.JSON.parse(o.responseText);
            } catch (e) {
              Y.log('Could not parse json'+type, 'error', 'info');
              return;
            }
            populateBoundary(info,childType);
          },
          failure: function(parentId, o) {
            Y.log('Could not retrieve point data ','error','info');
          }
        }
      };
      url = "boundaryPoints/"+parentType+"/"+parentId;
      var request = Y.io(url, callback);
    });

}

function displayInfo(widget) {
    var info = document.getElementById('circleinfo');
    info.style.display = "block";
    info.innerHTML = 'Centre of circular overlay: ' + widget.get('position') + ' and Radius of overlay: ' +
      Math.round(parseFloat(widget.get('distance'))*100)/100 + ' km';
};


function eToggle(anctag,darg)
{
  var ele = document.getElementById(darg);
  //var text = document.getElementById(anctag);
  //if(ele.style.display == "block") 
  if(anctag == "less") 
  {
    ele.style.display = "none";
    //text.innerHTML = "More...";
    //text.firstChild.nodeValue = "More...";
//    document.getElementById('toggle').innerHTML='<a class="button" style="float:right" href="javascript:eToggle("moreoptions");" id="toggles"><span>More...</span></a>';
  }
  else 
  {
    ele.style.display = "block";
    //text.innerHTML = "Less...";
    //text.firstChild.nodeValue = "Less...";
  }
} 

function togglePanel(panelid)
{
  var ele = document.getElementById(panelid);
  if(ele.style.display == "block") {
    ele.style.display = "none";
  }
  else {
    ele.style.display = "block";
  }
}

var newwindow;
function popwindow(url)
{
  newwindow=window.open(url,'Downloads','height=620,width=400,scrollbars=1');
  if (window.focus) {newwindow.focus()}
}


function listFiles(fileList)
{
  var type = parseInt(fileList["listtype"])
  if( type == 1 || type == 3) {
    if( type == 1){
      document.getElementById('selections').style.display = "block";
    } else {
      document.getElementById('selections').style.display = "none";
      document.getElementById('mp_files').style.display = "block";
      document.getElementById('mla_files').style.display = "block";
    } 
    var mptable = document.getElementById('mp_files');
    var mlatable = document.getElementById('mla_files');
    var fileNames = fileList["mpnames"].sort();
    tableHTML = "<div class='div-table'>" + "<div class='div-table-caption'>List of Reports</div>" ;
    for( each in fileNames) {
      tableHTML = tableHTML + "<div class='div-table-row'>" + "<div class='div-table-col'>" + fileNames[each] + "</div>"+
      "<div class='div-table-col'>" + "<a target='_blank' href='" + fileList["directory"] + fileList["subdir1"] + "/" + fileNames[each] + "'/>" + "Kannada</a></div>" +
      "<div class='div-table-col'>" + "<a target='_blank' href='" + fileList["directory"] + fileList["subdir2"] + "/" + fileNames[each] + "'/>" + "English</a></div>" + 
      "</div>";
    }
    mptable.innerHTML = tableHTML + '</div></div>'; 
    tableHTML = "<div class='div-table'>" ;
    if (type ==1 ) {
      tableHTML = tableHTML + "<div class='div-table-caption'>List of Reports</div>" ;
    }
    fileNames = fileList["mlanames"].sort();
    for( each in fileNames) {
      tableHTML = tableHTML + "<div class='div-table-row'>" + "<div class='div-table-col'>" + fileNames[each] + "</div>"+
      "<div class='div-table-col'>" + "<a target='_blank' href='" + fileList["directory"] + fileList["subdir1"] + "/" + fileNames[each] + "'/>" + "Kannada</a></div>" +
      "<div class='div-table-col'>" + "<a target='_blank' href='" + fileList["directory"] + fileList["subdir2"] + "/" + fileNames[each] + "'/>" + "English</a></div>" + 
      "</div>";
    }
    mlatable.innerHTML = tableHTML + "</div></div>"
  } else if (type == 2) {
    document.getElementById('raw_files').style.display = "block";
    var rawfiletable = document.getElementById('raw_files');
    var fileNames = fileList["rawfiles"].sort();
    tableHTML = "<div class='div-table'>" + "<div class='div-table-caption'>List of Reports</div>" ;
    tableHTML = tableHTML + "<div class='div-table-row'> Right click and use \"Save As\" to download files below:</div>";
    for( each in fileNames) {
      tableHTML = tableHTML + "<div class='div-table-row'>" +
                              "<div class='div-table-col' style='width:200px;'>" + 
                  "<a target='_blank' href='" + fileList["directory"] + "/" + fileNames[each] + "'/>" + 
                  fileNames[each] + "</a></div></div>";
    }
    rawfiletable.innerHTML = tableHTML + "</div>"
  }
}
function selectFiles()
{
  elm = document.getElementById('filetype').value;
  if(elm.length != 0) {
    div_ids=["mla_files","mp_files","corp_files"]
    for (var i = 0; i < div_ids.length; i++) {
      var layer = document.getElementById(div_ids[i]);
      if (elm!= div_ids[i]) {
        layer.style.display = "none";
      }
      else {
        layer.style.display = "block";
      }
    }
  }
}
