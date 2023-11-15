import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:location/location.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:math' as math;
import 'package:collection/collection.dart';
class MapPage extends StatefulWidget {
  final String sessionId;
  final List<Map<String, dynamic>> mechanicUsers;
   // Add this line

  MapPage({
    required this.sessionId,
    required this.mechanicUsers,
    // Add this line
  });

  @override
  _MapPageState createState() => _MapPageState();
  String mechanicUsersToString(LatLng currentUserLocation) {
  return mechanicUsers.map((user) {
    final mechanicLocation = LatLng(user['location']['latitude'], user['location']['longitude']);
    final distance = _calculateDistance(currentUserLocation, mechanicLocation);
    return '${user['firstName']} ${user['lastName']} - ${distance.toStringAsFixed(2)} km';
  }).join('\n'); // Join the strings with a newline separator
}
double _calculateDistance(LatLng start, LatLng end) {
  const double radius = 6371; // Earth's radius in kilometers
  final lat1 = _toRadians(start.latitude);
  final lon1 = _toRadians(start.longitude);
  final lat2 = _toRadians(end.latitude);
  final lon2 = _toRadians(end.longitude);

  final dlat = lat2 - lat1;
  final dlon = lon2 - lon1;

  final a = math.pow(math.sin(dlat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dlon / 2), 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return radius * c;
}

double _toRadians(double degree) {
  return degree * math.pi / 180;
}
}

class _MapPageState extends State<MapPage> {
  LocationData? _locationData;
  final MapController _mapController = MapController();
  final PopupController _popupLayerController = PopupController();
  IO.Socket? socket;

  @override
void initState() {
  super.initState();
  _determinePosition();
  _initSocket();
  
  // Setup the bookingStatus listener here
  socket!.on('bookingStatus', (data) {
    // Handle booking status
  });
}


  Future<void> _determinePosition() async {
    var locationService = Location();
    var permissionStatus = await locationService.requestPermission();
    if (permissionStatus == PermissionStatus.granted) {
      var locData = await locationService.getLocation();
      setState(() {
        _locationData = locData;
      });
    }
  }

  void _initSocket() {
    socket = IO.io('https://63a5-2001-4454-415-8a00-d420-28e1-55cb-d200.ngrok-free.app/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket!.connect();

    socket!.onConnect((_) {
      print('connected to socket server');
      // Perform any on connect actions here
    });

    socket!.onDisconnect((_) {
      print('disconnected from socket server');
      // Handle disconnection here
    });

    // Listen to other socket events, e.g., 'bookingStatus', 'mechanicResponse'
  }

  void _bookMechanic(String mechanicId) { 
    print('book1');// mechanicId is passed as a parameter now
  if (_locationData == null) {
    print('Location data is not available.');
    return;
  }

  var bookingData = {
    'userId': widget.sessionId,
    'mechanicId': mechanicId,
    'userLocation': {
      'latitude': _locationData!.latitude,
      'longitude': _locationData!.longitude,
    },
    'bookingTime': DateTime.now().toIso8601String(),
    // Add other booking details as needed
  };

  socket!.emit('bookMechanic', bookingData);
  print('book');

  // Handle the booking response via a listener
  socket!.on('bookingStatus', (data) {
    print('Booking status received: $data');
    // Parse the response and update UI based on booking status
    var bookingStatus = data['status']; // Assuming 'status' is part of the response
    var bookingId = data['bookingId']; // Assuming each booking has a unique 'bookingId'

    switch (bookingStatus) {
      case 'confirmed':
        // Handle confirmed booking
        break;
      case 'rejected':
        // Handle rejected booking
        break;
      // Add more cases as needed
      default:
        // Handle unknown status
    }
  });
}


  @override
Widget build(BuildContext context) {

  return Scaffold(
    appBar: AppBar(
      title: Text('Mechanic Map View'),
    ),
    body: _locationData == null ? Center(child: CircularProgressIndicator()) : buildMap(context),
    
  );
}

  @override
  void dispose() {
    socket?.disconnect();
    super.dispose();
  }
  
 
  @override
Widget buildMap(BuildContext context) {
    var markersList = widget.mechanicUsers.map((user) => _buildMarker(user)).whereType<Marker>().toList();
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(_locationData?.latitude ?? 0, _locationData?.longitude ?? 0),
        zoom: 13,
        onTap: (_, __) => _popupLayerController.hideAllPopups(), // Hide popup when the map is tapped
      ),
    children: <Widget>[ // The map layers are defined as children
      TileLayer(  // Tile layer wrapped in a TileLayerWidget
         
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        
      ),
      
    
      PopupMarkerLayerWidget(
  options: PopupMarkerLayerOptions(
    markers: markersList,
    popupController: _popupLayerController,
    popupBuilder: (BuildContext context, Marker marker) {
      var user = _findMechanicByLocation(marker.point);
      return _buildPopup(user);
    },
  ),
),

      ],
    );
  }
  Marker? _buildMarker(Map<String, dynamic> user) {
  final location = user['location'];
  final latitude = location != null ? location['latitude'] as double? : null;
  final longitude = location != null ? location['longitude'] as double? : null;

  if (latitude == null || longitude == null) {
    return null; // It's now acceptable to return null
  }

  return Marker(
    width: 80,
    height: 80,
    point: LatLng(latitude, longitude),
    builder: (ctx) => Icon(Icons.location_pin, color: Colors.red, size: 30),
    anchorPos: AnchorPos.align(AnchorAlign.top),
  );
}

Map<String, dynamic>? _findMechanicByLocation(LatLng location) {
  return widget.mechanicUsers.firstWhereOrNull(
    (user) => LatLng(user['location']['latitude'], user['location']['longitude']) == location
  );
}





  Widget _buildPopup(Map<String, dynamic>? user) {
  if (user == null) {
    return Container(); // Return an empty container if the user is null
  }

  String mechanicName = '${user['firstName']} ${user['lastName']}';
  String mechanicMobile = user['phoneNumber'] ?? 'Not Available'; // Retrieve mobile number
  LatLng currentUserLocation = LatLng(_locationData?.latitude ?? 0, _locationData?.longitude ?? 0);
  double distance = widget._calculateDistance(currentUserLocation, LatLng(user['location']['latitude'], user['location']['longitude']));

  // UI improvements
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            mechanicName,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          Divider(color: Colors.grey.shade400),
          Text(
            '${distance.toStringAsFixed(2)} km away',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 10), // Add spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, color: Colors.green), // Phone icon
              SizedBox(width: 5), // Spacing between icon and text
              Text(
                mechanicMobile,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          // Optionally add a call button
          SizedBox(height: 10), // Spacing before button
          ElevatedButton.icon(
            icon: Icon(Icons.call),
            label: Text("Call Mechanic"),
            onPressed: () {
              // Call action
            },
          ),
        ],
      ),
    ),
  );
}
}
  
     



