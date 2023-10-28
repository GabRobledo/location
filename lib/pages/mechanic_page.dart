import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'dart:math';
import '../service/mongo_service.dart';
import '../utils/location.dart';
import '../service/socket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../profile/profile_overview.dart';
import '../auth/login_page.dart';
import '../transaction/mechanic_request.dart';
import '../transaction/transaction_list.dart';
import '../drawer/favorites.dart';
import '../drawer/settings.dart';
import '../drawer/help_center.dart';
import '../drawer/terms_and_conditions.dart';

class MechanicPage extends StatefulWidget {
  final String sessionId;
  final List<String> selectedVehicleTypes;

  MechanicPage({required this.sessionId, required this.selectedVehicleTypes});

  @override
  _MechanicPageState createState() => _MechanicPageState();
}

class _MechanicPageState extends State<MechanicPage> {
  LocationData? _locationData;
  Location _location = Location();
  String? _locationName;
  Timer? _timer;
  String? user;
  List<Map<String, dynamic>> driverUsers = [];
  List<Map<String, dynamic>> filteredDriverUsers = [];
  final SocketService socketService = SocketService();
  int _selectedIndex = 0;

  // Add this variable for the selected tab index

  TextEditingController searchController = TextEditingController();

  // GoogleMapController? _controller;
  // Set<Marker> _markers = {};
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Map View'),
//       ),
//       body: FlutterMap(
//         options: MapOptions(
//           center: LatLng(51.5, -0.09), // Initial map center coordinates
//           zoom: 13.0, // Initial zoom level
//         ),
//         layers: [
//           TileLayerOptions(
//             urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//             subdomains: ['a', 'b', 'c'],
//           ),
//           // Add more layers as needed, e.g., MarkerLayerOptions
//         ],
//       ),
//     );
//   }
// }

