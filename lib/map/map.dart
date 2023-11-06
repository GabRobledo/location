import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart'; // Import location services


class MechanicMapPage extends StatefulWidget {
  final String sessionId;
  final List<Map<String, dynamic>> mechanicUsers; // Assuming DriverPage contains relevant mechanic data
  

  MechanicMapPage({
    Key? key,
    required this.sessionId,
    required this.mechanicUsers,
    
  }) : super(key: key);

  @override
  _MechanicMapPageState createState() => _MechanicMapPageState();
}

class _MechanicMapPageState extends State<MechanicMapPage> {
  late final MapController mapController;
  LatLng? initialLocation; // Changed to nullable LatLng

  LocationData? currentLocation; // Store the user's current location

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    getCurrentLocation(); // Get the user's current location
  }

  // Function to get the user's current location
  Future<void> getCurrentLocation() async {
    final location = Location();
    try {
      currentLocation = await location.getLocation();
      setState(() {
        // Update the initialLocation with the user's current location
        initialLocation = LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if initialLocation is not null
    if (initialLocation == null) {
      // If it's still null, we can show a loading spinner or some placeholder
      return Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: initialLocation, // This will now be non-null
                zoom: 12.0,
                maxZoom: 18.0,
                minZoom: 2.0,
              ),
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
                      point: initialLocation!, // This will now be non-null
                      builder: (context) => IconButton(
                        icon: Icon(Icons.location_on),
                        onPressed: () {
                          // Handle marker click here
                        },
                      ),
                    ),
                    // You might want to add more markers for each mechanic here
                  ],
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: () {
                  // Add your "Book Mechanic" action here
                },
                icon: Icon(Icons.build),
                label: Text("Book Mechanic"),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
