var district, block, cluster, circle, project, school, preschool, preschooldist;

var map = L.map('map').setView([12.9719,77.5937], 10);
var mapquestUrl = 'http://{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png',
subDomains = ['otile1','otile2','otile3','otile4'],
mapquestAttrib = "&copy; <a href='http://osm.org/copyright'>OpenStreetMap</a> contributors"
var mapquest = new L.TileLayer(mapquestUrl, {maxZoom: 18, attribution: mapquestAttrib, subdomains: subDomains});
mapquest.addTo(map);

$.getJSON('/pointinfo/', function(data) {
	district = JSON.parse(data['district'][0]);
	block = JSON.parse(data['block'][0]);
	cluster = JSON.parse(data['cluster'][0]);
	circle = JSON.parse(data['circle'][0]);
	project = JSON.parse(data['project'][0]);
	school = JSON.parse(data['school'][0]);
	preschool = JSON.parse(data['preschool'][0]);
	preschooldist = JSON.parse(data['preschooldistrict'][0]);
	add_markers();
});

var marker_cluster = new L.MarkerClusterGroup();

function add_markers () {
	var district_layer = L.geoJson(district).addTo(marker_cluster);
	var block_layer = L.geoJson(block).addTo(marker_cluster);
	var cluster_layer = L.geoJson(cluster).addTo(marker_cluster);
	var circle_layer = L.geoJson(circle).addTo(marker_cluster);
	var project_layer = L.geoJson(project).addTo(marker_cluster);
	var school_layer = L.geoJson(school).addTo(marker_cluster);
	var preschool = L.geoJson(preschool).addTo(marker_cluster);
	var preschooldist_layer = L.geoJson(preschooldist).addTo(marker_cluster);

	map.addLayer(marker_cluster);
}

