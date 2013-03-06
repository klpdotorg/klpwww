var school, preschool;
var district, block, cluster, circle, project, school, preschool, preschooldist;
var school_layer, district_layer, block_layer, cluster_layer, circle_layer, project_layer;
var preschool_layer, preschooldist_layer, boundedSchools_layer, boundedPreschools_layer;
var schoolsList;
var school_cluster = new L.MarkerClusterGroup({showCoverageOnHover: false, 
	iconCreateFunction: function(cluster) {
		return new L.DivIcon({ className:'marker-cluster marker-cluster-school', style:'style="margin-left: -20px; margin-top: -20px; width: 40px; height: 40px; transform: translate(293px, 363px); z-index: 363;"', html: "<div><span>" + cluster.getChildCount() + "</span></div>" });
	}});
var preschool_cluster = new L.MarkerClusterGroup({showCoverageOnHover: false, 
	iconCreateFunction: function(cluster) {
		return new L.DivIcon({ className:'marker-cluster marker-cluster-preschool', style:'style="margin-left: -20px; margin-top: -20px; width: 40px; height: 40px; transform: translate(293px, 363px); z-index: 363;"', html: "<div><span>" + cluster.getChildCount() + "</span></div>" });
	}});

var current_layers = new L.LayerGroup();

function getURLParameter(name) {
	return decodeURI(
		(RegExp(name + '=' + '(.+?)(&|$)').exec(location.search)||[,])[1]
		);
}

var southWest = new L.LatLng(11.57, 73.87),
northEast = new L.LatLng(18.45, 78.57),
bounds = new L.LatLngBounds(southWest, northEast);

var regionParameter = getURLParameter('region');
var region = (regionParameter === 'undefined') ? '' : regionParameter;
var bangalore = L.latLng([12.9719,77.5937]);

var map = L.map('map', {zoomControl: false, attributionControl: false, maxBounds: bounds}).setView(bangalore, 12);
var mapquestUrl = 'http://{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png',
subDomains = ['otile1','otile2','otile3','otile4'];
var mapquest = new L.TileLayer(mapquestUrl, {maxZoom: 18, subdomains: subDomains});
mapquest.addTo(map);

zoom = new L.Control.Zoom({position:'topleft'});

$.getJSON('/schoolsinfo/', function(data) {

	school = JSON.parse(data['school'][0]);
	preschool = JSON.parse(data['preschool'][0]);
	preschooldist = JSON.parse(data['preschooldistrict'][0]);
	initialize();

})

map.addLayer(current_layers);

var blockIcon = L.icon({
	iconUrl:'/images/icons/block.png',
	iconSize: [20, 30],
	iconAnchor: [16, 80],
	popupAnchor: [-6, -78]

});

var districtIcon = L.icon({
	iconUrl:'/images/icons/district.png',
	iconSize: [20, 30],
	iconAnchor: [16, 80],
	popupAnchor: [-6, -78]

});

var circleIcon = L.icon({
	iconUrl:'/images/icons/circle.png',
	iconSize: [20, 30],
	iconAnchor: [16, 80],
	popupAnchor: [-6, -78]

});

var clusterIcon = L.icon({
	iconUrl:'/images/icons/cluster.png',
	iconSize: [20, 30],
	iconAnchor: [16, 80],
	popupAnchor: [-6, -78]

});

var projectIcon = L.icon({
	iconUrl:'/images/icons/project.png',
	iconSize: [20, 30],
	iconAnchor: [16, 80],
	popupAnchor: [-6, -78]

});

var schoolIcon = L.icon({
	iconUrl:'/images/icons/school.png',
	iconSize: [20, 30],
	iconAnchor: [16, 80],
	popupAnchor: [-6, -78]

});

var preschoolIcon = L.icon({
	iconUrl:'/images/icons/preschool.png',
	iconSize: [20, 30],
	iconAnchor: [16, 80],
	popupAnchor: [-6, -78]

});


