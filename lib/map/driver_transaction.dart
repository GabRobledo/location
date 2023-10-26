import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DriverTransactionPage extends StatefulWidget {
  @override
  _DriverTransactionPageState createState() => _DriverTransactionPageState();
}

class _DriverTransactionPageState extends State<DriverTransactionPage> {
  double distance = 0.0;
  double fare = 0.0;
  List<Map<String, dynamic>> filteredMechanicUsers = [];
  LocationData? _locationData;
  String selectedIssue = 'Engine Issue';
  final List<Map<String, dynamic>> availableIssues = [
    {
      'label': 'Engine Issue',
      'icon': Icons.engineering,
    },
    {
      'label': 'Brake Problem',
      'icon': Icons.car_crash,
    },
    {
      'label': 'Tire Repair',
      'icon': Icons.directions_car,
    },
    {
      'label': 'Others',
      'icon':
          Icons.miscellaneous_services, // Use an appropriate icon for "Others"
    },
  ];
  XFile? selectedImage; // Declare the variable within the class

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Selected Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100, // Adjust the width to your preference
                height: 100, // Adjust the height to your preference
                child: Image.file(File(image.path)),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Confirm'),
              ),
            ],
          ),
        ),
      );
      setState(() {
        selectedImage = image;
      });
    } else {
      // User canceled the image selection.
      // You can display a message or handle this case as needed.
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final double? latitude = _locationData?.latitude;
    final double? longitude = _locationData?.longitude;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Page'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(latitude ?? 50, longitude ?? 50),
                  zoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_locationData?.latitude ?? 50,
                            _locationData?.longitude ?? 50),
                        width: 80,
                        height: 80,
                        builder: (context) => Icon(Icons.pin_drop),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Vertically center align
                children: [
                  SizedBox(height: 20),
                  buildSectionTitle('Select Issue'),
                  buildSelectIssueSection(), // Pass ther list of available issues
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _uploadPhoto,
                    icon: Icon(Icons.photo),
                    label: Text('Upload Photo'),
                  ),
                  if (selectedImage != null)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 16),
                        Container(
                          // width: 500, // Adjust the width to your preference
                          // height: 100, // Adjust the height to your preference
                          child: Image.file(File(selectedImage!.path)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            SizedBox(height: 60),
            Center(
              child: GestureDetector(
                onTap: submitRequest,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    border: Border.all(
                      color: Color.fromARGB(255, 255, 32, 21),
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.send,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Submit Request',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget buildSelectIssueSection() {
    return Column(
      children: [
        Row(
          children: availableIssues.map((issue) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedIssue = issue['label'];
                });
              },
              child: Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Icon(issue['icon'],
                        color: selectedIssue == issue['label']
                            ? Colors.blue
                            : Colors.grey),
                    Text(issue['label'],
                        style: TextStyle(
                            color: selectedIssue == issue['label']
                                ? Colors.blue
                                : Colors.grey)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        // SizedBox(height: 16),
        // ElevatedButton.icon(
        //   onPressed: _uploadPhoto,
        //   icon: Icon(Icons.photo),
        //   label: Text('Upload Photo'),
        // ),
        // if (selectedImage != null) // Display the selected image if available
        //   Column(
        //     children: [
        //       SizedBox(height: 16),
        //       Image.file(File(selectedImage!.path)),
        //     ],
        //   ),
        // SizedBox(height: 120), // Added spacing
        // Center(
        //   child: GestureDetector(
        //     onTap: submitRequest,
        //     child: Container(
        //       padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        //       decoration: BoxDecoration(
        //         color: Colors.redAccent,
        //         border: Border.all(
        //           color: Color.fromARGB(255, 255, 32, 21),
        //         ),
        //         borderRadius: BorderRadius.circular(40),
        //       ),
        //       child: Row(
        //         mainAxisSize: MainAxisSize.min,
        //         children: <Widget>[
        //           Icon(Icons.send, color: Color.fromARGB(255, 255, 255, 255)),
        //           SizedBox(width: 8),
        //           Text(
        //             'Submit Request',
        //             style: TextStyle(
        //               color: Color.fromARGB(255, 255, 255, 255),
        //               fontSize: 18,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  void submitRequest() {
    // Placeholder logic to send the transaction request to the mechanic.
    // You would typically make an API request to your backend here.
    // Example: sendTransactionRequest(distance, selectedIssue, selectedImage);
  }
}
