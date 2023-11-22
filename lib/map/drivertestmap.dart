import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPageTest extends StatefulWidget {
  final String sessionId;
  final List<Map<String, dynamic>> mechanicUsers;
  

  MapPageTest({
    required this.sessionId,
    required this.mechanicUsers,
  });

  @override
  _MapPageState createState() => _MapPageState();
  

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

class _MapPageState extends State<MapPageTest> {
  LocationData? _locationData;
  final MapController _mapController = MapController();
  final PopupController _popupLayerController = PopupController();
  IO.Socket? socket;
  
  String _getVehicleTypes(List<dynamic> vehicleTypes) {
    return vehicleTypes.join(', ');
  }

   Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
      }
      return 'No address available';
    } catch (e) {
      return 'Failed to get address';
    }
  }


  @override
  void initState() {
    super.initState();
    _determinePosition();
    _initSocket();
  }
  Future<void> callUser(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Failed to make the phone call.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
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
    socket = IO.io('https://cf86-2001-4454-415-8a00-20cb-be4f-7389-765c.ngrok-free.app/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket!.connect();

    socket!.onConnect((_) {
      print('connected to socket server');
    });

    socket!.onDisconnect((_) {
      print('disconnected from socket server');
    });

    // Listen to other socket events, e.g., 'bookingStatus', 'mechanicResponse'
  }

  void _bookMechanic(String mechanicId) {
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
    };

    socket!.emit('bookMechanic', bookingData);
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mechanic Map View'),
        backgroundColor: Colors.red, // Updated to red theme
      ),
      body: _locationData == null
          ? Center(child: CircularProgressIndicator())
          : buildMap(context),
    );
  }

  Widget buildMap(BuildContext context) {
    var markersList = widget.mechanicUsers
        .map((user) => _buildMarker(user))
        .whereType<Marker>()
        .toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(_locationData?.latitude ?? 0, _locationData?.longitude ?? 0),
        zoom: 13,
        onTap: (_, __) => _popupLayerController.hideAllPopups(),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
          additionalOptions: {
            'accessToken': 'https://www.openstreetmap.org/oauth/access_token', // Optional: Use Mapbox or other tile providers for better visuals
            'id': 'mapbox/streets-v11', // Optional: Mapbox map style
          },
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
      return null;
    }

    return Marker(
      width: 80,
      height: 80,
      point: LatLng(latitude, longitude),
      builder: (ctx) => Icon(Icons.location_pin, color: Colors.red, size: 30), // Marker color updated to red
      anchorPos: AnchorPos.align(AnchorAlign.top),
    );
  }

  Map<String, dynamic>? _findMechanicByLocation(LatLng location) {
    return widget.mechanicUsers.firstWhereOrNull(
      (user) => LatLng(user?['location']['latitude'], user?['location']['longitude']) == location
    );
  }

  Widget _buildPopup(Map<String, dynamic>? user) {
    if (user == null) {
      return Container();
    }

    String mechanicName = '${user['firstName']} ${user['lastName']}';
    String mechanicMobile = user['phoneNumber'] ?? 'Not Available';
    String vehicleTypes = _getVehicleTypes(user['VehicleType'] ?? []);
    LatLng mechanicLocation = LatLng(user['location']['latitude']??'', user['location']['longitude']??
    '');
    LatLng currentUserLocation = LatLng(_locationData?.latitude ?? 0, _locationData?.longitude ?? 0);
    double distance = widget._calculateDistance(currentUserLocation, mechanicLocation);

    return FutureBuilder<String>(
      future: _getAddressFromLatLng(mechanicLocation.latitude, mechanicLocation.longitude),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        String address = snapshot.data ?? 'Address loading...';
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  mechanicName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Divider(color: Colors.grey.shade400),
                Text(
                  '${distance.toStringAsFixed(2)} km away',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.car_repair, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(child: Text(vehicleTypes)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(child: Text(address)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.green),
                    SizedBox(width: 8),
                    Text(mechanicMobile),
                  ],
                ),
               SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.call),
                label: Text("Call Mechanic"),
                onPressed: () {
                  callUser(mechanicMobile);
                },
                style: ElevatedButton.styleFrom(primary: Colors.red),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    socket?.disconnect();
    super.dispose();
  }
}
