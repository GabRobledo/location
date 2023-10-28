import 'package:flutter/material.dart';

class MechanicReviewPage extends StatefulWidget {
  final String orderNumber;
  final String customerName;
  final String customerAddress;
  final String comment;
  final String fare;
  final String issue;
  final String photo;
  final String distance;
  final String paymentMethod;

  MechanicReviewPage({
    required this.orderNumber,
    required this.customerName,
    required this.customerAddress,
    required this.comment,
    required this.fare,
    required this.issue,
    required this.photo,
    required this.distance,
    required this.paymentMethod,
  });

  @override
  _MechanicReviewPageState createState() => _MechanicReviewPageState();
}

class _MechanicReviewPageState extends State<MechanicReviewPage> {
  int _selectedIndex = 0;
  TextEditingController searchController = TextEditingController();
  String? orderNumber;
  String? customerName;
  String? customerAddress;
  String? comment;
  String? fare;
  String? issue;
  String? photo;
  String? distance;
  String? paymentMethod;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search for something...',
                  prefixIcon: Icon(Icons.search),
                )),
            SizedBox(
                height:
                    16.0), // Add some spacing between search bar and content
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(),
            ),
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 3,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request #$orderNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28.0,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    'Customer: $customerName',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22.0,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Delivery Address: $customerAddress',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.grey,
                    ),
                  ),
                  Divider(height: 20, thickness: 2.0, color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Text('Fare: $fare', style: TextStyle(fontSize: 20.0)),
                      Text('Issue: $issue', style: TextStyle(fontSize: 20.0)),
                    ],
                  ),
                  // SizedBox(height: 20.0),
                  // Text(
                  //   'Payment Method: $paymentMethod',
                  //   style: TextStyle(fontSize: 20.0),
                  // ),
                  Text(
                    'Comment: $comment',
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Handle the Accept button press
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                        ),
                        child: Text(
                          'Accept',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Handle the Decline button press
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red,
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                        ),
                        child: Text(
                          'Decline',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
    );
  }
}