var drawControl = new L.Control.Draw({
	position: 'topright',
	polyline: false,
	marker: false,
	polygon: false,
	rectangle: false
});

function onLocationFound(e) {
	map.setView(e.latlng, 15);
}

function onLocationError(e) {
	map.setView(bangalore, 12);
}


map.on('locationfound', onLocationFound);
map.on('locationerror', onLocationError);

function initialize () {
	map.locate({setView: true, maxZoom: 16});
	preschool_layer = L.geoJson(preschool, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: preschoolIcon});}, onEachFeature: onEachSchool});

	preschooldist_layer = L.geoJson(preschooldist, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: preschoolIcon});}, onEachFeature: onEachSchool});
	preschool_layer.addTo(preschool_cluster);

	preschooldist_layer.addTo(preschool_cluster);

	school_layer = L.geoJson(school, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: schoolIcon});}, onEachFeature: onEachSchool});

	school_layer.addTo(school_cluster);

	current_layers.addLayer(school_cluster);
	current_layers.addLayer(preschool_cluster);

	$.getJSON('/pointinfo/', function(data) {
		district = JSON.parse(data['district'][0]);
		block = JSON.parse(data['block'][0]);
		cluster = JSON.parse(data['cluster'][0]);
		circle = JSON.parse(data['circle'][0]);
		project = JSON.parse(data['project'][0]);
		setup_layers();
	});

}

function setup_layers() {

	district_layer = L.geoJson(district, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: districtIcon});}, onEachFeature: onEachFeature});

	block_layer = L.geoJson(block, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: blockIcon});}, onEachFeature: onEachFeature});

	cluster_layer = L.geoJson(cluster, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: clusterIcon});}, onEachFeature: onEachFeature});

	circle_layer = L.geoJson(circle, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: circleIcon});}, onEachFeature: onEachCircle});

	project_layer = L.geoJson(project, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: projectIcon});}, onEachFeature: onEachFeature});

	rteCircles();

	overlays = {
		"<img src='/images/icons/school.png' height='25px' /> Schools": school_cluster,
		"<img src='/images/icons/preschool.png' height='25px' /> Preschools": preschool_cluster,
		"<img src='/images/icons/district.png' height='25px' /> Districts": district_layer,
		"<img src='/images/icons/block.png' height='25px' /> Blocks": block_layer,
		"<img src='/images/icons/cluster.png' height='25px' /> Clusters": cluster_layer,
		"<img src='/images/icons/project.png' height='25px' /> Projects": project_layer,
		"<img src='/images/icons/circle.png' height='25px' /> Circles": circle_layer,
		"Schools RTE 2KM": rteSchools,
		"Preschools RTE 1KM": rtePreschools,
	};


	zoom.addTo(map);

	L.control.attribution({position: 'bottomleft'})
	.addAttribution("&copy; <a href='http://osm.org/copyright'>OpenStreetMap</a>")
	.setPrefix("")
	.addTo(map);

	new L.Control.GeoSearch({position: 'topright',
		provider: new L.GeoSearch.Provider.Google({
			region: region
		}), zoomLevel: 15, country: 'India', searchLabel: 'Search for a neighborhood...'
	}).addTo(map);

	L.control.layers(null, overlays, {position:'topright', collapsed:false}).addTo(map);
	map.addControl(filter);
	map.addControl(drawControl);

}


map.on('zoomend', update_map);

function update_map() {
	zoom_level = map.getZoom();
	if (zoom_level == 8) {
		current_layers.clearLayers();
		current_layers.addLayer(district_layer);
	}

	else if (zoom_level == 9) {
		current_layers.clearLayers();
		current_layers.addLayer(block_layer);
		current_layers.addLayer(circle_layer);

	}

	else if (zoom_level == 10) {
		current_layers.clearLayers();
		current_layers.addLayer(cluster_layer);
		current_layers.addLayer(project_layer);
	}

	else if (zoom_level >= 11) {
		current_layers.clearLayers();
		current_layers.addLayer(school_cluster);
		current_layers.addLayer(preschool_cluster);
	}


}

