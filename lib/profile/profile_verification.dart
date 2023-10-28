import 'package:flutter/material.dart';

class VerificationPage extends StatefulWidget {
  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController mobileNumberController = TextEditingController();
  String mobileNumberError = '';

  @override
  void dispose() {
    mobileNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification'),
        backgroundColor:
            Colors.red, // Changed the app bar background color to red.
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Verification Requirements',
                style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ),
            _buildRequirementCard('1. Upload ID Picture',
                'Capture or select your ID photo', Icons.camera_alt, () {
              // Implement ID picture upload logic here.
            }),
            const SizedBox(height: 20.0),
            _buildRequirementCard('2. Upload Profile Picture',
                'Add your profile photo', Icons.camera_alt, () {
              // Implement profile picture upload logic here.
            }),
            const SizedBox(height: 20.0),
            _buildTextField(
                '3. Enter Mobile Number', 'Mobile Number', TextInputType.phone),
            const SizedBox(height: 20.0),
            _buildRequirementCard('4. Upload License Picture',
                'Capture or select your license photo', Icons.camera_alt, () {
              // Implement license picture upload logic here.
            }),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                // Validate the mobile number.
                if (mobileNumberController.text.isEmpty ||
                    !isValidMobileNumber(mobileNumberController.text)) {
                  setState(() {
                    mobileNumberError = 'Invalid mobile number';
                  });
                } else {
                  // Clear any previous error.
                  setState(() {
                    mobileNumberError = '';
                  });
                  // Implement verification submission logic here.
                  // You can send the entered data and uploaded images to the server or admin for verification.
                }
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.red, // Changed the button color to red.
                minimumSize: Size(double.infinity, 50.0),
              ),
              child:
                  Text('Submit Verification', style: TextStyle(fontSize: 20.0)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementCard(
      String title, String subtitle, IconData icon, Function onPressed) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        onTap: () {
          if (onPressed != null) {
            onPressed();
          }
        },
        leading: Icon(icon,
            size: 36.0, color: Colors.red), // Changed the icon color to red.
        title: Text(title,
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 16.0)),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildTextField(
      String labelText, String hintText, TextInputType keyboardType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText,
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
        TextField(
          controller: mobileNumberController,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: mobileNumberError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                  color: Colors.red), // Changed the border color to red.
            ),
          ),
        ),
      ],
    );
  }

  bool isValidMobileNumber(String value) {
    // Implement your mobile number validation logic here.
    // Return true for a valid number, or false for an invalid number.
    return true;
  }
}
