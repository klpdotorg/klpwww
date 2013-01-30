var district, block, cluster, circle, project, school, preschool, preschooldist;

var map = L.map('map', {zoomControl: false}).setView([12.9719,77.5937], 12);
var mapquestUrl = 'http://{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png',
subDomains = ['otile1','otile2','otile3','otile4'],
mapquestAttrib = "&copy; <a href='http://osm.org/copyright'>OpenStreetMap</a> contributors"
var mapquest = new L.TileLayer(mapquestUrl, {maxZoom: 18, attribution: mapquestAttrib, subdomains: subDomains});
mapquest.addTo(map);

zoom = new L.Control.Zoom({position:'bottomright'});
zoom.addTo(map);

$.getJSON('/pointinfo/', function(data) {
	district = JSON.parse(data['district'][0]);
	block = JSON.parse(data['block'][0]);
	cluster = JSON.parse(data['cluster'][0]);
	circle = JSON.parse(data['circle'][0]);
	project = JSON.parse(data['project'][0]);
	school = JSON.parse(data['school'][0]);
	preschool = JSON.parse(data['preschool'][0]);
	preschooldist = JSON.parse(data['preschooldistrict'][0]);
	initialize();
});

var school_layer, district_layer, block_layer, cluster_layer, circle_layer, project_layer;
var preschool_layer, preschooldist_layer;
var school_cluster = new L.MarkerClusterGroup();
var circle_cluster = new L.MarkerClusterGroup();
var preschool_cluster = new L.MarkerClusterGroup();

function initialize () {

// var district_layer = L.geoJson(district).addTo(map);
// var block_layer = L.geoJson(block).addTo(map);
// var circle_layer = L.geoJson(circle).addTo(circle_cluster);
// map.addLayer(circle_cluster)
	// var cluster_layer = L.geoJson(cluster).addTo(marker_cluster);
	// var project_layer = L.geoJson(project).addTo(marker_cluster);
	// var preschool = L.geoJson(preschool).addTo(marker_cluster);
	// var preschooldist_layer = L.geoJson(preschooldist).addTo(marker_cluster);

	school_layer = L.geoJson(school).addTo(school_cluster);
	map.addLayer(school_cluster);

	overlays = {
		// "Districts": district_layer,
		// "Blocks": block_layer,
		"Schools": school_cluster
	};

	// map.removeLayer(district_layer);
	// map.removeLayer(block_layer);

	L.control.layers(null, overlays, {position:'bottomright'}).addTo(map);
}


map.on('zoomend', update_map);

function update_map() {
	zoom_level = map.getZoom();

	if (zoom_level == 8) {
		district_layer = L.geoJson(district).addTo(map);
		}

	else if (zoom_level == 9) {
		block_layer = L.geoJson(block).addTo(map);

	}

	else if (zoom_level == 10) {
		circle_layer = L.geoJson(circle).addTo(circle_cluster);
		map.addLayer(circle_cluster);
		map.removeLayer(school_cluster);

	}

	else if (zoom_level == 11) {

	}

		
}