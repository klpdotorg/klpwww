var southWest = new L.LatLng(11.57, 73.87),
northEast = new L.LatLng(18.45, 78.57),
bounds = new L.LatLngBounds(southWest, northEast);

var bangalore = L.latLng([12.9719,77.5937]);
var district, block, cluster, circle, project, school, preschool, preschooldist;

var map = L.map('map', {attributionControl: false, maxBounds: bounds}).setView(bangalore, 10);
var mapquestUrl = 'http://{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png', subDomains = ['otile1','otile2','otile3','otile4'];
var mapquest = new L.TileLayer(mapquestUrl, {maxZoom: 18, subdomains: subDomains});

mapquest.addTo(map);

var school_cluster = new L.MarkerClusterGroup({showCoverageOnHover: false, 
	iconCreateFunction: function(cluster) {
		return new L.DivIcon({ className:'marker-cluster marker-cluster-school', style:'style="margin-left: -20px; margin-top: -20px; width: 40px; height: 40px; transform: translate(293px, 363px); z-index: 363;"', html: "<div><span>" + cluster.getChildCount() + "</span></div>" });
	}});

var current_layers = new L.LayerGroup();
var current_filter = new L.LayerGroup();
var rteLowerPrimary  = new L.LayerGroup();
var rteHigherPrimary = new L.LayerGroup();

function getURLParameter(name) {
	return decodeURI(
		(RegExp(name + '=' + '(.+?)(&|$)').exec(location.search)||[,])[1]
		);
}

var regionParameter = getURLParameter('region');
var region = (regionParameter === 'undefined') ? '' : regionParameter;

map.addLayer(current_layers);
map.addLayer(current_filter);

$.getJSON('/pointinfo/', function(data) {
	district = JSON.parse(data['district'][0]);
	block = JSON.parse(data['block'][0]);
	cluster = JSON.parse(data['cluster'][0]);
	circle = JSON.parse(data['circle'][0]);
	project = JSON.parse(data['project'][0]);
	preschooldist = JSON.parse(data['preschooldistrict'][0]);
	initialize();
});

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

var preschooldistrictIcon = L.icon({
	iconUrl:'/images/icons/pdistrict.png',
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

function initialize() {
	district_layer = L.geoJson(district, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: districtIcon});}, onEachFeature: onEachFeature});

	preschooldist_layer = L.geoJson(preschooldist, {pointToLayer: function(feature, latlng){
	return L.marker(latlng, {icon: preschooldistrictIcon});}, onEachFeature: onEachFeature});

	block_layer = L.geoJson(block, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: blockIcon});}, onEachFeature: onEachFeature});

	cluster_layer = L.geoJson(cluster, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: clusterIcon});}, onEachFeature: onEachFeature});

	circle_layer = L.geoJson(circle, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: circleIcon});}, onEachFeature: onEachCircle});

	project_layer = L.geoJson(project, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: projectIcon});}, onEachFeature: onEachFeature});

	current_layers.addLayer(district_layer);
	current_layers.addLayer(preschooldist_layer);	
	current_layers.addLayer(block_layer);
	// current_layers.addLayer(cluster_layer);
	// current_layers.addLayer(circle_layer);
	// current_layers.addLayer(project_layer);


	overlays = {
		"<img src='/images/icons/pdistrict.png' height='25px' /> Preschool Districts": preschooldist_layer,
		"<img src='/images/icons/project.png' height='25px' /> Preschool Projects": project_layer,
		"<img src='/images/icons/circle.png' height='25px' /> Preschool Circles": circle_layer,
		// "<img src='/images/icons/preschool.png' height='25px' /> Preschools": preschool_cluster,
		"<img src='/images/icons/district.png' height='25px' /> School Districts": district_layer,
		"<img src='/images/icons/block.png' height='25px' /> School Blocks": block_layer,
		"<img src='/images/icons/cluster.png' height='25px' /> School Clusters": cluster_layer,
		// "<img src='/images/icons/school.png' height='25px' /> Schools": school_cluster,
		"LPS RTE 1 KM": rteLowerPrimary,
		"HPS RTE 3 KM": rteHigherPrimary,
	};

	// zoom.addTo(map);

	L.control.attribution({position: 'bottomright'})
	.addAttribution("&copy; <a href='http://osm.org/copyright'>OpenStreetMap</a>")
	.setPrefix("")
	.addTo(map);

	new L.Control.GeoSearch({position: 'topright',
		provider: new L.GeoSearch.Provider.Google({
			region: region
		}), zoomLevel: 15, country: 'India', searchLabel: 'Search for a neighborhood...'
	}).addTo(map);

	L.control.layers(null, overlays, {position:'topright', collapsed:true}).addTo(map);
}



$('a.toggles').click(function() {
    $('a.toggles i').toggleClass('icon-chevron-left icon-chevron-right');

    $('#sidebar').animate({
        width: 'toggle'
    }, 0);
    $('#content').toggleClass('span12 span10');
    $('#content').toggleClass('no-sidebar');
    map.invalidateSize();
    map.setView(bangalore, 10, true);
});

function onEachFeature(feature, layer) {
	if (feature.properties) {
		layer.bindPopup(feature.properties.name);
	}
}

function onEachCircle(feature, layer) {
	if (feature.properties) {
		layer.on('click', circlePopup);
	}
}

function circlePopup() {
	marker = this;
	$.getJSON('/info/circle/'+marker.feature.id, function(data) {
		popupContent = "<b>"+marker.feature.properties.name+"</a></b>"+"<hr> Boys: "+
		String(data['numBoys'])+" | Girls: "+String(data['numGirls'])+" | Total: <b>"+String(data['numStudents'])+"</b><br />Schools: "+String(data['numSchools']);
		marker.bindPopup(popupContent).openPopup();
	});	
}

map.on('zoomend', update_map);

function update_map() {
	zoom_level = map.getZoom();
	if (zoom_level == 8) {
		current_layers.clearLayers();
		current_layers.addLayer(district_layer);
		current_layers.addLayer(preschooldist_layer);
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

//Filters

filters = d3.selectAll('.filters li').on('click', function(d,i){applyFilter(this);});
function applyFilter (filter) {
	identifier = d3.select(filter).attr('id');
	$.getJSON('/diseinfo/'+identifier, function(data) {
		school = JSON.parse(data['school'][0]);
		setupLayer();
	});
}

function setupLayer() {
	school_layer = L.geoJson(school, {pointToLayer: function(feature, latlng){
	return L.marker(latlng, {icon: schoolIcon});}, onEachFeature: onEachSchool});

	school_layer.addTo(school_cluster);
	school_cluster.addTo(current_filter);
}

function onEachSchool(feature, layer) {
	if (feature.properties) {
		layer.on('click', schoolPopup);
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