import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  final LatLng initialLocation =
      LatLng(37.7749, -122.4194); // San Francisco, CA

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Flutter Map Page'),
      // ),
      body: FlutterMap(
        options: MapOptions(
          center: initialLocation,
          zoom: 12.0,
          maxZoom: 18.0,
          minZoom: 2.0,
        ),
        mapController: mapController,
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 40.0,
                height: 40.0,
                point: initialLocation,
                builder: (context) => IconButton(
                  icon: Icon(Icons.location_on),
                  onPressed: () {
                    // Handle marker click here
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () {
          // Add your "Book Mechanic" action here
          // For example, you can navigate to a new page or show a dialog.
        },
        style: ElevatedButton.styleFrom(
          primary: Colors.red, // Set the button color to red
        ),
        child: Text("Book Mechanic", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: MapPage(),
  ));
}