function onEachFeature(feature, layer) {
	if (feature.properties) {
		layer.bindPopup(feature.properties.name);
	}
}

function onEachSchool(feature, layer) {
	if (feature.properties) {
		layer.on('click', schoolPopup);
	}
}

function onEachCircle(feature, layer) {
	if (feature.properties) {
		layer.on('click', circlePopup);
	}
}

function schoolPopup () {
	marker = this;
	$.getJSON('/info/school/'+marker.feature.id, function(data) {
		popupContent = "<b><a href='schoolpage/school/"+marker.feature.id+"' target='_blank'>"+marker.feature.properties.name+"</a></b>"+"<hr> Boys: "+
		String(data['numBoys'])+" | Girls: "+String(data['numGirls'])+" | Total: <b>"+String(data['numStudents'])+"</b><br />Stories: "+String(data['numStories'])+
		" &rarr; <i><a href='shareyourstoryschool?type=school?id="+marker.feature.id+"' target='_blank'>Share your story!</a></i>";
		marker.bindPopup(popupContent).openPopup();
	});
}

function circlePopup() {
	marker = this;
	$.getJSON('/info/circle/'+marker.feature.id, function(data) {
		popupContent = "<b>"+marker.feature.properties.name+"</a></b>"+"<hr> Boys: "+
		String(data['numBoys'])+" | Girls: "+String(data['numGirls'])+" | Total: <b>"+String(data['numStudents'])+"</b><br />Schools: "+String(data['numSchools']);
		marker.bindPopup(popupContent).openPopup();
	});	
}

var stopDrawing = L.Control.extend({
	options: {
		position: 'topright'
	},

	onAdd: function (map) {
		var container = L.DomUtil.create('div', 'leaflet-control leaflet-control-draw leaflet-bar');
		var containerUI = L.DomUtil.create('a', 'stop-drawing leaflet-bar-part leaflet-bar-part-top leaflet-bar-part-bottom', container);
		L.DomEvent
		.addListener(container, 'click', L.DomEvent.stopPropagation)
		.addListener(container, 'click', L.DomEvent.preventDefault)
		.addListener(container, 'click', this.clicked);
		return container;
	},

	clicked: function stop() {
		drawControl.handlers.circle.disable();
		map.removeControl(stopDrawingControl);
		map.addControl(drawControl);
		map.addLayer(current_layers);
		if (schoolsListFlag == 1) {
			map.removeControl(schoolsList);
			schoolsListFlag = 0;
		}
	}
});

var drawnItems = new L.LayerGroup();
var stopDrawingControl = new stopDrawing();

map.on('drawing', function(){
	drawnItems.clearLayers();
	map.addControl(stopDrawingControl);
	map.removeControl(drawControl);
	if (boundedSchools_layer || boundedPreschools_layer) {
		map.removeLayer(boundedSchools_layer);
		map.removeLayer(boundedPreschools_layer);
	};
	map.removeLayer(current_layers);
});

var alerts = L.Control.extend({

	options: {
		position: 'topcenter',
		message: ''		
	},
	initialize: function (options) {
		L.Util.setOptions(this, options)
	},

	onAdd: function (map) {
		var container = L.DomUtil.create('div', 'alert alert-success');
		container.innerHTML = this.options.message+"<a class='close' data-dismiss='alert' href='#'>&times;</a>";
		return container;
	}

});

