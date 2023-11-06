import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../service/mongo_service.dart';
import '../utils/location.dart';
import '../service/socket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;


import '../profile/profile_overview.dart';
import '../auth/login_page.dart';

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
    
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => LoginPage(), 
    ));
  }

  

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
                        height: 20, 
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
                                                      
                                                      print('Declined');
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      primary: Colors.red,
                                                    ),

                                                    child: Text('Decline'),
                                                  ),
                                                  
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
