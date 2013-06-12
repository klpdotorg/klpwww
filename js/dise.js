var southWest = new L.LatLng(11.57, 73.87),
northEast = new L.LatLng(18.45, 78.57),
bounds = new L.LatLngBounds(southWest, northEast);

var bangalore = L.latLng([12.9719,77.5937]);

var map = L.map('map', {zoomControl: false, attributionControl: false, maxBounds: bounds}).setView(bangalore, 10);
var mapquestUrl = 'http://{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png', subDomains = ['otile1','otile2','otile3','otile4'];
var mapquest = new L.TileLayer(mapquestUrl, {maxZoom: 18, subdomains: subDomains});

mapquest.addTo(map);

zoom = new L.Control.Zoom({position:'topleft'});

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