var selectedSchools = L.Control.extend({

	options: {
		position: 'topleft',
		schools: [],
		preschools: []
	},

	initialize: function(options) {
		L.Util.setOptions(this, options)
	},

	onAdd: function (map) {
		var container = L.DomUtil.create('div', 'btn-group');
		button = "<p class='btn btn-success dropdown-toggle' data-toggle='dropdown'>Institutions<span class='caret'></span></p><ul class='dropdown-menu schools'>";
		var schoolsEntries= ""; var preschoolsEntries = "";
		for (i=0; i<this.options.schools.length; i++) {
			schoolsEntries = schoolsEntries+"<li><a href='schoolpage/school/"+this.options.schools[i].id+" ' target='_blank'>"+this.options.schools[i].properties['name']+"</a></li>";
		}
		for (i=0; i<this.options.preschools.length; i++) {
			preschoolsEntries = preschoolsEntries+"<li><a href='schoolpage/school/"+this.options.preschools[i].id+" ' target='_blank'>"+this.options.preschools[i].properties['name']+"</a></li>";
		}
		container.innerHTML =button+schoolsEntries+"<li class='divider'></li>"+preschoolsEntries+"</ul>";
		return container;
	}

});

var schoolsListFlag = 0;

map.on('draw:circle-created', function (e) {
	map.removeControl(stopDrawingControl);
	map.addControl(drawControl);
	drawnItems.addLayer(e.circ);
	bbox = e.circ.getBounds().toBBoxString()
	$.getJSON('/schools?bounds='+bbox, function(data) {
		if (data['count'] == 0) {
			alerter = new alerts({message:"No schools found in a radius of <strong>"+Math.floor(e.circ.getRadius())+" meters </strong>"});
			map.addControl(alerter);
		}
		else {

			alerter = new alerts({message:"<strong>"+data['count']+"</strong> schools found in a radius of <strong>"+Math.floor(e.circ.getRadius())+" meters </strong>"})
			map.addControl(alerter);
			boundedSchools = JSON.parse(data['schools'][0]);
			boundedPreschools = JSON.parse(data['preschools'][0]);

			if (schoolsListFlag == 1) {
				map.removeControl(schoolsList);
				schoolsListFlag = 0;
			}
			schoolsList = new selectedSchools({schools: boundedSchools.features, preschools: boundedPreschools.features});
			map.addControl(schoolsList);
			schoolsListFlag = 1;
			boundedSchools_layer = L.geoJson(boundedSchools, {pointToLayer: function(feature, latlng){
				return L.marker(latlng, {icon: schoolIcon});}, onEachFeature: onEachSchool});
			boundedPreschools_layer = L.geoJson(boundedPreschools, {pointToLayer: function(feature, latlng){
				return L.marker(latlng, {icon: preschoolIcon});}, onEachFeature: onEachSchool});			
			boundedSchools_layer.addTo(map);
			boundedPreschools_layer.addTo(map);
			$('.schools').mouseover(function(){map.dragging.disable(); map.scrollWheelZoom.disable();});
			$('.schools').mouseout(function(){map.dragging.enable(); map.scrollWheelZoom.enable();});
			map.setView(e.circ.getLatLng(), 14, true);
		}
	});
setTimeout(function (){map.removeControl(alerter)}, 30000);
});


$('.alert').alert();
rteSchools  = new L.LayerGroup();
rtePreschools = new L.LayerGroup();

function rteCircles() {
	school_cluster.eachLayer(function(layer) {
		circle = L.circle(layer.getLatLng(), 2000, {stroke: false, fill:true, fillColor: "red", fillOpacity: "0.1"}).addTo(rteSchools);
	});

	preschool_cluster.eachLayer(function(layer) {
		circle = L.circle(layer.getLatLng(), 1000, {stroke: false, fill:true, fillColor: "green", fillOpacity: "0.1"}).addTo(rtePreschools);
	})
}


function fill_dropdown(data,type){
	var dist=document.getElementById(type);
	var count=1;
	document.getElementById(type).length=1;
	for(var i=0;i<data.length;i++){
		dist.options[count]=new Option(data[i].name,data[i].id);
		count=count+1;
	}
}


