import 'dart:async';
import '../drawer/terms_and_conditions.dart';
import '../drawer/help_center.dart';
import '../drawer/settings.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:raamb_app/main.dart';
import 'dart:math';
import '../service/mongo_service.dart';
import '../utils/location.dart';
import '../service/socket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import '../profile/profile_overview.dart';
import '../auth/login_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../profile/profile_overview.dart';
import '../pages/driver_page.dart';
import '../transaction/transaction_list.dart';
import '../drawer/favorites.dart';

class DriverPage extends StatefulWidget {
  final String sessionId;
  final List<String> selectedVehicleTypes = [];

  final TextEditingController _textController = TextEditingController();

  final List<String> _messages = [];

  DriverPage({required this.sessionId});

  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  LocationData? _locationData;
  Location _location = Location();
  String? _locationName;
  String? userId;
  Timer? _timer;
  List<Map<String, dynamic>> mechanicUsers = [];
  List<Map<String, dynamic>> filteredMechanicUsers = [];
  final SocketService socketService = SocketService();
  int _selectedIndex = 0;
  final List<String> _messages = [];
  IO.Socket? socket;
  final TextEditingController _textController = TextEditingController();
  LatLng? locationData;
  LatLng? selectedUserLocation; // Add this variable
  List<LatLng> polylineCoordinates = []; // Corrected data type
  final MapController mapController = MapController();
  String? sessionId;
  List<Map<String, dynamic>> driverUsers = [];

  // final List<String> _messages = [];

  TextEditingController searchController = TextEditingController();

  String? selectedVehicleTypes;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _startLocationTimer();
    updateUserStatus(widget.sessionId, true);
    fetchMechanicUsers();
    fetchPolylinePoints();
    socket = IO.io('https://8cc2-49-145-135-84.ngrok-free.app');
    // socket?.connect();

    //   fetchChatHistory().then((chatHistory){
    //   setState(() {
    //     _messages.addAll(chatHistory);
    //   });
    // });
    (chatHistory) {
      setState(() {
        _messages.addAll(chatHistory);
      });
    };
    socketService.startSocketConnection();

    socketService.socket?.on('message', (data) async {
      // Assuming data includes senderId, content, and chatRoomId
      final senderId = data['senderId'];
      final content = data['content'];
      final chatRoomId = data['chatRoomId'];

      // Save the received message to MongoDB
      await saveChatMessage(senderId, content, chatRoomId);

      // Update the UI with the new message
      setState(() {
        _messages.add(data.toString());
        print('Received message: $data');
      });
    });

    // socket?.on('message', (data) {
    //   setState(() {
    //     _messages.add(data);
    //     print('Received message: $data'); // Add this print statement
    //   });
    // });
    socketService.socket?.on("driverLocationUpdate", (data) {
      print('socketdata driver');
      print(data);
      updateMechanicLocation(data);
    });

