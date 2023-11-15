import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SingleDriverTest extends StatefulWidget {
  final String sessionId;
  final List<Map<String, dynamic>> mechanicUsers;

  SingleDriverTest({required this.sessionId, required this.mechanicUsers});

  @override
  _SingleDriverState createState() => _SingleDriverState();
}

class _SingleDriverState extends State<SingleDriverTest> {
  LocationData? _locationData;
  final MapController _mapController = MapController();
  final PopupController _popupLayerController = PopupController();
  IO.Socket? socket;
  bool isBookingButtonEnabled = true;
  String bookingStatus = 'No booking made';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _determinePosition();
    _initSocket();
    _loadInitialState();
  }

  Future<void> _determinePosition() async {
    var locationService = Location();
    var permissionStatus = await locationService.requestPermission();
    if (permissionStatus == PermissionStatus.granted) {
      var locData = await locationService.getLocation();
      setState(() {
        _locationData = locData;
      });
    } else {
      _showError('Location permission not granted');
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
      _loadInitialState();
    });

    socket!.onDisconnect((_) {
      print('disconnected from socket server');
    });

    socket!.onError((error) {
      _showError('Socket connection error: $error');
    });

    socket!.on('booking-update', (data) {
      setState(() {
        bookingStatus = data['status'];
      });
    });

  }

  void _initSocketListeners() {
    // Add any other listeners you need
  }

  void _handleRealTimeBookingUpdate(dynamic data) {
    setState(() {
      bookingStatus = data['status'];
      // Handle other data as needed
    });
  }

  void _bookMechanic(String mechanicId) {
    if (_locationData == null || !isBookingButtonEnabled) {
      _showError('Booking not available.');
      return;
    }

    setState(() {
      isBookingButtonEnabled = false;
      bookingStatus = 'Booking pending...';
    });

    if (socket == null) {
      _showError('Socket is not connected.');
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
          bookingStatus = 'Booking accepted';
        } else {
          bookingStatus = 'Booking failed';
          isBookingButtonEnabled = true;
        }
      });
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mechanic Map View'),
      ),
      body: Stack(
        children: [
          _locationData == null ? Center(child: CircularProgressIndicator()) : buildMap(),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: BookingStatusCard(
              status: bookingStatus,
              isEnabled: isBookingButtonEnabled,
              onBookMechanic: () => _bookMechanic('mechanicId'), // Replace with actual mechanicId
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMap() {
    var markersList = widget.mechanicUsers.map((user) => _buildMarker(user)).toList();
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(_locationData?.latitude ?? 0, _locationData?.longitude ?? 0),
        zoom: 13,
      ),
     children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: markersList),
      ],
    );
  }

  Marker _buildMarker(Map<String, dynamic> user) {
    var location = user['location'];
    var latitude = location['latitude'];
    var longitude = location['longitude'];

    return Marker(
      width: 40,
      height: 40,
      point: LatLng(latitude, longitude),
      builder: (ctx) => Icon(Icons.location_pin, color: Colors.red, size: 30),
    );
  }

  @override
  void dispose() {
    socket?.disconnect();
    super.dispose();
  }
}

class BookingStatusCard extends StatelessWidget {
  final String status;
  final bool isEnabled;
  final VoidCallback onBookMechanic;

  const BookingStatusCard({
    Key? key,
    required this.status,
    required this.isEnabled,
    required this.onBookMechanic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 2),
        ],
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Booking Status: $status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: isEnabled ? onBookMechanic : null,
            icon: Icon(Icons.build, color: Colors.white),
            label: Text('Book Mechanic'),
            style: ElevatedButton.styleFrom(
              primary: isEnabled ? Colors.green : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}
