import 'dart:async';
import 'package:raamb_app/chat/ChatContent/chat_message.dart';

import 'package:raamb_app/map/driver_map.dart';

import '../drawer/terms_and_conditions.dart';
import '../drawer/help_center.dart';
import '../drawer/settings.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:raamb_app/main.dart';

import '../service/mongo_service.dart';
import '../utils/location.dart';
import '../service/socket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import '../profile/profile_overview.dart';
import '../auth/login_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;



import '../transaction/transaction_list.dart';
import '../drawer/favorites.dart';

import '../chat/chat.dart';

import 'package:provider/provider.dart';


class DriverPage extends StatefulWidget {
  final String sessionId;
  final List<String> selectedVehicleTypes = [];
  List<Map<String, dynamic>> filteredMechanicUsers = [];
  

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
  String? firstName;
  String? lastName;

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
    
    socket = IO.io('https://8cc2-49-145-135-84.ngrok-free.app');
    _loadUserData();
    
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



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Messages tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(),
        ),
      );
    } else if (index == 2) {
      // Favorites tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(
            sessionId: widget.sessionId, // Pass the session ID
            mechanicUsers: mechanicUsers,
            
             // Pass the list of mechanics
            
           
          ),
        ),
      );
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

  



Future<void> _loadUserData() async {
  final loginSession = Provider.of<LoginSession>(context, listen: false);
  final sessionId = loginSession.getUserId();
  
  getUserData(sessionId).then((userData) {
    if (userData != null) {
      if (mounted) {
        setState(() {
          firstName = userData['firstName'];
          lastName = userData['lastName'];
        });
      }
    }
  }).catchError((error) {
    // Handle any errors here
    print('Error fetching user data: $error');
  });
}




  @override
  Widget build(BuildContext context) {
    final double? latitude = _locationData?.latitude;
    final double? longitude = _locationData?.longitude;
    var displayName = '${firstName ?? 'Your'} ${lastName ?? 'Name'}';
    
  
  
  

    

    return DefaultTabController(
  length: 4, // Number of tabs including "All"
  child: Scaffold(
    appBar: AppBar(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (firstName != null && lastName != null) // Check if the names are not null
            Text(
              '$firstName $lastName', // Display the full name
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.white70,
              ),
            ),
          Text(
            _locationName ?? 'Default Location Name', // Location name falls back to a default if null
            style: TextStyle(
              fontSize: 18.0,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48.0), // Adjust the height as needed
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 0),
              child: Material(
                borderRadius: BorderRadius.circular(30.0), // Make it rounded
                elevation: 2.0,
                child: TextField(
                  controller: searchController,
                  onChanged: _filterMechanicUsers,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0), // Make it rounded
                    ),
                  ),
                ),
              ),
            ),
            TabBar(
        isScrollable: true, // Set this to true to enable scrolling
        tabs: [
                Tab(text: "Automotive"),
                Tab(text: "Motorcycle"),
                Tab(text: "Bicycle"),
                Tab(text: "All"), // The new "All" tab
              ],
              onTap: (index) {
                // Handle the tap event and perform actions based on the tab
                setState(() {
                  switch (index) {
                    case 0: // Automotive
                      selectedVehicleTypes = 'Automotive';
                      break;
                    case 1: // Motorcycle
                      selectedVehicleTypes = 'Motorcycle';
                      break;
                    case 2: // Bicycle
                      selectedVehicleTypes = 'Bicycle';
                      break;
                    case 3: // All
                      selectedVehicleTypes = null; // Or set this to 'All' if you have a specific filter for this
                      break;
                  }
                  _filterMechanicByVehicleType(); // Make sure this method uses the selectedVehicleTypes variable to filter
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        // Any other action buttons/icons can go here
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
                     accountName: Text(displayName),
                      accountEmail: null, // Add email if available
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: Colors.white,
                        child:
                            Icon(Icons.person), // Add user profile picture here
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.account_circle), // Icon for "Profile"
                      title: Text('Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        _showProfile(widget.sessionId);
                      },
                    ),
                    // ListTile(
                    //   leading: Icon(Icons.star), // Icon for "Favorites"
                    //   title: Text('Favorites'),
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //     _showFavoritesPage(context);
                    //     // Add your "Favorites" navigation logic here
                    //   },
                    // ),
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
                      leading: Icon(
                          Icons.description), // Icon for "Terms and Conditions"
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
        body: Column(
          children: [
           
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0,
                               
                
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
                        final tariff = user['tariff'] != null ? '\$${user['tariff']}' : 'Unknown';

                        return Card(
  elevation: 4,
  margin: EdgeInsets.all(8.0),
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center, // Center the children vertically
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ListTile(
          isThreeLine: true, // Allows for a denser layout if needed
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
          // leading: CircleAvatar(
          //   // Placeholder for user icon or image
          //   backgroundImage: NetworkImage(user['imageUrl'] ?? 'default_image_url'),
          // ),
          title: Text(
            '${user['firstName'] ?? 'Unknown'} ${user['lastName'] ?? ''}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.red.shade700, // Your app's main color
            ),
            textAlign: TextAlign.center,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                    Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon(Icons.phone, size: 15, color: Colors.lightBlue),
          // SizedBox(width: 4),
          Expanded( // Use Expanded for the phone number to ensure it fills the available space.
      child: Text(
            '${user['phoneNumber'] ?? 'Unknown'}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
                  ),
                   
                   textAlign: TextAlign.center,
                ),
          ),
                        // Spacer(),
                        Align(
      alignment: Alignment.topRight, // This will align the container to the right.
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: user['isLogged'] == true ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          user['isLogged'] == true ? 'Available' : 'Unavailable',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      
      ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      address ?? 'Unknown',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                      
                    ),
                    SizedBox(height: 4),
                    Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_searching, size: 15, color: Colors.lightGreen),
          SizedBox(width: 4),
          Text(
            latitude != null && longitude != null
                ? '${calculateDistance(_locationData?.latitude, _locationData?.longitude, latitude, longitude).toStringAsFixed(2)} meters'
                : 'Distance not available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${user['VehicleType'] ?? 'Unknown'} Mechanic',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
          'Tariff: P50-P250',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
                    ),
                  
                
                Divider(), // Visual separator
        ButtonBar(
          alignment: MainAxisAlignment.spaceEvenly, // Spread the buttons evenly across the horizontal axis
          buttonPadding: EdgeInsets.symmetric(horizontal: 12.0), // Add padding around the buttons
          children: <Widget>[
          IconButton(
                      icon: Icon(Icons.phone),
                      onPressed: () {
                        callUser(user['phoneNumber']);
                      },
                    ),
                    IconButton(
  icon: Icon(Icons.message),
  onPressed: () {
    // Navigate to the MessagePage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatMessages()),
    );
  },
),

                    IconButton(
  icon: Icon(Icons.build),
  onPressed: () {
    if (latitude != null && longitude != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(
            sessionId: widget.sessionId,
            mechanicUsers: widget.filteredMechanicUsers,
 // Pass the mechanic ID
          ),
        ),
      );
    } else {
      // Handle null latitude/longitude
    }
  },
                    ),
      
                                    ]
                                    )
      
    ]
    )
  ),
    )]
          
  ),
                        ));
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
            icon: Icon(Icons.location_on),
             label: 'Map',
           ),
           
 
        ],
        currentIndex: _selectedIndex,
        
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
       ),
  
      ),
  
    
      
  
    );
    
  }
  

  // // // Widget buildBody(BuildContext context) {
  // // //   final List<Widget> _pages = [
  // // //   ProfileOverview(sessionId: userId??''),
  // // //   ChatPage(),
  // // //   MapPage(mechanicUsers: mechanicUsers, sessionId: userId??'',),
  // // //   // ... other pages
  // // // ];
  // // //   return Scaffold(
  // // //     body: IndexedStack(
  // // //       index: _selectedIndex,
  // // //       children: _pages,
  // // //     ),
  // // //     bottomNavigationBar: BottomNavigationBar(
  // // //       items: const <BottomNavigationBarItem>[
  // // //         BottomNavigationBarItem(
  // // //           icon: Icon(Icons.home),
  // // //           label: 'Home',
  // // //         ),
  // // //         BottomNavigationBarItem(
  // // //           icon: Icon(Icons.message),
  // // //           label: 'Messages',
  // // //         ),
  // // //         BottomNavigationBarItem(
  // // //           icon: Icon(Icons.location_on),
  // // //           label: 'Map',
  // // //         ),
  // // //         // ... other tabs ...
  // // //       ],
  // // //       currentIndex: _selectedIndex,
  // // //       selectedItemColor: Colors.red,
  // // //       unselectedItemColor: Colors.grey,
  // // //       onTap: _onItemTapped,
  // // //     ),
    
  // //   );
    
  // }

  void _filterMechanicByVehicleType() {
    setState(() {
      filteredMechanicUsers = mechanicUsers.where((user) {
        if (selectedVehicleTypes == null) {
          return true; // No filter applied, return all mechanics
        } else {
          
          final vehicleTypeList = user['VehicleType'];
          return vehicleTypeList != null &&
              vehicleTypeList.contains(selectedVehicleTypes);
        }
      }).toList();
    });
    print("Filtered Mechanics: $filteredMechanicUsers");
  }
}