    socketService.socket?.on("driverUserStatusUpdate", (data) {
      print('socketdata driver status');
      print(data);
      updateMechanicStatus(data);
    });
    socketService.socket?.on('message', (data) {
      setState(() {
        _messages.add(data);
        print('Received message: $data'); // Add this print statement
      });
    });
    socket?.connect();
    socket?.onConnect((_) {
      print('connected to websocket');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    searchController.dispose();
    print('dispose');
    socketService.closeConnection();
    super.dispose();
    socket?.dispose();
  }

  void _startLocationTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getLocation();
    });
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        // Location services are not enabled, handle it accordingly
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // Location permission not granted, handle it accordingly
        return;
      }
    }

    LocationData locationData = await _location.getLocation();
    List<geocoding.Placemark> placemarks =
        await geocoding.placemarkFromCoordinates(
      locationData.latitude!,
      locationData.longitude!,
    );

    print("execute");
    if (placemarks.isNotEmpty) {
      geocoding.Placemark placemark = placemarks[0];
      String? address = placemark.thoroughfare;
      String? city = placemark.locality;
      String locationName = (address != null && city != null)
          ? '$address, $city'
          : (address ?? city ?? 'Unknown Location');
      setState(() {
        _locationData = locationData;
        _locationName = locationName;
      });

      print("db");

      // Save user data in MongoDB
      // await updateLocationInDb(
      //   widget.sessionId,
      //   locationData.latitude!,
      //   locationData.longitude!,
      //   locationName,
      //   city ?? '',
      // );

      // final Map<String, dynamic> locationUpdate = {
      //   'userId': widget.sessionId,
      //   'location': {
      //     'latitude': locationData.latitude,
      //     'longitude': locationData.longitude,
      //     'address': locationName,
      //     'city': city ?? '',
      //   },
      // };

      // print("emit");

      // socketService.socket?.emit("driverLocationUpdate", locationUpdate);

      updateLocation(widget.sessionId, locationData.latitude!,
          locationData.longitude!, locationName, city ?? '');
      updateUserStatus(widget.sessionId, true);
    }
  }

  void updateLocation(
    String sessionId,
    double latitude,
    double longitude,
    String locationName,
    String city,
  ) async {
    await updateLocationInDb(
      sessionId,
      latitude,
      longitude,
      locationName,
      city,
    );

    final Map<String, dynamic> locationUpdate = {
      'userId': sessionId,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'address': locationName,
        'city': city,
      },
    };

    print("emit");
    socketService.socket?.emit("driverLocationUpdate", locationUpdate);
  }

  void updateUserStatus(String userId, bool isLogged) async {
    await updateUserStatusInDb(userId, isLogged);

    final Map<String, dynamic> userStatusUpdate = {
      'userId': userId,
      'isLogged': isLogged,
      'role': 'Driver',
    };
    socketService.socket?.emit("driverUserStatusUpdate", userStatusUpdate);
  }

  void sortMechanicUsers() {
    mechanicUsers.sort((user1, user2) {
      final location1 = user1['location'];
      final location2 = user2['location'];
      final latitude1 =
          location1 != null ? location1['latitude'] as double? : null;
      final longitude1 =
          location1 != null ? location1['longitude'] as double? : null;
      final latitude2 =
          location2 != null ? location2['latitude'] as double? : null;
      final longitude2 =
          location2 != null ? location2['longitude'] as double? : null;

      if (latitude1 != null &&
          longitude1 != null &&
          latitude2 != null &&
          longitude2 != null) {
        final distance1 = calculateDistance(
          _locationData?.latitude,
          _locationData?.longitude,
          latitude1,
          longitude1,
        );
        final distance2 = calculateDistance(
          _locationData?.latitude,
          _locationData?.longitude,
          latitude2,
          longitude2,
        );
        return distance1.compareTo(distance2);
      }

      print(_locationData?.latitude);
      print(_locationData?.longitude);

      final distance1 = calculateDistance(_locationData?.latitude,
          _locationData?.longitude, latitude1, longitude1);
      final distance2 = calculateDistance(_locationData?.latitude,
          _locationData?.longitude, latitude2, longitude2);

      return distance1.compareTo(distance2);
    });
  }

  Future<void> fetchMechanicUsers() async {
    // Fetch mechanic users data
    // final List<Map<String, dynamic>>? users = await getMechanicUsers();
    final List<Map<String, dynamic>>? users = await getMechanicUsers();

    // Sort the users based on distance

    setState(() {
      mechanicUsers = users ?? [];
      filteredMechanicUsers = users ?? [];
    });

    sortMechanicUsers();
  }

  void _filterMechanicUsers(String query) {
    setState(() {
      filteredMechanicUsers = mechanicUsers
          .where((user) =>
              (user['firstName'] as String)
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (user['lastName'] as String)
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          // .where((user) => user['isLogged'] == true)
          .toList();
    });
  }

  void updateMechanicLocation(Map<String, dynamic> data) {
    final String userId = data['userId'];
    final Map<String, dynamic>? location = data['location'];

    if (userId != null && location != null) {
      for (int i = 0; i < mechanicUsers.length; i++) {
        if (mechanicUsers[i]['_id'] == userId) {
          setState(() {
            mechanicUsers[i]['location'] = location;
            filteredMechanicUsers = List.from(
                mechanicUsers.where((user) => user['isLogged'] == true));
          });
          sortMechanicUsers();
          break;
        }
      }
    }
  }

  void updateMechanicStatus(Map<String, dynamic> data) {
    developer.log(data.toString(), name: 'userdata');
    print(data);
    print("driverdatastatus");
    final String userId = data['userId'];
    final bool isLogged = data['isLogged'];

    if (userId != null) {
      for (int i = 0; i < mechanicUsers.length; i++) {
        if (mechanicUsers[i]['_id'] == userId) {
          setState(() {
            // mechanicUsers[i]['isLogged'] = isLogged;
            // filteredMechanicUsers = List.from(
            //     mechanicUsers.where((user) => user['isLogged'] == true));
          });
          sortMechanicUsers();
          break;
        }
      }
    }
  }

  void callUser(String phoneNumber) async {
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

//   Future<List<String>> fetchChatHistory() async {
//   final response = await http.get(Uri.parse('http://your-server-ip:3000/chatHistory')); // Replace with your server IP
//   if (response.statusCode == 200) {
//     final List<dynamic> data = json.decode(response.body);
//     return data.map((item) => item['text'].toString()).toList();
//   } else {
//     throw Exception('Failed to load chat history');
//   }
// }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Messages tab
      _showChatDialog(context);
    } else if (index == 2) {
      // Favorites tab
      _showFavoritesPage(context);
    } else if (index == 3) {
      // Profile tab
      _showProfile(widget.sessionId); // Replace _yourUserId with the user's ID
    }
  }

  void _showProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileOverview(sessionId: userId),
      ),
    );
  }

  // void _showTransactionHistory(BuildContext context) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => MyTextField()),
  //   );
  // }

  void _handleSubmitted(String data) {
    socketService.socket?.emit('message', data);
    _messages.add('You: $data');
    _textController.clear();
    print('Sent message: $data');
    setState(() {}); // Add this print statement
  }

  void _showChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height: 400,
            child: Column(
              children: <Widget>[
                AppBar(
                  title: Text('Inbox'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(_messages[index]),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Enter a message',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          _handleSubmitted(_textController.text);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFavoritesPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoritesPage()),
    );
  }

  void _handleLogout() {
    // Implement your logout logic here.
    // This might include clearing user session data, etc.

    // Navigate back to the login page.
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => LoginPage(), // Replace with your login page widget
    ));
  }

  // void _showHelpCenterDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Help Center'),
  //         content: Text(helpCenterText),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Close'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

