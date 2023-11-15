import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';


class SingleDriver extends StatefulWidget {
  final String sessionId;
  final List<Map<String, dynamic>> mechanicUsers;

  SingleDriver({
    required this.sessionId,
    required this.mechanicUsers,
  });

  @override
  _SingleDriverState createState() => _SingleDriverState();
 String mechanicUsersToString(LatLng currentUserLocation) {
  return mechanicUsers.map((user) {
    final mechanicLocation = LatLng(user['location']['latitude'], user['location']['longitude']);
    final distance = _calculateDistance(currentUserLocation, mechanicLocation);
    final mobileNumber = user['phoneNumber']; // Assuming the mobile number field is named 'mobileNumber'
    return '${user['firstName']} ${user['lastName']} - ${distance.toStringAsFixed(2)} km - Mobile: $mobileNumber';
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


class _SingleDriverState extends State<SingleDriver> {
  LocationData? _locationData;
  final MapController _mapController = MapController();
  final PopupController _popupLayerController = PopupController();
  IO.Socket? socket;
  bool isBookingButtonEnabled = true;
  String bookingStatus = 'No booking made';
  
  


 @override
void initState() {
  super.initState();
  _determinePosition();
  _initSocket();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    
    // Request booking status after the initial build
  });
}
Future<void> _loadInitialState() async {
  final prefs = await SharedPreferences.getInstance();
  final savedStatus = prefs.getString('bookingStatus') ?? 'No booking made';
  final isButtonEnabled = prefs.getBool('isBookingButtonEnabled') ?? true;

  setState(() {
    bookingStatus = savedStatus;
    isBookingButtonEnabled = isButtonEnabled;
  });
}
Future<void> _updateBookingState(String newStatus, bool isButtonEnabled) async {
  setState(() {
    bookingStatus = newStatus;
    isBookingButtonEnabled = isButtonEnabled;
  });
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('bookingStatus', newStatus);
  await prefs.setBool('isBookingButtonEnabled', isButtonEnabled);
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
    socket = IO.io('https://6b62-2001-4454-415-8a00-1c6a-3f66-7555-ddcc.ngrok-free.app/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket!.connect();

    socket!.onConnect((_) {
      print('connected to socket server');
      _initSocketListeners();
      // requestBookingStatus();
      _loadInitialState();
    });

    socket!.onDisconnect((_) {
      print('disconnected from socket server');
    });

    
  }
  void _initSocketListeners() {
    print('igud');
  socket!.on('booking-confirmation', (data) {
    print('yawork');
    _updateBookingState('Booking Confirmed', false);
    String bookingId = data['bookingId'];
        requestBookingStatus(bookingId); 
    });

  socket!.on('bookingResponse', (data) {
    if (data['status'] == 'Accepted') {
      _updateBookingState('Booking Accepted', false); // Button should remain disabled until booking is complete
    } else if (data['status'] == 'Declined') {
      _updateBookingState('Booking Declined', true);
    }
  });
  socket!.on('bookingCompleted', (data) {
    _updateBookingState('Booking Completed', true);
  });

  socket!.on('bookingCompleteConfirmation', (data) {
    _updateBookingState('Booking Completed', true); // Re-enable the booking button
  });

  socket!.on('bookingError', (errorMessage) {
    _updateBookingState('Error: $errorMessage', true);
  });
 
}
void requestBookingStatus(String bookingId) {
  socket!.emit('checkBookingId', {'bookingId': bookingId});

  // Listen for the server's response
  socket!.on('bookingIdCheckResult', (data) {
    if (data['exists'] == false) {
      // Enable the button if bookingId is not found
      _updateBookingState('Booking Available', true);
    }
  });
}







  void _bookMechanic(String mechanicId) {
    if (_locationData == null || !isBookingButtonEnabled) {
      print('Booking not available.');
      return;
    }

    setState(() {
      isBookingButtonEnabled = false; // Disable the button after booking
      bookingStatus = 'Booking pending...'; // Update booking status
    });


  if (socket == null) {
    print('Socket is not connected.');
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
  };

  socket!.emitWithAck('bookMechanic', bookingData, ack: (data) {
      setState(() {
        if (data != null) {
          bookingStatus = 'Booking accepted'; // Update status on acknowledgment
        } else {
          bookingStatus = 'Booking failed'; // Update status on failure
        }
      });
    });
  }
  



 @override
Widget build(BuildContext context) {
  String mechanicId = widget.mechanicUsers[0]['_id'];

  return Scaffold(
    appBar: AppBar(
      title: Text('Mechanic Map View'),
    ),
    body: Stack(
      children: [
        // Map Widget
        _locationData == null 
          ? Center(child: CircularProgressIndicator()) 
          : buildMap(context),

        // Overlay Widgets (Booking Status and Button)
        Positioned(
  bottom: 10,
  left: 10,
  right: 10,
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 4,
          spreadRadius: 2,
        ),
      ],
    ),
    padding: EdgeInsets.all(16.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Booking Status: $bookingStatus',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: isBookingButtonEnabled ? () => _bookMechanic(mechanicId) : null,
          icon: Icon(Icons.build, color: Colors.white),
          label: Text('Book Mechanic'),
          style: ElevatedButton.styleFrom(
            primary: isBookingButtonEnabled ? Colors.green : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      ],
    ),
  ),
),

    ],
    )
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
   return Column(
    children: <Widget>[
      
      Expanded(
        child: FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(_locationData?.latitude ?? 0, _locationData?.longitude ?? 0),
        zoom: 8,
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
            popupBuilder: (BuildContext context, Marker marker) => _buildPopup(marker),
          ),
      ),
        ],
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
  LatLng currentUserLocation = LatLng(_locationData?.latitude ?? 0, _locationData?.longitude ?? 0);
  String mechanicUsersStr = widget.mechanicUsersToString(currentUserLocation);

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 5,
    child: Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Align text to center
        children: <Widget>[
          Text(
            'Available Mechanics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
            textAlign: TextAlign.center, // Align text inside Text widget
          ),
          Divider(color: Colors.grey.shade400),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              mechanicUsersStr,
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center, // Align text inside Text widget
            ),
          ),
        ],
      ),
    ),
  );
}




}

  
     



