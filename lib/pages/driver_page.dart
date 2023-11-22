import 'dart:async';
import 'package:raamb_app/chat/ChatContent/chat_message.dart';
import 'package:raamb_app/chat/ChatList/chat_list.dart';
import 'package:raamb_app/chat/chattest.dart';
import 'package:raamb_app/map/driver_map.dart';
import 'package:raamb_app/map/drivertestmap.dart';
import 'package:raamb_app/map/singe_drivermap.dart';
import 'package:raamb_app/map/singledrivertest.dart';
import 'package:raamb_app/profile/profile_overview.dart';
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
import '../profile/profile_edit.dart';
import '../auth/login_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../transaction/transaction_list.dart';
import '../drawer/favorites.dart';
import '../chat/chat.dart';
import 'package:provider/provider.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:raamb_app/chat/ChatList/chatnew.dart';
import 'dart:math';






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

class _DriverPageState extends State<DriverPage>with SingleTickerProviderStateMixin {
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
  String? email;
 late PersistentTabController _controller;
late AnimationController _animationController;
 
 
  
  
  



  TextEditingController searchController = TextEditingController();

  String? selectedVehicleTypes;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _startLocationTimer();
    updateUserStatus(widget.sessionId, true);
    fetchMechanicUsers();
    _controller = PersistentTabController(initialIndex: 0);
    _animationController= AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    
    
    _loadUserData();
    
    (chatHistory) {
      setState(() {
        _messages.addAll(chatHistory);
      });
    };
    socketService.startSocketConnection();

  
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
    _animationController.dispose();
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
    // First, compare based on isLogged status
    bool isLogged1 = user1['isLogged'] ?? false;
    bool isLogged2 = user2['isLogged'] ?? false;

    if (isLogged1 && !isLogged2) {
      return -1;
    } else if (!isLogged1 && isLogged2) {
      return 1;
    }

    // If both users have the same isLogged status, then compare based on distance
    final location1 = user1['location'];
    final location2 = user2['location'];
    final latitude1 = location1 != null ? location1['latitude'] as double? : null;
    final longitude1 = location1 != null ? location1['longitude'] as double? : null;
    final latitude2 = location2 != null ? location2['latitude'] as double? : null;
    final longitude2 = location2 != null ? location2['longitude'] as double? : null;

    if (latitude1 != null && longitude1 != null && latitude2 != null && longitude2 != null) {
      final distance1 = calculateDistance(
        _locationData?.latitude, _locationData?.longitude, latitude1, longitude1,
      );
      final distance2 = calculateDistance(
        _locationData?.latitude, _locationData?.longitude, latitude2, longitude2,
      );
      return distance1.compareTo(distance2);
    }

    // Handle cases where some location data might be missing
    final distance1 = latitude1 != null && longitude1 != null
      ? calculateDistance(_locationData?.latitude, _locationData?.longitude, latitude1, longitude1)
      : double.maxFinite;
    final distance2 = latitude2 != null && longitude2 != null
      ? calculateDistance(_locationData?.latitude, _locationData?.longitude, latitude2, longitude2)
      : double.maxFinite;

    return distance1.compareTo(distance2);
  });
}





  Future<void> fetchMechanicUsers() async {
    
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
            mechanicUsers[i]['isLogged'] = isLogged;
            filteredMechanicUsers = List.from(
                mechanicUsers.where((user) => user['isLogged'] == true));
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
      // Favorites tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(
            sessionId: widget.sessionId, // Pass the session ID
            mechanicUsers: mechanicUsers,
            
           
            
           
          ),
        ),
      );
    }
   
  }
  // Function to navigate to the Transactions page
  void _navigateToTransactions(String sessionId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TransactionsPage(bookingId: widget.sessionId),
    ));
  }

  // Function to navigate to the Settings page
  void _navigateToSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SettingsPage(),
    ));
  }

  // Function to navigate to the Help Center page
  void _navigateToHelpCenter() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => HelpCenterPage(),
    ));
  }

  // Function to navigate to the Terms and Conditions page
  void _navigateToTermsAndConditions() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TermsAndConditionsPage(),
    ));
  }

  void _showProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileOverview(sessionId: userId),
      ),
    );
  }

  

  

  void _handleLogout() {
   
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => LoginPage(), // Replace with your login page widget
    ));
  }
Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    onTap: onTap,
  );
}
void _confirmLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Do you really want to log out?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Log Out'),
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
          ),
        ],
      );
    },
  );
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
          email = userData['email']; // Add this line to update the email
        });
      }
    }
  }).catchError((error) {
    // Handle any errors here
    print('Error fetching user data: $error');
  });
}



