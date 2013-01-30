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
var cluster_cluster = new L.MarkerClusterGroup({showCoverageOnHover: false});
var school_cluster = new L.MarkerClusterGroup({showCoverageOnHover: false});
var circle_cluster = new L.MarkerClusterGroup({showCoverageOnHover: false});
var preschool_cluster = new L.MarkerClusterGroup({showCoverageOnHover: false});
var current_layers = new L.LayerGroup();
// var markerList = []
map.addLayer(current_layers);

function initialize () {

	district_layer = L.geoJson(district, {onEachFeature: onEachFeature});
	block_layer = L.geoJson(block, {onEachFeature: onEachFeature});
	cluster_layer = L.geoJson(cluster, {onEachFeature: onEachFeature}).addTo(cluster_cluster);
	circle_layer = L.geoJson(circle, {onEachFeature: onEachFeature}).addTo(circle_cluster);
	project_layer = L.geoJson(project, {onEachFeature: onEachFeature});
	preschool_layer = L.geoJson(preschool, {onEachFeature: onEachFeature});
	preschooldist_layer = L.geoJson(preschooldist, {onEachFeature: onEachFeature});
	preschool_layer.addTo(preschool_cluster);
	preschooldist_layer.addTo(preschool_cluster);
	school_layer = L.geoJson(school, {onEachFeature: onEachFeature});
	school_layer.addTo(school_cluster);

	current_layers.addLayer(school_cluster);
	current_layers.addLayer(preschool_cluster);

	overlays = {
		"Districts": district_layer,
		"Blocks": block_layer,
		"Clusters": cluster_cluster,
		"Circles": circle_cluster,
		"Projects": project_layer,
		"Preschools": preschool_cluster,
		"Schools": school_cluster
	};

	L.control.layers(null, overlays, {position:'bottomright', collapsed:false}).addTo(map);
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

	}

	else if (zoom_level == 10) {
		current_layers.clearLayers();
		current_layers.addLayer(cluster_cluster);
	}

	else if (zoom_level == 11) {
		current_layers.clearLayers();
		current_layers.addLayer(circle_cluster);
		current_layers.addLayer(project_layer);
	}

	else if (zoom_level == 12) {
		current_layers.clearLayers();
		current_layers.addLayer(school_cluster);
	}

		
}

function onEachFeature(feature, layer) {
    if (feature.properties) {
        layer.bindPopup(feature.properties.name);
    }
}
