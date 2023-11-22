import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../values/values.dart';

import '../widgets/progress_card_close_button.dart';
import '../background/darkRadialBackground.dart';

import '../widgets/container_label.dart';

import '../../service/mongo_service.dart';
import '../profile/profile_verification.dart';
import '../profile/profile_edit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';



class ProfileOverview extends StatefulWidget {
  final String sessionId;

  ProfileOverview({required this.sessionId});

  @override
  _ProfileOverviewState createState() => _ProfileOverviewState();
}

class _ProfileOverviewState extends State<ProfileOverview> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController dobController = TextEditingController(); // Date of Birth
  TextEditingController contactNumberController = TextEditingController();
  String? profilePictureUrl;

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);

      // Update the profile picture URL
      setState(() {
        profilePictureUrl =
            file.path; // Set the profile picture URL to the local file path
      });
    }
  }
  Widget createInfoRow(String label, String? value, IconData icon) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppColors.primaryBackgroundColor, // Define a secondary background color
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, color: HexColor.fromHex("#FFD700")), // Gold color icon
        SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'Not Available',
            textAlign: TextAlign.right,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 17,
            ),
          ),
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    final LoginSession loginSession = Provider.of<LoginSession>(context);

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(loginSession.getUserId()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            final user = snapshot.data!;

            return Stack(
              children: [
                DarkRadialBackground(
                  color: HexColor.fromHex("#1f1818"),
                  position: "topLeft",
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20.0),
                          // Display the profile picture or a default image
                          Container(
                            width: 150.0,
                            height: 150.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: profilePictureUrl != null
                                ? Image.file(
                                    File(profilePictureUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 100,
                                  ),
                          ),
                          ElevatedButton(
      onPressed: _uploadProfilePicture,
      child: Text('Upload Photo'),
      style: ElevatedButton.styleFrom(
        primary: Colors.redAccent, // Define your button color
        onPrimary: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "${user['firstName'].toString().capitalize} ${user['lastName'].toString().capitalize}",
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            user['email'],
                            style: GoogleFonts.lato(
                              color: HexColor.fromHex("#ffb3ff"),
                              fontSize: 17,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfileEdit(sessionId: widget.sessionId),
                                  ),
                                );
                              },
                              child: Text('Edit Profile'),
                            ),
                          ),
                          SizedBox(height: 20),
                          ContainerLabel(label: "Profile Data"),
                          SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            height: 90,
                            padding: EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${user['firstName'].toString().capitalize} ${user['lastName'].toString().capitalize}",
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      user['email'],
                                      style: GoogleFonts.lato(
                                        fontWeight: FontWeight.bold,
                                        color: HexColor.fromHex("#725e64"),
                                      ),
                                    ),
                                  ],
                                ),
                                // ElevatedButton(
                                //   onPressed: () {
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(
                                //         builder: (context) =>
                                //             VerificationPage(),
                                //       ),
                                //     );
                                //   },
                                //   child: Text('Verify'),
                                //   style: ElevatedButton.styleFrom(
                                //     primary: Colors.red,
                                //     onPrimary: Colors.white,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                          SizedBox(height: 25),
                          createInfoRow('Address', user['address'], Icons.location_on),
    createInfoRow('Username', user['username'], Icons.person),
    createInfoRow('Phone Number', user['phoneNumber'], Icons.phone),
    createInfoRow('Date of Birth', user['dateOfBirth'], Icons.cake), // Assuming 'dob' is the key for the date of birth in your user data
    SizedBox(height: 25),
  ],
),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: Transform.scale(
                    scale: 1.2,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.close),
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('Failed to load user data.'));
          }
        },
      ),
    );
  }
}
