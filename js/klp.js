//Globals
var map;
var lastWindow;
var geocoder;
var mapmarkers={"districtMarkers":{},"preschooldistrictMarkers":{},"blockMarkers":{},"clusterMarkers":{},"schoolMarkers":{},"preschoolMarkers":{},"projectMarkers":{},"circleMarkers":{}};
var types = ["district","block","cluster","school","preschooldistrict","project","circle","preschool"];
var zoomInfo = {"district":7,"preschooldistrict":7,"block":9,"cluster":11,"school":13,"project":9,"circle":11,"preschool":13};
var images = {"district":"district.png","preschooldistrict":"district.png","block":"block.png","cluster":"cluster.png","circle":"circle.png","project":"project.png","school":"school.png","preschool":"preschool.png"};
var center={"lat":12.971606,"lon":77.594376};
var defaultid="8877";
var childInfo=[];
var distanceWidget = null;


/* Initialize map*/
function initialiseSchool(){
  document.getElementById("schooldiv").style.display="inline";
  document.getElementById("preschooldiv").style.display="none";
  var latlng = new google.maps.LatLng(center["lat"],center["lon"]);
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
  google.maps.event.addListener(distanceWidget, 'distance_changed', function()
  {
    displayInfo(distanceWidget);
  });
  google.maps.event.addListener(distanceWidget, 'position_changed', function() 
  {
    displayInfo(distanceWidget);
  });
}

function geocode() 
{
  var address = document.getElementById("address").value;
  geocoder.geocode({
    'address': address,
    'partialmatch': true}, geocodeResult);
}
 

function geocodeResult(results, status) 
{
  if (status == 'OK' && results.length > 0) 
  {
    map.fitBounds(results[0].geometry.viewport);
    map.setCenter(results[0].geometry.location);
    distanceWidget.set('position', map.getCenter());
  }
  else 
  {
    alert("Geocode was not successful for the following reason: " + status);
  }
}

function closeWindow()
{
  if( typeof(lastWindow) == 'object' )
  {
    lastWindow.close();
  }
}

function changeVisibility(showmarkers)
{
  for(markertype in mapmarkers)
  {
    if(markertype in showmarkers)
    {
      for (m in mapmarkers[markertype])
      {
        marker = mapmarkers[markertype][m];
        marker.setVisible(true);
      }
    }
    else
    {
      for (m in mapmarkers[markertype])
      {
        marker = mapmarkers[markertype][m];
        marker.setVisible(false);
      }
    }
  }
}

function zoomChanged()
{
  closeWindow();
  var zoom = map.getZoom();
  if (zoom < zoomInfo["block"] )
  {
    changeVisibility({"districtMarkers":0,"preschooldistrictMarkers":0});
  }
  else if (zoom >= zoomInfo["block"] && zoom < zoomInfo["cluster"])
  {
    changeVisibility({"blockMarkers":0,"projectMarkers":0});
  }
  else if (zoom >= zoomInfo["cluster"] && zoom < zoomInfo["school"])
  {
    changeVisibility({"clusterMarkers":0,"circleMarkers":0});
  }
  else if (map.getZoom() >= zoomInfo["school"])
  {
    changeVisibility({"schoolMarkers":0,"preschoolMarkers":0});
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
      markers = mapmarkers["districtMarkers"];
    if(type=="block")
      markers = mapmarkers["blockMarkers"];
    if(type=="cluster")
      markers = mapmarkers["clusterMarkers"];
    if(type=="school")
      markers = mapmarkers["schoolMarkers"];
    if(type=="preschooldistrict")
      markers = mapmarkers["preschooldistrictMarkers"];
    if(type=="project")
      markers = mapmarkers["projectMarkers"];
    if(type=="circle")
      markers = mapmarkers["circleMarkers"];
    if(type=="preschool")
      markers = mapmarkers["preschoolMarkers"];
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
  plotHighSchool();
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
      '<div><a href=\"javascript:void(0);\" onclick=window.open("schoolpage/'+type+'/' + schoolId + '","mywindow")><span  style="color:#439C1E;font-size:10pt;font-weight:normal"><b>' + name.toUpperCase() + '</b></span></a><span style="color:black"><i> Know more...</i></span></div>'+
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
  return mapmarkers["districtMarkers"][defaultid];
}

function changeFocus(parentType,childType)
{
  closeWindow();
  var id= document.getElementById(parentType).value;
  if (parentType != "school" && parentType != "preschool")
    getBoundary(id,parentType,childType)
  var markers;
  var othermarkers;
  var marker;
  if(parentType=="district"){
    markers = mapmarkers["districtMarkers"];
    othermarkers = mapmarkers["blockMarkers"];}
  if(parentType=="block"){
    markers = mapmarkers["blockMarkers"];
    othermarkers = mapmarkers["clusterMarkers"];}
  if(parentType=="cluster"){
    markers = mapmarkers["clusterMarkers"];
    othermarkers = mapmarkers["schoolMarkers"];}
  if(parentType=="school"){
    markers = mapmarkers["schoolMarkers"];
    othermarkers = mapmarkers["schoolMarkers"];}
  if(parentType=="preschooldistrict"){
    markers = mapmarkers["preschooldistrictMarkers"];
    othermarkers = mapmarkers["projectMarkers"];}
  if(parentType=="project"){
    markers = mapmarkers["projectMarkers"];
    othermarkers = mapmarkers["circleMarkers"];}
  if(parentType=="circle"){
    markers = mapmarkers["circleMarkers"];
    othermarkers = mapmarkers["preschoolMarkers"];}
  if(parentType=="preschool"){
    markers = mapmarkers["preschoolMarkers"];
    othermarkers = mapmarkers["preschoolMarkers"];
  } else {
    marker=mapmarkers["districtMarkers"][defaultid]
  }
  if (id in markers)
    marker = markers[id];
  else
    marker = getOtherMarker(othermarkers);
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

function plotHighSchool() {
 var pos = new google.maps.LatLng('12.923692337812845', '77.64972028650284');
 var marker = new google.maps.Marker({
   position: pos,
   map: map,
   title: 'Agara High School',
   visible:visible,
   icon:"images/highschool.png"
 });
 google.maps.event.addListener(marker, 'click', function(event) {
    getHighSchoolInfo(marker);
 });
}

function getHighSchoolInfo(marker)
{
   var tableContent= '<div style="display:block">' +
      '<div><a href=\"javascript:void(0);\" onclick=window.open("sslc/agara_hs.html","mywindow")<span  style="color:#439C1E;font-size:10pt;font-weight:normal"><b>AGARA HIGH SCHOOL</b></span></a><span style="color:black"><i> Know more...</i></span></div>'+
      '<div style="display:table;font-size:8pt;font-weight:normal;margin-bottom:-10px;">' +
      '<div style="display:table-row">' +
        '<div style="display:table-cell"> 24th Main Rd, HSR Layout, Bangalore, Karnataka </div>' +
      '</div><div style="display:table-row">' +
        '<div style="display:table-cell"> School Type: High School</div>' +
        '</div></div><hr/>' +
      '</div>'; //<div style="color:#222;font-size:7pt;font-weight:normal;float:left"> Source: SSLC Board</div>';
   var message = new google.maps.InfoWindow({content:tableContent});
   openInfoWindow(message,marker);
}
