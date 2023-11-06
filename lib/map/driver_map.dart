import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:location/location.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
    socket = IO.io('https://8cc2-49-145-135-84.ngrok-free.app:3000', <String, dynamic>{
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
  String mechanicId = '123';

  return Scaffold(
    appBar: AppBar(
      title: Text('Mechanic Map View'),
    ),
    body: _locationData == null ? Center(child: CircularProgressIndicator()) : buildMap(context),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        // Call the function with the mechanic ID
        // Ensure that 'widget.mechanicId' represents the selected mechanic's ID
        _bookMechanic(mechanicId);
      },
      label: Text('Book Mechanic'),
      icon: Icon(Icons.build),
      backgroundColor: Colors.red,
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
      // MarkerClusterLayerWidget(  // Marker cluster layer wrapped in a MarkerClusterLayerWidget
      //   options: MarkerClusterLayerOptions(
      //     maxClusterRadius: 120,
      //     size: Size(40, 40),
      //     fitBoundsOptions: FitBoundsOptions(
      //       padding: EdgeInsets.all(50),
      //     ),
      //     markers: widget.mechanicUsers.map((user) {
      //       final location = user['location'];
      //       final latitude = location != null ? location['latitude'] as double? : null;
      //       final longitude = location != null ? location['longitude'] as double? : null;
      //       if (latitude != null && longitude != null) {
      //         return Marker(
      //           width: 40,
      //           height: 40,
      //           point: LatLng(latitude, longitude),
      //           builder: (ctx) => Icon(
      //             Icons.location_pin,
      //             color: Colors.red, // Marker color red to match theme
      //             size: 30,
      //           ),
      //         );
      //       }
      //       return null;
      //     }).whereType<Marker>().toList(), // Exclude nulls from the marker list
      //     builder: (context, markers) {
      //       return FloatingActionButton(
      //         child: Text(markers.length.toString()),
      //         onPressed: null,
      //       );
        
      //     },
      //   ),
      //   ),
    
    
    
      PopupMarkerLayerWidget(
          options: PopupMarkerLayerOptions(
            markers: markersList,
            popupController: _popupLayerController,
            popupBuilder: (BuildContext context, Marker marker) => _buildPopup(marker),
          ),
        ),
      ],
    );
  }
  Marker? _buildMarker(Map<String, dynamic> user) {
  final location = user['location'];
  final latitude = location != null ? location['latitude'] as double? : null;
  final longitude = location != null ? location['longitude'] as double? : null;

  // Instead of throwing an exception, you could return null or handle this case differently.
  if (latitude == null || longitude == null) {
    debugPrint('Invalid location data for user: $user');
    return null;
  }
    return Marker(
      width: 40,
      height: 40,
      point: LatLng(latitude, longitude),
      builder: (ctx) => Icon(
        Icons.location_pin,
        color: Colors.red, // Marker color red to match theme
        size: 30,
      ),
      // You can also add an anchor or other properties to the Marker if needed
    );
    
  }
  Widget _buildPopup(Marker marker) {
    // This is a simple popup content with basic styling.
    // Customize this method to fit your own popup content design.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Mechanic at ${marker.point}'),
      ),
    );
  }
}
  
     