  @override
  void initState() {
    super.initState();
    _getLocation();
    _startLocationTimer();
    updateUserStatus(widget.sessionId, true);
    fetchDriverUsers();
    socketService.startSocketConnection();
    socketService.socket?.on("mechanicLocationUpdate", (data) {
      print('socketdata mechanic');
      print(data);
      updateDriverLocation(data);
    });

    socketService.socket?.on("mechanicUserStatusUpdate", (data) {
      print('socketdata mechanic status');
      print(data);
      updateDriverStatus(data);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    searchController.dispose();

    socketService.closeConnection();
    super.dispose();
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
      // socketService.socket?.emit("mechanicLocationUpdate", locationUpdate);
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
    socketService.socket?.emit("mechanicLocationUpdate", locationUpdate);
  }

  void updateUserStatus(String userId, bool isLogged) async {
    await updateUserStatusInDb(userId, isLogged);

    final Map<String, dynamic> userStatusUpdate = {
      'userId': userId,
      'isLogged': isLogged,
      'role': 'Mechanic',
    };
    socketService.socket?.emit("mechanicUserStatusUpdate", userStatusUpdate);
  }

  void sortDriverUsers() {
    driverUsers.sort((user1, user2) {
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

      final distance1 = calculateDistance(_locationData?.latitude,
          _locationData?.longitude, latitude1, longitude1);
      final distance2 = calculateDistance(_locationData?.latitude,
          _locationData?.longitude, latitude2, longitude2);

      return distance1.compareTo(distance2);
    });
  }

  Future<void> fetchDriverUsers() async {
    // Fetch Driver users data
    final List<Map<String, dynamic>>? users = await getDriverUsers();
    final filteredUsers = users?.where((user) {
      final vehicleType =
          user['vehicleType'] as String?; // Assuming the key is 'vehicleType'
      return widget.selectedVehicleTypes.contains(vehicleType);
    }).toList();

    // Sort the users based on distance

    setState(() {
      driverUsers = users ?? [];
      filteredDriverUsers = users ?? [];
    });

    sortDriverUsers();
  }

  void _filterDriverUsers(String query) {
    setState(() {
      filteredDriverUsers = driverUsers
          .where((user) =>
              (user['firstName'] as String)
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              (user['lastName'] as String)
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .where((user) => user['isLogged'] == true)
          .toList();
    });
  }

  void updateDriverLocation(Map<String, dynamic> data) {
    final String userId = data['userId'];
    final Map<String, dynamic>? location = data['location'];

    if (userId != null && location != null) {
      for (int i = 0; i < driverUsers.length; i++) {
        if (driverUsers[i]['_id'] == userId) {
          setState(() {
            driverUsers[i]['location'] = location;
            filteredDriverUsers = List.from(driverUsers);
          });
          sortDriverUsers();
          break;
        }
      }
    }
  }

  void updateDriverStatus(Map<String, dynamic> data) {
    developer.log(data.toString(), name: 'userdata');
    print(data);
    print("mechanicdatastatus");
    final String userId = data['userId'];
    final bool isLogged = data['isLogged'];
    if (userId != null) {
      for (int i = 0; i < driverUsers.length; i++) {
        if (driverUsers[i]['_id'] == userId) {
          setState(() {
            driverUsers[i]['isLogged'] = isLogged;
            filteredDriverUsers = List.from(
                driverUsers.where((user) => user['isLogged'] == true));
          });
          sortDriverUsers();
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

  void _handleLogout() {
    // Implement your logout logic here.
    // This might include clearing user session data, etc.

    // Navigate back to the login page.
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => LoginPage(), // Replace with your login page widget
    ));
  }

  // void _showDriverLocationOnMap(String address) async {
  //   List<geocoding.Placemark> placemarks =
  //       await geocoding.locationFromAddress(address);

  //   if (placemarks.isNotEmpty) {
  //     final geocoding.Placemark placemark = placemarks.first;
  //     final double latitude = placemark.latitude!;
  //     final double longitude = placemark.longitude!;

  //     final mapController = MapController();
  //     final LatLng driverLocation = LatLng(latitude, longitude);

  //     showModalBottomSheet(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return Container(
  //           height: 300, // Adjust the height as needed
  //           child: FlutterMap(
  //             options: MapOptions(
  //               center: driverLocation,
  //               zoom: 14.0, // Adjust the initial zoom level
  //               plugins: [MarkerClusterPlugin()], // Enable marker clustering
  //               onTap: (_) {
  //                 if (Navigator.of(context).canPop()) {
  //                   Navigator.of(context).pop();
  //                 }
  //               },
  //             ),
  //             layers: [
  //               TileLayerOptions(
  //                 urlTemplate:
  //                     "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
  //                 subdomains: ['a', 'b', 'c'],
  //               ),
  //               MarkerLayerOptions(
  //                 markers: [
  //                   Marker(
  //                     width: 30.0,
  //                     height: 30.0,
  //                     point: driverLocation,
  //                     builder: (context) => Icon(
  //                       Icons.location_pin,
  //                       color: Colors.red,
  //                       size: 30.0,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //             mapController: mapController,
  //           ),
  //         );
  //       },
  //     );
  //   } else {
  //     // Handle the case where no coordinates were found for the given address
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text('Error'),
  //         content: Text('Location not found for the provided address.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text('OK'),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileOverview(sessionId: userId),
      ),
    );
  }

  void _showTransactionHistory() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          // Customize the content of the transaction history here.
          child: Column(
            children: [
              ListTile(
                title: Text('Transaction 1'),
              ),
              ListTile(
                title: Text('Transaction 2'),
              ),
              // Add more transaction items as needed.
            ],
          ),
        );
      },
    );
  }

  void _showHelpCenterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Help Center'),
          content: Text(helpCenterText),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String helpCenterText = '''
**Frequently Asked Questions (FAQs)**

1. **How do I create an account?**
   To create an account, click on the "Sign Up" button on the login page and provide the required information.

2. **How can I reset my password?**
   If you've forgotten your password, you can click on the "Forgot Password" link on the login page to reset it.

3. **How do I contact customer support?**
   You can reach our customer support team by sending an email to support@example.com or by calling our toll-free number at 1-800-123-4567.

4. **What are the supported payment methods?**
   We accept payments via credit/debit cards, PayPal, and in-app wallet.

5. **Is my personal information secure?**
   Yes, we take the security of your personal information seriously. We use industry-standard encryption to protect your data.

6. **How do I report a problem with the app?**
   If you encounter any issues or have suggestions for improvements, please use the in-app feedback feature or contact our support team.

**Contact Information**

- Email: support@example.com
- Phone: 1-800-123-4567
- Address: 123 Main Street, City, Country
''';

  void _showTermsAndConditionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Terms and Conditions'),
          content: Text(termsAndConditionsText),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings'),
          content: Text(settingsText),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String settingsText = '''
**General Settings**

- **Notifications:** Enable or disable app notifications.
- **Language:** Choose your preferred language.
- **Theme:** Customize the app's appearance with light or dark mode.
- **Privacy:** Manage your privacy settings.

**Account Settings**

- **Change Password:** Update your account password.
- **Profile:** Edit your profile information.
- **Security:** Enhance your account security.

**App Version**

- **Version:** 1.0.0
- **Check for Updates:** Check if there are any new app updates available.

**Support and Feedback**

- **Contact Support:** Get assistance from our support team.
- **Send Feedback:** Share your thoughts and suggestions.

**Legal**

- **Terms and Conditions:** Read our terms and conditions.
- **Privacy Policy:** Review our privacy policy.
- **Licenses:** View open-source licenses used in the app.
''';
  void navigateToMechanicReviewPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MechanicReviewPage(
          orderNumber: '12345',
          customerName: 'John Doe',
          customerAddress: '123 Main St',
          comment: 'Some comment', // Provide a value for comment
          fare: '50.00',
          issue: 'Car trouble',
          photo: 'url_to_photo',
          distance: '5 miles',
          paymentMethod: 'Credit Card',
        ),
      ),
    );
  }

  void _showFavoritesPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoritesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 4, // Number of tabs
        child: Scaffold(
          appBar: AppBar(
            title: Text(_locationName ?? ''),
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
              // IconButton(
              //   icon: Icon(Icons.book),
              //   onPressed: () {
              //     // Add the action for the logbook icon here
              //   },
              // ),
            ],
          ),
          drawer: Drawer(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      UserAccountsDrawerHeader(
                        accountName: Text(''),
                        accountEmail: null, // Add email if available
                        currentAccountPicture: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                              Icons.person), // Add user profile picture here
                        ),
                      ),
                      ListTile(
                        leading:
                            Icon(Icons.account_circle), // Icon for "Profile"
                        title: Text('Profile'),
                        onTap: () {
                          Navigator.pop(context);
                          _showProfile(widget.sessionId);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.star), // Icon for "Favorites"
                        title: Text('Favorites'),
                        onTap: () {
                          Navigator.pop(context);
                          _showFavoritesPage(context);
                          // Add your "Favorites" navigation logic here
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.history), // Icon for "Transactions"
                        title: Text('Transactions'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionHistoryPage(),
                            ),
                          );
                        },
                      ),
                      Divider(),
                      Container(
                        height: 1, // Set the height for the line
                        decoration: BoxDecoration(
                          color: Colors.grey, // Choose the color you prefer
                        ),
                      ),
                      Divider(
                        height: 20, // Adjust the height to make it bigger
                        // Adjust the thickness
                        // Change the color to blue or any other color you prefer
                      ),
                      ListTile(
                        leading: Icon(Icons.settings), // Icon for "Settings"
                        title: Text('Settings'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SettingsPage()),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.help), // Icon for "Help Center"
                        title: Text('Help Center'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HelpCenterPage()),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons
                            .description), // Icon for "Terms and Conditions"
                        title: Text('Terms and Conditions'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TermsAndConditionsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.exit_to_app), // Icon for "Log-Out"
                  title: Text('Log-Out'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                ),
              ],
            ),
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
              // BottomNavigationBarItem(
              //   icon: Icon(Icons.favorite),
              //   label: 'Favorites',
              // ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            unselectedItemColor: Colors.grey,
            selectedItemColor: Colors.red,
            onTap: _onItemTapped,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterDriverUsers,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredDriverUsers.isNotEmpty
                    ? SingleChildScrollView(
                        child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: filteredDriverUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredDriverUsers[index];
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

                              return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Card(
                                      elevation: 2,
                                      child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Column(children: [
                                            ListTile(
                                              key: ValueKey(user[
                                                  '_id']), // Assign a unique key based on the user ID
                                              title: Text(
                                                ' ${user['firstName'] ?? 'Unknown'} ${user['lastName'] ?? ''}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Padding(
                                                padding: const EdgeInsets
                                                        .symmetric(
                                                    horizontal:
                                                        1), // Adjust the margin here
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(Icons.phone,
                                                              size: 15,
                                                              color: Colors
                                                                  .lightBlue),
                                                          SizedBox(width: 5),
                                                          Text(
                                                            '${user['phoneNumber'] ?? 'Unknown'}',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                          // Spacer(),
                                                          // Container(
                                                          //   padding: EdgeInsets
                                                          //       .symmetric(
                                                          //     horizontal: 4,
                                                          //     vertical: 2,
                                                          //   ),
                                                          //   decoration:
                                                          //       BoxDecoration(
                                                          //     color:
                                                          //         Colors.green,
                                                          //     borderRadius:
                                                          //         BorderRadius
                                                          //             .circular(
                                                          //                 4),
                                                          //   ),
                                                          //   child: Text(
                                                          //     'Online',
                                                          //     style: TextStyle(
                                                          //       color: Colors
                                                          //           .white,
                                                          //       fontSize: 12,
                                                          //     ),
                                                          //   ),
                                                          // ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        '${address ?? 'Unknown Address'}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .location_searching,
                                                            size: 15,
                                                            color: Colors
                                                                .lightGreen,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            '${latitude != null && longitude != null ? calculateDistance(_locationData?.latitude, _locationData?.longitude, latitude, longitude).toStringAsFixed(2) : 'Unknown'} meters',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ]),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ElevatedButton(
                                                    // Use ElevatedButton for "Acrcept" button
                                                    onPressed: () {
                                                      // Handle Accept logic here
                                                      // For now, just print a message
                                                      print('Accepted');
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      primary: Colors.green,
                                                    ),
                                                    child: Text('Accept'),
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          10), // Add spacing between buttons
                                                  ElevatedButton(
                                                    // Use TextButton for "Decline" button
                                                    onPressed: () {
                                                      // Handle Decline logic here
                                                      // For now, just print a message
                                                      print('Declined');
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      primary: Colors.red,
                                                    ),

                                                    child: Text('Decline'),
                                                  ),
                                                  // IconButton(
                                                  //   icon: Icon(Icons.phone),
                                                  //   onPressed: () {
                                                  //     Navigator.pop(context);
                                                  //     navigateToMechanicReviewPage(
                                                  //         context);
                                                  //   },
                                                  // ),
                                                  // IconButton(
                                                  //   icon: Icon(Icons.map),
                                                  //   onPressed: () {
                                                  //     Navigator.push(
                                                  //         context,
                                                  //         MaterialPageRoute(
                                                  //             builder:
                                                  //                 (context) =>
                                                  //                     FlutterMap(
                                                  //                       options:
                                                  //                           MapOptions(
                                                  //                         center: LatLng(
                                                  //                             latitude!,
                                                  //                             longitude!), // Initial map center coordinates
                                                  //                         zoom:
                                                  //                             13.0, // Initial zoom level
                                                  //                       ),
                                                  //                       children: [
                                                  //                         TileLayer(
                                                  //                           urlTemplate:
                                                  //                               "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                                  //                           subdomains: [
                                                  //                             'a',
                                                  //                             'b',
                                                  //                             'c'
                                                  //                           ],
                                                  //                           userAgentPackageName:
                                                  //                               'com.raamb_app.app',
                                                  //                         ),
                                                  //                         MarkerLayer(
                                                  //                           markers: [
                                                  //                             Marker(
                                                  //                               point: LatLng(latitude, longitude),
                                                  //                               width: 80,
                                                  //                               height: 80,
                                                  //                               builder: (context) => Icon(Icons.pin_drop),
                                                  //                             ),
                                                  //                           ],
                                                  //                         ),
                                                  //                       ],
                                                  //                     )
                                                  //                     )
                                                  //                     );
                                                  //   },
                                                  // ),
                                                ],
                                              ),
                                            ),
                                          ]))));
                            }),
                      )
                    : Center(child: Text('No Drivers found')),
              ),
            ],
          ),
        ));
  }
}
