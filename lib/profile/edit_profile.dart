import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.openSans(), // Updated font
        ),
        backgroundColor: Colors.redAccent, // Changed to red accent
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Your Profile:',
              style: GoogleFonts.openSans(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700, // Red color for the header
              ),
            ),
            SizedBox(height: 30.0),
            buildTextField(
              controller: firstNameController,
              labelText: 'First Name',
              hintText: 'Enter your first name',
            ),
            SizedBox(height: 20.0),
            buildTextField(
              controller: lastNameController,
              labelText: 'Last Name',
              hintText: 'Enter your last name',
            ),
            SizedBox(height: 20.0),
            buildTextField(
              controller: emailController,
              labelText: 'Email',
              hintText: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: () {
                // Save the updated profile information
              },
              child: Text(
                'Save Changes',
                style: GoogleFonts.openSans(fontSize: 18.0),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.redAccent, // Updated to red accent
                padding: EdgeInsets.symmetric(vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(color: Colors.red.shade700), // Red color for the label
        hintStyle: TextStyle(color: Colors.red.shade300), // Lighter red for the hint
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade700),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      cursorColor: Colors.redAccent, // Cursor color to match the theme
      keyboardType: keyboardType,
      style: GoogleFonts.openSans(color: Colors.black), // Text color
    );
  }
}