function change_focus(parentType,childType){

	var type=document.getElementById(parentType);
	$.getJSON('/boundaryPoints/'+parentType+'/'+type.value, function(data) {
		fill_dropdown(data,childType);

	});

}

var filterMap = L.Control.extend({
	options: {
		position: 'topcenter'
	},

	onAdd: function (map) {
		var container = L.DomUtil.create('div', 'leaflet-control filter-control');
		container.title = "Filter Schools";
		button = "<a href='#filterModal' role='button' data-toggle='modal'></a>";
		container.innerHTML = button;
		return container;
	},

	clicked: function openFilters() {
	}
});

var filter = new filterMap();


$("#selection").select2({
	placeholder: "Select the type of School",
	allowClear: true,
});

$("#district").select2({
	placeholder: "Select a District",
	allowClear: true,
	disabled: true
});


$("#block").select2({
	placeholder: "Select a Block",
	allowClear: true
});

$("#cluster").select2({
	placeholder: "Select a Cluster",
	allowClear: true
});

$("#school").select2({
	placeholder: "Select a School",
	allowClear: true
});

$("#preschooldistrict").select2({
	placeholder: "Select a District",
	allowClear: true
});

$("#project").select2({
	placeholder: "Select a Project",
	allowClear: true
});

$("#circle").select2({
	placeholder: "Select a Circle",
	allowClear: true
});

$("#preschool").select2({
	placeholder: "Select a Preschool",
	allowClear: true
});

$("#district, #block, #cluster, #school, #preschooldist, #project, #circle, #preschool").select2("disable");

$("#selection").on("change", function(e) {
	if (e.val == 'school') {
		$('#schooldiv').removeClass('hide');
		$('#preschooldiv').addClass('hide');
		$('#district').select2('enable');
	};

	if (e.val == 'preschool') {
		$('#preschooldiv').removeClass('hide');
		$('#schooldiv').addClass('hide');
		$('#preschooldistrict').select2('enable');
	};
});

$("#district").on("change", function(e) {$('#block').select2('enable');});
$("#block").on("change", function(e) {$('#cluster').select2('enable');});
$("#cluster").on("change", function(e) {$('#school').select2('enable');});
$("#preschooldistrict").on("change", function(e) {$('#project').select2('enable');});
$("#project").on("change", function(e) {$('#circle').select2('enable');});
$("#circle").on("change", function(e) {$('#preschool').select2('enable');});

$("#school").on("change", function(e) {
	applyFilter(e, school, schoolIcon);
});


function filterSchool(id) {
	return (function(d) {return (d.id == id);});
}

$("#preschool").on("change", function(e) {
	applyFilter(e, preschool, preschoolIcon)

})

function applyFilter(e, array, icon) {
	filteredSchool = array.features.filter(filterSchool(e.val));
	coordinates = [filteredSchool[0].geometry.coordinates[1], filteredSchool[0].geometry.coordinates[0]];
	map.removeLayer(current_layers);
	map.setView(L.latLng(coordinates), 15);
	filteredSchoolMarker = L.marker(coordinates, {icon: icon});
	$.getJSON('/info/school/'+filteredSchool[0].id, function(data) {
		popupContent = "<b><a href='schoolpage/school/"+filteredSchool[0].id+"' target='_blank'>"+filteredSchool[0].properties.name+"</a></b>"+"<hr> Boys: "+
		String(data['numBoys'])+" | Girls: "+String(data['numGirls'])+" | Total: <b>"+String(data['numStudents'])+"</b><br />Stories: "+String(data['numStories'])+
		" &rarr; <i><a href='shareyourstoryschool?type=school?id="+filteredSchool[0].id+"' target='_blank'>Share your story!</a></i>";
		filteredSchoolMarker.bindPopup(popupContent).openPopup();
	});

	filteredSchoolMarker.addTo(map);
	$('#filterModal').modal('hide');	
};