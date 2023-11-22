import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:raamb_app/service/mongo_service.dart';
import 'dart:convert';

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
  bool isBookingButtonEnabled = false;
  String bookingStatus = 'No booking made';

  @override
  void initState() {
    super.initState();
    _initialize();
    _fetchTransactions();
  }

  Future<void> _initialize() async {
    await _determinePosition();
    _initSocket();
    
  
  }
  Future<void> _fetchTransactions() async {
  int retryCount = 0;
  const int maxRetries = 10; // Maximum number of retries
  const int retryDelay = 2; // Delay in seconds between retries

  // Convert mechanicUsers to a list of their _id values
  List<String> mechanicIds = widget.mechanicUsers.map((mechanic) => mechanic['_id'].toString()).toList();

  while (retryCount < maxRetries) {
    try {
      var transactions = await getTransactions(widget.sessionId, mechanicIds);
      var hasBooking = await hasBookings(widget.sessionId, mechanicIds);
      
      bool hasOngoingTransaction = false;
      String latestStatus = 'No booking made'; // Initializing latestStatus with a default value

      if (hasBooking) {
        // If there is a booking, set status to "Booking pending"
        latestStatus = 'Booking pending';
        hasOngoingTransaction = true; // Assuming a booking implies an ongoing transaction
      } else if (transactions.isNotEmpty) {
        transactions.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
        var latestTransaction = transactions.first;
        if (latestTransaction['action'] == 'On-going') {
          hasOngoingTransaction = true;
          latestStatus = 'Booking accepted';
        } else if (latestTransaction['action'] == 'Completed' || latestTransaction['action'] == 'Declined') {
          hasOngoingTransaction = false;
        }
      }

      setState(() {
        bookingStatus = latestStatus;
        isBookingButtonEnabled = !hasOngoingTransaction;
      });

      break;
    } catch (error) {
      if (error.toString().contains('MongoDart Error: No master connection')) {
        retryCount++;
        print('Attempt $retryCount: Error fetching transactions: $error');
        if (retryCount >= maxRetries) {
          _showError('Error fetching transactions after $maxRetries attempts');
          break;
        }
        await Future.delayed(Duration(seconds: retryDelay));
      } else {
        print('Error fetching transactions: $error');
        _showError('Error fetching transactions');
        break;
      }
    }
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
    } else {
      _showError('Location permission not granted');
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

    socket!.onError((error) {
      _showError('Socket connection error: $error');
    });

   socket!.on('bookingResponse', (data) {
      print('Booking response: $data');
      setState(() {
        bookingStatus = 'Booking ${data['status']}';
        isBookingButtonEnabled = data['status'] == 'Declined';
      });
    });

    socket!.on('bookingError', (errorMessage) {
      print('Booking error: $errorMessage');
      setState(() {
        bookingStatus = 'Booking error';
        isBookingButtonEnabled = true;
      });
    });

  }


  void _bookMechanic(String mechanicId) {
    print('$mechanicId');
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
          print ('buuk');
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



  @override
Widget build(BuildContext context) {
  String mechanicId = '';
  String mechanicName = 'Mechanic';  // Default name

  if (widget.mechanicUsers.isNotEmpty) {
    mechanicId = widget.mechanicUsers[0]['_id'] ?? '';
    mechanicName = widget.mechanicUsers[0]['firstName'] ?? 'Mechanic';  // Fetch the mechanic's name
  }

  return Scaffold(
    appBar: AppBar(
      title: Text(mechanicName),  // Use the mechanic's name here
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
            onBookMechanic: () => _bookMechanic(mechanicId),
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
