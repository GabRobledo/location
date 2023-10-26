import 'package:flutter/material.dart';

class VerificationPage extends StatefulWidget {
  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  // Declare variables for user input, e.g., mobile number, uploaded images, etc.
  String mobileNumber = '';
  // You can declare other variables for uploaded images here.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Page'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Verification Requirements:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            // 1. Upload ID Picture
            Text('1. Upload ID Picture:'),
            ElevatedButton(
              onPressed: () {
                // Implement ID picture upload logic here (e.g., using ImagePicker).
              },
              child: Text('Upload ID Picture'),
            ),
            SizedBox(height: 10.0),
            // 2. Upload Profile Picture
            Text('2. Upload Profile Picture:'),
            ElevatedButton(
              onPressed: () {
                // Implement profile picture upload logic here (e.g., using ImagePicker).
              },
              child: Text('Upload Profile Picture'),
            ),
            SizedBox(height: 10.0),
            // 3. Enter Mobile Number (Fixed)
            Text('3. Enter Mobile Number:'),
            TextFormField(
              onChanged: (value) {
                setState(() {
                  mobileNumber = value;
                });
              },
              keyboardType: TextInputType.phone, // Set keyboard type to phone.
              decoration: InputDecoration(
                hintText: 'Mobile Number',
              ),
            ),
            SizedBox(height: 10.0),
            // 4. Upload License Picture
            Text('4. Upload License Picture:'),
            ElevatedButton(
              onPressed: () {
                // Implement license picture upload logic here (e.g., using ImagePicker).
              },
              child: Text('Upload License Picture'),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Implement verification submission logic here.
                // You can send the entered data and uploaded images to the server or admin for verification.
              },
              child: Text('Submit Verification'),
            ),
          ],
        ),
      ),
    );
  }
}