List<Widget> _buildScreens() {
    return [
      DriverPage(sessionId: widget.sessionId), // using the sessionId passed to MyHomePage
      // ChatMessages(),
      MapPage(mechanicUsers: mechanicUsers, sessionId: widget.sessionId,), // using the mechanicUsers passed to MyHomePage
    ];
  }
  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home),
        title: ("Home"),
        activeColorPrimary: Colors.red,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.message),
        title: ("Messages"),
        activeColorPrimary: Colors.red,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.location_on),
        title: ("Map"),
        activeColorPrimary: Colors.red,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

@override
  Widget build(BuildContext context) {
    final double? latitude = _locationData?.latitude;
    final double? longitude = _locationData?.longitude;
    var displayName = '${firstName ?? 'Your'} ${lastName ?? 'Name'}';
     var displayEmail = email ?? 'email@example.com'; // Default email placeholder
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
              fontSize: 18.0,
              ),
            ),
          Text(
            _locationName ?? 'Default Location Name', // Location name falls back to a default if null
            
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.white70,
              
            ),
          ),
          ],
      ),
      actions: <Widget>[
  // Inbox Button inside a SizedBox
  SizedBox(
    width: 50, // Adjust the width as needed
    height: 50, // Adjust the height as needed
    child: IconButton(
      icon: Icon(Icons.email_outlined, size: 25),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecentMessagesScreen(sessionId: widget.sessionId,)), // Navigate to MessageListScreen
        );
      },
    ),
  ),
  // Location Button
  IconButton(
    icon: Icon(Icons.location_on_outlined, size: 25), // Adjust the size of the icon
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => 
        MapPageTest(sessionId: widget.sessionId, mechanicUsers: mechanicUsers)),
        
      );
    },
  ),
  // Refresh Button
  // ... Your Refresh Button code here ...
],

    
      bottom: PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight + 80.0),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
          child: Material(
            borderRadius: BorderRadius.circular(32.0),
            elevation: 1.0,
            child: TextField(
              controller: searchController,
              onChanged: _filterMechanicUsers,
              decoration: InputDecoration(
                labelText: 'Search',
                labelStyle: TextStyle(color: Colors.black), // Dark color for visibility
                prefixIcon: Icon(Icons.search, color: Colors.black), // Black icon for visibility
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white, // White background for the search bar
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'List of Mechanics',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White for contrast
            ),
          ),
        ),
        TabBar(
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Colors.white, // White color for contrast
          unselectedLabelColor: Colors.white.withOpacity(0.5), // Lighter shade for unselected tabs
          tabs: [
            Tab(text: "All"),
            Tab(text: "Motorcycle"),
            Tab(text: "Bicycle"),
            Tab(text: "Automotive"),
              ],
              onTap: (index) {
                // Handle the tap event and perform actions based on the tab
                setState(() {
                  switch (index) {
                    case 0: // Automotive
                      selectedVehicleTypes = null;
                      break;
                    case 1: // Motorcycle
                      selectedVehicleTypes = 'Motorcycle';
                      break;
                    case 2: // Bicycle
                      selectedVehicleTypes = 'Bicycle';
                      break;
                    case 3: // All
                      selectedVehicleTypes = 'Automotive'; // Or set this to 'All' if you have a specific filter for this
                      break;
                  }
                  _filterMechanicByVehicleType(); // Make sure this method uses the selectedVehicleTypes variable to filter
                });
              },
            ),
            
          ],
        ),
        
      ),
      
    ),
        drawer: Drawer(
  child: Column(
    children: [
      Expanded(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(displayName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              accountEmail: Text(email ?? '', style: TextStyle(fontSize: 16)),
              // currentAccountPicture: CircleAvatar(
              //   backgroundImage: NetworkImage(profileImageUrl ?? 'default_image_url'),
              // ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.red[700] ?? Colors.red, // Providing a fallback non-nullable color
        Colors.red[300] ?? Colors.redAccent, // Fallback non-nullable color
          ]
          ),
              ),
            ),
            _buildDrawerItem(Icons.account_circle, 'Profile', () => _showProfile(widget.sessionId)),
            _buildDrawerItem(Icons.history, 'Transactions', () => _navigateToTransactions(widget.sessionId)
            ),
            Divider(thickness: 1, color: Colors.grey.shade400),
            _buildDrawerItem(Icons.settings, 'Settings', () => _navigateToSettings()),
            _buildDrawerItem(Icons.help, 'FAQ', () => _navigateToHelpCenter()),
            _buildDrawerItem(Icons.description, 'Terms and Conditions', () => _navigateToTermsAndConditions()),
  ],
        ),
      ),
      Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          leading: Icon(Icons.exit_to_app),
          title: Text('Log-Out'),
          onTap: () => _confirmLogout(context),
        ),
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
  child: filteredMechanicUsers.isNotEmpty
      ? ListView.builder(
          itemCount: filteredMechanicUsers.length,
          itemBuilder: (context, index) {
            final user = filteredMechanicUsers[index];
            final location = user['location'];
            final latitude = location != null ? location['latitude'] as double? : null;
            final longitude = location != null ? location['longitude'] as double? : null;
            final double distance = latitude != null && longitude != null ? calculateDistance(_locationData?.latitude, _locationData?.longitude, latitude, longitude) : 0;
            final address = location != null ? location['address'] as String? : null;
             final double rawTariff = distance * .05;
             final int tariff = (rawTariff / 50).ceil() * 50;

            return Card(
  elevation: 4,
  margin: EdgeInsets.all(8.0),
 color: user['isLogged'] ? Colors.lightGreen[50] : Colors.red[50],// Lighter shades of red with adjusted opacity
// Adjust opacity for closed state
  child: Stack( // Use a Stack to overlay text
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
                    ListTile(
                      // leading: CircleAvatar(
                      //   backgroundImage: NetworkImage(user['imageUrl'] ?? 'default_placeholder_image_url'),
                      //   radius: 25,
                      // ),
                      title: Center( // Centering the title
              child: Text(
                '${user['firstName'] ?? 'Unknown'} ${user['lastName'] ?? ''}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black54),
              ),
            ),
                      subtitle: Center( // Centering the subtitle
  child: Column(
    mainAxisSize: MainAxisSize.min, // Use the minimum space required by children
    children: <Widget>[
      
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
  children: <Widget>[
    Icon(
      Icons.phone,
      color: Colors.grey.shade800,
      size: 18,
    ),
    SizedBox(width: 5), // Adjust the width as needed for spacing
    Text(
      '${user['phoneNumber'] ?? 'Unknown'}',
      style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
    ),
  ],
),
      
      Align(
  alignment: Alignment.centerRight,
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: user['isLogged'] ? Colors.lightGreen[700] : Colors.red[300], // Adjusted colors for better visibility
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      user['isLogged'] ? 'Available' : 'Unavailable',
      style: TextStyle(color: Colors.white, fontSize: 14),
    ),
  ),
)
    ],
  ),
),
),

                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.home, color: Colors.deepPurple),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '$address',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.redAccent),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${latitude != null && longitude != null ? '${(calculateDistance(_locationData?.latitude, _locationData?.longitude, latitude, longitude) / 1000).toStringAsFixed(2)} km' : 'Not Available'}',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.directions_car, color: Colors.blueGrey),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${user['VehicleType'] ?? 'Unknown'}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                   Row(
      children: [
        // Icon(Icons.attach_money_outlined, color: Colors.green),
        SizedBox(width: 5),
        Expanded(
          child: Text(
            '₱ ${tariff.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
                        ),
                      ],
                    ),
                    Divider(),// Visual separator
        Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: <Widget>[
    // Call Button
    TextButton.icon(
      icon: Icon(Icons.phone, color: Colors.blue, size: 24),
      label: Text('Call', style: TextStyle(color: Colors.blue, fontSize: 16)),
      onPressed: () => callUser(user['phoneNumber']),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        shadowColor: Colors.blue.withOpacity(0.2),
        elevation: 2,
      ),
    ),
    // Message Button
    TextButton.icon(
      icon: Icon(Icons.message, color: Colors.green, size: 24),
      label: Text('Message', style: TextStyle(color: Colors.green, fontSize: 16)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatMessagesTest(sessionId: widget.sessionId, user: user['_id'], firstName: user['firstName'], lastName: user['lastName'])),
        );
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        shadowColor: Colors.green.withOpacity(0.2),
        elevation: 2,
      ),
    ),
    // Book Button
    TextButton.icon(
      icon: Icon(Icons.book_online, color: Colors.red, size: 24),
      label: Text('Book', style: TextStyle(color: Colors.red, fontSize: 16)),
      onPressed: () {
        if (latitude != null && longitude != null) {
          Map<String, dynamic> userIdMap = user;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SingleDriverTest(sessionId: widget.sessionId, mechanicUsers: [userIdMap]),
            ),
          );
        } else {
          // Handle null latitude/longitude
        }
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        shadowColor: Colors.red.withOpacity(0.2),
        elevation: 2,
      ),
    ),
  ],
)   
          ]
    )
  ),

          ],
          ),
          );
      },
                    )
                  : Center(
                      child: Text('No Mechanics found.'),
                    ),
            ),
          ],
        ),
        // Floating Action Button
   floatingActionButton: RotationTransition(
        turns: Tween(begin: 0.0, end: 1.0).animate(_animationController),
        child: FloatingActionButton(
          onPressed: () {
            sortMechanicUsers();
            _animationController.forward(from: 0.0); // Start the rotation animation
          },
          child: Icon(Icons.refresh),
        ),
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
          
          final vehicleTypeList = user['VehicleType'];
          return vehicleTypeList != null &&
              vehicleTypeList.contains(selectedVehicleTypes);
        }
      }).toList();
    });
    print("Filtered Mechanics: $filteredMechanicUsers");
  }
}
