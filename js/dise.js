var southWest = new L.LatLng(11.57, 73.87),
northEast = new L.LatLng(18.45, 78.57),
bounds = new L.LatLngBounds(southWest, northEast);

var bangalore = L.latLng([12.9719,77.5937]);
var district, block, cluster, circle, project, school, preschool, preschooldist;

var map = L.map('map', {attributionControl: false, maxBounds: bounds}).setView(bangalore, 9);
var mapquestUrl = 'http://{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png', subDomains = ['otile1','otile2','otile3','otile4'];
var mapquest = L.tileLayer.grayscale(mapquestUrl, {maxZoom: 18, subdomains: subDomains});

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

	block_layer = L.geoJson(block, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: blockIcon});}, onEachFeature: onEachFeature});

	cluster_layer = L.geoJson(cluster, {pointToLayer: function(feature, latlng){
		return L.marker(latlng, {icon: clusterIcon});}, onEachFeature: onEachFeature});

	current_layers.addLayer(district_layer);
	current_layers.addLayer(block_layer);

	overlays = {
		"<img src='/images/icons/district.png' height='25px' /> Districts": district_layer,
		"<img src='/images/icons/block.png' height='25px' /> Blocks": block_layer,
		"<img src='/images/icons/cluster.png' height='25px' /> Clusters": cluster_layer,
		"<img src='/images/icons/school.png' height='25px' /> Schools": school_cluster,
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
	new toggleFilter().addTo(map);
}


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
	}

	else if (zoom_level == 9) {
		current_layers.clearLayers();
		current_layers.addLayer(block_layer);
	}

	else if (zoom_level == 10) {
		current_layers.clearLayers();
		current_layers.addLayer(cluster_layer);
	}

	else if (zoom_level >= 11) {
		current_layers.clearLayers();
		current_layers.addLayer(school_cluster);
	}
}

var spin_layer = L.geoJson(null).addTo(map);

//Filters

filters = d3.selectAll('.filters li').on('click', function(d,i){applyFilter(this);});
function applyFilter (filter) {
	current_filter.clearLayers();
	identifier = d3.select(filter).attr('id');
	d3.selectAll('.filters li').classed('active', false);
	d3.select(filter).classed('active', true);
	spin_layer.fire('data:loading');
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
	spin_layer.fire('data:loaded');

}

function trueFalse (status) {
	if (status == 'yes') {
		return "<i class='small icon-ok'></i>";
	} else{
		return "<i class='small icon-remove'></i>"
	};
}

function onEachSchool(feature, layer) {
	if (feature.properties) {
		popupContent = "<b><a href='schoolpage/school/"+feature.id+"' target='_blank'>"+feature.properties.name+
		"</a></b><hr>DISE: <b>"+String(feature.properties.disecode)+"</b> | Boys: "+String(feature.properties.boys_count)+" | Girls: "+
		String(feature.properties.girls_count)+"<br> Classes: "+String(feature.properties.class_count)+
		" | PTR: "+String(feature.properties.ptr)+"<br> Library "+trueFalse(feature.properties.has_library)+
		" | Toilets "+trueFalse(feature.properties.has_toilet)+" | HM "+trueFalse(feature.properties.has_hm)+
		" | Ramps "+trueFalse(feature.properties.has_ramps);

		layer.bindPopup(popupContent);
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

// Filter Toggle Control

var toggleFilter = L.Control.extend({
	options: {
		position: 'bottomleft'
	},

	onAdd: function (map) {
		var container = L.DomUtil.create('div', 'leaflet-control');
		button = "<button class='btn btn-small toggles'>Filters <i class='icon-chevron-left'></i></button>";
		L.DomEvent
		.addListener(container, 'click', L.DomEvent.stopPropagation)
		.addListener(container, 'click', L.DomEvent.preventDefault)
		.addListener(container, 'click', this.clicked);
		container.innerHTML = button;
		return container;
	},

	clicked: function stop() {
	    $('.toggles i').toggleClass('icon-chevron-left icon-chevron-right');
	    $('#sidebar').animate({
	        width: 'toggle'
	    }, 0);
	    $('#content').toggleClass('span12 span10');
	    $('#content').toggleClass('no-sidebar');
	    map.invalidateSize();
	    // map.setView(bangalore, 10, true);
	}
});