//   String helpCenterText = '''
// **Frequently Asked Questions (FAQs)**

// 1. **How do I create an account?**
//    To create an account, click on the "Sign Up" button on the login page and provide the required information.

// 2. **How can I reset my password?**
//    If you've forgotten your password, you can click on the "Forgot Password" link on the login page to reset it.

// 3. **How do I contact customer support?**
//    You can reach our customer support team by sending an email to support@example.com or by calling our toll-free number at 1-800-123-4567.

// 4. **What are the supported payment methods?**
//    We accept payments via credit/debit cards, PayPal, and in-app wallet.

// 5. **Is my personal information secure?**
//    Yes, we take the security of your personal information seriously. We use industry-standard encryption to protect your data.

// 6. **How do I report a problem with the app?**
//    If you encounter any issues or have suggestions for improvements, please use the in-app feedback feature or contact our support team.

// **Contact Information**

// - Email: support@example.com
// - Phone: 1-800-123-4567
// - Address: 123 Main Street, City, Country
// ''';

//   void _showTermsAndConditionsDialog(BuildContext context, String termsAndConditionsText) {
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => TermsAndConditionsPage(
//         termsAndConditionsText: termsAndConditionsText, // Provide the text here
//       ),
//     ),
//   );
// }

  String termsAndConditionsText = '''
1. Acceptance of Terms
   By using this app, you agree to comply with and be bound by these terms and conditions.

2. Use License
   Permission is granted to temporarily download one copy of the materials (information or software) on this app for personal, non-commercial use only.

3. Disclaimer
   The materials on this app are provided "as is". The app makes no warranties, expressed or implied.

4. Limitations
   In no event shall the app be liable for any damages arising out of the use or inability to use the materials on this app.

5. Governing Law
   These terms and conditions are governed by and construed in accordance with the laws of your jurisdiction.

6. Changes to Terms
   The app may revise these terms and conditions at any time without notice.
''';

  // void _showSettingsDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Settings'),
  //         content: Text(settingsText),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Close'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

//   String settingsText = '''
// **General Settings**

// - **Notifications:** Enable or disable app notifications.
// - **Language:** Choose your preferred language.
// - **Theme:** Customize the app's appearance with light or dark mode.
// - **Privacy:** Manage your privacy settings.

// **Account Settings**

// - **Change Password:** Update your account password.
// - **Profile:** Edit your profile information.
// - **Security:** Enhance your account security.

// **App Version**

// - **Version:** 1.0.0
// - **Check for Updates:** Check if there are any new app updates available.

// **Support and Feedback**

// - **Contact Support:** Get assistance from our support team.
// - **Send Feedback:** Share your thoughts and suggestions.

// **Legal**

// - **Terms and Conditions:** Read our terms and conditions.
// - **Privacy Policy:** Review our privacy policy.
// - **Licenses:** View open-source licenses used in the app.
// ''';

  void fetchPolylinePoints() async {
    // Replace with your actual coordinates for start and end points
    double startLatitude = _locationData?.latitude ?? 0.0;
    double startLongitude = _locationData?.longitude ?? 0.0;
    double endLatitude = selectedUserLocation?.latitude ?? 0.0;
    double endLongitude = selectedUserLocation?.longitude ?? 0.0;

    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      '', // Empty string or omit it if you're not using Google Maps
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(endLatitude, endLongitude),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> routeCoordinates = result.points.map((point) {
        return LatLng(point.latitude, point.longitude); // Corrected data type
      }).toList();

      setState(() {
        polylineCoordinates = routeCoordinates;

        // Center the map on the starting point
        mapController.move(LatLng(startLatitude, startLongitude), 13.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? latitude = _locationData?.latitude;
    final double? longitude = _locationData?.longitude;

    return DefaultTabController(
      length: 4, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _locationName ?? 'Default Location Name',
          ),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.my_location_sharp),
              onPressed: () {
                if (latitude != null && longitude != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlutterMap(
                        options: MapOptions(
                          center: LatLng(latitude,
                              longitude), // Use latitude and longitude here
                          zoom: 18,
                          maxZoom: 20,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: ['a', 'b', 'c'],
                            userAgentPackageName: 'com.raamb_app.app',
                          ),
                          MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                              maxClusterRadius: 120,
                              size: Size(40, 40),
                              fitBoundsOptions: FitBoundsOptions(
                                padding: EdgeInsets.all(50),
                              ),
                              markers: filteredMechanicUsers
                                  .map((user) {
                                    final location = user['location'];
                                    final latitude = location != null
                                        ? location['latitude'] as double?
                                        : null;
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
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Handle the case where latitude and longitude are not available
                }
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            key: ValueKey(userId ?? ['_id']),
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.red, // Background color
                ),
                child: Text(
                  userId ?? 'nothere',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ), // Content of the DrawerHeader
              ),
              ListTile(
                title: Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _showProfile(widget.sessionId);
                  // Add your profile navigation logic here
                },
              ),
              ListTile(
                title: Text('Transactions'),
                onTap: () {
                  Navigator.pop(
                      context); // Close the current screen if necessary
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TransactionHistoryPage()),
                  );
                },
              ),
              ListTile(
                title: Text('Settings'), // Add Settings option
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text('Help Center'), // Add Help Center option
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HelpCenterPage(),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(
                    'Terms and Conditions'), // Add Terms and Conditions option
                onTap: () {
                  Navigator.pop(context); // Close the current dialog or drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TermsAndConditionsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text('Log-Out'),
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout();
                  // Add your log-out logic here
                  // Add your log-out logic here
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                onChanged: _filterMechanicUsers,
                decoration: InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0,
                children: <Widget>[
                  ChoiceChip(
                    label: Text('Automotive'),
                    selected: selectedVehicleTypes == 'Automotive',
                    onSelected: (isSelected) {
                      setState(() {
                        selectedVehicleTypes = isSelected ? 'Automotive' : null;
                        // Call a function to filter mechanics by vehicle type.
                        _filterMechanicByVehicleType();
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text('Motorcycle'),
                    selected: selectedVehicleTypes == 'Motorcycle',
                    onSelected: (isSelected) {
                      setState(() {
                        selectedVehicleTypes = isSelected ? 'Motorcycle' : null;
                        _filterMechanicByVehicleType();
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text('Bicycle'),
                    selected: selectedVehicleTypes == 'Bicycle',
                    onSelected: (isSelected) {
                      setState(() {
                        selectedVehicleTypes = isSelected ? 'Bicycle' : null;
                        _filterMechanicByVehicleType();
                      });
                    },
                  ),
                  // ChoiceChip(
                  //   label: Text('Sedan'),
                  //   selected: selectedVehicleType == 'Sedan',
                  //   onSelected: (isSelected) {
                  //     setState(() {
                  //       selectedVehicleType = isSelected ? 'Sedan' : null;
                  //       _filterMechanicByVehicleType();
                  //     });
                  //   },
                  // ),
                ],
              ),
            ),
            Expanded(
              child: filteredMechanicUsers
                      .isNotEmpty // Check if mechanicUsers is not empty
                  ? ListView.builder(
                      itemCount: filteredMechanicUsers.length,
                      itemBuilder: (context, index) {
                        // Sort mechanic users based on distance here
                        filteredMechanicUsers.sort((user1, user2) {
                          final isLogged1 = user1['isLogged'] as bool? ?? false;
                          final isLogged2 = user2['isLogged'] as bool? ?? false;

                          if (isLogged1 != isLogged2) {
                            return isLogged1
                                ? -1
                                : 1; // Online users come before offline users
                          }

                          final location1 = user1['location'];
                          final location2 = user2['location'];
                          final latitude1 = location1 != null
                              ? location1['latitude'] as double?
                              : null;
                          final longitude1 = location1 != null
                              ? location1['longitude'] as double?
                              : null;
                          final latitude2 = location2 != null
                              ? location2['latitude'] as double?
                              : null;
                          final longitude2 = location2 != null
                              ? location2['longitude'] as double?
                              : null;

                          if (latitude1 != null &&
                              longitude1 != null &&
                              latitude2 != null &&
                              longitude2 != null) {
                            final distance1 = calculateDistance(
                              _locationData?.latitude,
                              _locationData?.longitude,
                              latitude1,
                              longitude1,
                            );
                            final distance2 = calculateDistance(
                              _locationData?.latitude,
                              _locationData?.longitude,
                              latitude2,
                              longitude2,
                            );
                            return distance1.compareTo(distance2);
                          }
                          return 0; // Handle cases where location data is missing or invalid
                        });

                        final user = filteredMechanicUsers[index];
                        // child: filteredMechanicUsers.isNotEmpty
                        //     ? ListView.builder(
                        //         itemCount: filteredMechanicUsers.length,
                        //         itemBuilder: (context, index) {
                        //           final user = filteredMechanicUsers[index];

                        final location = user['location'];
                        final latitude = location != null
                            ? location['latitude'] as double?
                            : null;
                        final longitude = location != null
                            ? location['longitude'] as double?
                            : null;
                        final address = location != null
                            ? location['address'] as String?
                            : null;
                        final city = location != null
                            ? location['city'] as String?
                            : null;

                        return Card(
                            elevation: 2,
                            child: ListTile(
                                key: ValueKey(user['_id']),
                                title: Text(
                                  ' ${user['firstName'] ?? 'Unknown'} ${user['lastName'] ?? ''}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 15,
                                          color: Colors.lightBlue,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${user['phoneNumber'] ?? 'Unknown'}',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Spacer(),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: user['isLogged'] == true
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            user['isLogged'] == true
                                                ? 'Available'
                                                : 'Unavailable', // Check if any user is logged in
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // SizedBox(height: 4),
                                    // Row(
                                    //   children: [
                                    //     Icon(
                                    //       Icons.location_searching,
                                    //       size: 15,
                                    //       color: Colors.lightGreen,
                                    //     ),
                                    //     SizedBox(width: 4),
                                    //     Text(
                                    //       'Distance: ${(latitude != null && longitude != null) ? calculateDistance(_locationData?.latitude, _locationData?.longitude, latitude, longitude).toStringAsFixed(2) + ' meters' : 'Estimated'}',
                                    //       maxLines: 1,
                                    //       overflow: TextOverflow.ellipsis,
                                    //       style: TextStyle(
                                    //         color: Colors.grey[600],
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                    SizedBox(height: 4),
                                    Text(
                                      ' ${address ?? 'Unknown'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_searching,
                                          size: 15,
                                          color: Colors.lightGreen,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          ' ${(latitude != null && longitude != null) ? calculateDistance(_locationData?.latitude, _locationData?.longitude, latitude, longitude).toStringAsFixed(2) + ' meters' : ''}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      ' ${user['VehicleType'] ?? 'Unknown'} Mechanic',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.phone),
                                        onPressed: () {
                                          callUser(user['phoneNumber']);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.message),
                                        onPressed: () {
                                          callUser(user['phoneNumber']);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.map),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => FlutterMap(
                                                options: MapOptions(
                                                  center: LatLng(latitude!,
                                                      longitude!), // Initial map center coordinates
                                                  zoom:
                                                      13.0, // Initial zoom level
                                                ),
                                                children: [
                                                  TileLayer(
                                                    urlTemplate:
                                                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                                    subdomains: ['a', 'b', 'c'],
                                                    userAgentPackageName:
                                                        'com.raamb_app.app',
                                                  ),
                                                  MarkerLayer(
                                                    markers: [
                                                      Marker(
                                                        point: LatLng(latitude,
                                                            longitude),
                                                        width: 80,
                                                        height: 80,
                                                        builder: (context) =>
                                                            Icon(
                                                                Icons.pin_drop),
                                                      ),
                                                      Marker(
                                                        point: LatLng(
                                                            _locationData
                                                                    ?.latitude ??
                                                                0,
                                                            _locationData
                                                                    ?.longitude ??
                                                                0), // Marker for the ending point
                                                        width: 80,
                                                        height: 80,
                                                        builder: (context) =>
                                                            Icon(
                                                                Icons.pin_drop),
                                                      ),
                                                    ],
                                                  ),

                                                  // (
                                                  //     // Customize the marker icon
                                                  //     ) {
                                                  //   showDialog(
                                                  //       context:
                                                  //           context,
                                                  //       builder:
                                                  //           (BuildContext
                                                  //               context) {
                                                  //         return AlertDialog(
                                                  //           title:
                                                  //               Text('Location Info'),
                                                  //           content:
                                                  //               Text('This is the selected location.'),
                                                  //           actions: [
                                                  //             TextButton(
                                                  //               child: Text('Close'),
                                                  //               onPressed: () {
                                                  //                 Navigator.of(context).pop();
                                                  //               },
                                                  //             ),
                                                  //           ],
                                                  //         );
                                                  //       });
                                                  // }
                                                  //               ),
                                                  //                   ),
                                                  //     )
                                                  //   ],
                                                  // ),
                                                  PolylineLayer(
                                                    polylines: [
                                                      Polyline(
                                                        points: [
                                                          LatLng(
                                                              _locationData
                                                                      ?.latitude ??
                                                                  0,
                                                              _locationData
                                                                      ?.longitude ??
                                                                  0), // Start point
                                                          LatLng(latitude,
                                                              longitude)
                                                        ], // Use polylineCoordinates directly
                                                        color: Colors
                                                            .blue, // Color of the polyline
                                                        strokeWidth:
                                                            3.0, // Width of the polyline
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    ])));
                      },
                    )
                  : Center(
                      child: Text('No Mechanics found.'),
                    ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.person),
            //   label: 'Profile',
            // ),
          ],
          currentIndex: _selectedIndex,
          unselectedItemColor: Colors.grey,
          selectedItemColor: Colors.red,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  void _filterMechanicByVehicleType() {
    setState(() {
      filteredMechanicUsers = mechanicUsers.where((user) {
        if (selectedVehicleTypes == null) {
          return true; // No filter applied, return all mechanics
        } else {
          // Check if mechanic['VehicleType'] is not null and contains selectedVehicleType
          final vehicleTypeList = user['VehicleType'];
          return vehicleTypeList != null &&
              vehicleTypeList.contains(selectedVehicleTypes);
        }
      }).toList();
    });
    print("Filtered Mechanics: $filteredMechanicUsers");
  }
}
