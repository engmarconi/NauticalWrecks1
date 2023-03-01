//Decalre the map variable
var map, _markers;

// Load the KML file from source 
//var src = '../bin/Debug/ShipwreckPointData.kml';




function getData() {
    var kmlPath = '../ShipwreckPointData.kml';
    const googleMarkers = [];

    // This step is to load the KML file as XML Document
    XmlDocument kmlXml = new XmlDocument();
    kmlXml.Load(kmlPath);

    // This step is to print the kml content
    Response.ContentType = "text/xml";
    Response.Write(kmlXml.InnerXml);
    Response.End();
   

    var xmlDoc = new DOMParser().parseFromString(Response.getData, 'text/xml');
    for (const item of xmlDoc.getElementsByTagName('Placemark')) {
        let markers = item.getElementsByTagName('Point');
        /** MARKER PARSE **/
        for (const marker of markers) {
            var coords = marker.getElementsByTagName('coordinates')[0].childNodes[0].nodeValue.trim()
            let coord = coords.split(",");
            googleMarkers.push({
                lat: +coord[1],
                lng: +coord[0],
                name: item.getAttribute("id"),
                decription: item.getElementsByTagName('description')[0].childNodes[0].nodeValue.trim()
                //name:"", 
                //decription:""
            })
        }
    }
    setValue(googleMarkers);
}


getData();





// IIFE == Imediately Invoked function expression



function setValue(val) {
    _markers = val;
}

async function initMap() {
    console.log(_markers);
    let options = {
        center: new google.maps.LatLng(_markers[0].lat, _markers[0].lng),
        zoom: 3,
        maxZoom: 18,
        mapTypeId: 'terrain'
    };


    const infoWindow = new google.maps.InfoWindow();
    const latlngbounds = new google.maps.LatLngBounds();
    const map = new google.maps.Map(document.getElementById("map"), options);

    for (let i = 0; i < _markers.length; i++) {
        const data = _markers[i];
        const myLatlng = new google.maps.LatLng(data.lat, data.lng);
        const marker = new google.maps.Marker({
            position: myLatlng,
            map: map,
        });

        (function (marker, data) {
            google.maps.event.addListener(marker, "click", function (e) {
                infoWindow.setContent(`<div style = 'width:200px;min-height:40px'> 
                                          <strong>${data.name}</strong><br/>
                                              <p> ${data.decription}</p>
                                             Lat: ${data.lat} - Long: ${data.lng}
                                      </div>`);
                infoWindow.open(map, marker);
            });
        })(marker, data);

        latlngbounds.extend(marker.position);
    }
    // var bounds = new google.maps.LatLngBounds();
    map.setCenter(latlngbounds.getCenter());
    // map.fitBounds(latlngbounds);


    var kmlLayer = new google.maps.KmlLayer(src, {
        suppressInfoWindows: true,
        preserveViewport: false,
        map: map
    });

    // kml layer
    kmlLayer.addListener('click', function (event) {
        var content = event.featureData.infoWindowHtml;
        var testimonial = document.getElementById('capture');
        testimonial.innerHTML = content;
    });
}





