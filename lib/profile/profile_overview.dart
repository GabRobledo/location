import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../main.dart'; // Adjust this import based on your project structure
import '../values/values.dart'; // Adjust this import based on your project structure
import '../widgets/progress_card_close_button.dart'; // Adjust this import based on your project structure
import '../background/darkRadialBackground.dart'; // Adjust this import based on your project structure
import '../../service/mongo_service.dart'; // Adjust this import based on your project structure
import '../profile/profile_verification.dart'; // Adjust this import based on your project structure
import '../profile/edit_profile.dart'; // Adjust this import based on your project structure

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return "";
    return this[0].toUpperCase() + this.substring(1).toLowerCase();
  }
}
class ProfileOverview extends StatefulWidget {
  final String sessionId;

  ProfileOverview({required this.sessionId});

  @override
  _ProfileOverviewState createState() => _ProfileOverviewState();
}

class _ProfileOverviewState extends State<ProfileOverview> {
   final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
bool isLoading = false;
  String? profilePictureUrl;

  @override
  void initState() {
    super.initState();
    // fetchUserData();
  }
  // Future<void> fetchUserData() async {
  //   setState(() => isLoading = true);
  //   final userData = await getUserData(widget.sessionId);
  //   if (userData != null) {
  //     usernameController.text = userData['username'] ?? '';
  //     firstNameController.text = userData['firstName'] ?? '';
  //     addressController.text = userData['address'] ?? '';
  //     dobController.text = userData['dateOfBirth'] ?? '';
  //     contactNumberController.text = userData['contactNumber'] ?? '';
  //   } else {
  //     // Handle user not found
  //     debugPrint("User not found");
  //   }
  //   setState(() => isLoading = false);
  // }

  Future<void> saveProfile() async {
    setState(() => isLoading = true);
    Map<String, dynamic> updatedProfile = {
      'username': usernameController.text,
      'firstName': firstNameController.text,
      'address': addressController.text,
      'dateOfBirth': dobController.text,
      'contactNumber': contactNumberController.text,
    };

    final bool success = await updateUserProfile(widget.sessionId, updatedProfile);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile successfully updated!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile.')),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      final bytes = file.readAsBytesSync();
      String base64Image = base64Encode(bytes);

      try {
        var response = await http.post(
          Uri.parse('YOUR_UPLOAD_ENDPOINT'), // Replace with your endpoint
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "image": base64Image,
            "userId": widget.sessionId,
          }),
        );

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          setState(() {
            profilePictureUrl = data['imageUrl'];
          });
        } else {
          print('Failed to upload image: ${response.statusCode}');
        }
      } catch (e) {
        print('Error occurred: $e');
      }
    }
  }
   @override
  void dispose() {
    usernameController.dispose();
    firstNameController.dispose();
    addressController.dispose();
    dobController.dispose();
    contactNumberController.dispose();
    super.dispose();
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
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 20.0),
                          Text(
                            "${user['firstName']} ${user['lastName']}",
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
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
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                          AppSpaces.verticalSpace20,
                          containerLabel("Edit Profile"),
                          AppSpaces.verticalSpace10,
                          _buildEditableUserInfoRow("Username", usernameController),
                          _buildEditableUserInfoRow("First Name", firstNameController),
                          _buildEditableUserInfoRow("Address", addressController),
                          _buildEditableUserInfoRow("Date of Birth", dobController),
                          _buildEditableUserInfoRow("Contact Number", contactNumberController),
                          AppSpaces.verticalSpace20,
                          ElevatedButton(
                            onPressed: saveProfile,
                            child: Text('Save Changes'),
                          ),
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
                    child: ProgressCardCloseButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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

Widget containerLabel(String label) {
    return Text(
      label,
      style: TextStyle(/* Your TextStyle here */),
    );
  }

  Widget _buildUserInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(value ?? "Not available", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
  Widget _buildEditableUserInfoRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
        ),
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}


// Add other necessary classes (e.g., LoginSession) or imports as needed based on your project structure.
