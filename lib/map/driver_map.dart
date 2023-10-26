import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:location/location.dart';
import '../pages/driver_page.dart';

class MapPage extends StatelessWidget {
  final String sessionId;
  LocationData? _locationData;
  double? latitude = 0.0; // Initialize latitude with your value
  double? longitude = 0.0; // Initialize longitude with your value
  final List<Map<String, dynamic>> mechanicUsers;

  MapPage({required this.sessionId, required this.mechanicUsers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Page'),
      ),
      body: latitude != null && longitude != null
          ? buildMap()
          : Center(
              child: Text("Latitude and Longitude are not available."),
            ),
    );
  }

  Widget buildMap() {
    final double? latitude = _locationData?.latitude;
    final double? longitude = _locationData?.longitude;
    return FlutterMap(
      options: MapOptions(
        center: LatLng(latitude ?? 50, longitude ?? 50),
        zoom: 18,
        maxZoom: 20,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
          // userAgentPackageName: 'com.raamb_app.app',
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 120,
            size: Size(40, 40),
            fitBoundsOptions: FitBoundsOptions(
              padding: EdgeInsets.all(50),
            ),
            markers: mechanicUsers
                .map((user) {
                  final location = user['location'];
                  final latitude =
                      location != null ? location['latitude'] as double? : null;
                  final longitude = location != null
                      ? location['longitude'] as double?
                      : null;

                  if (latitude != null && longitude != null) {
                    return Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(latitude, longitude),
                      builder: (ctx) => Container(
                        child: Icon(
                          Icons.person_pin,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    );
                  } else {
                    // Handle cases where location data is missing or invalid
                    return null;
                  }
                })
                .whereType<Marker>()
                .toList(),
            builder: (context, markers) {
              // Define how the cluster markers should be rendered here
              // For example, you can return a container with the number of markers
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.blue,
                ),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
