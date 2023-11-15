import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../values/values.dart';

import '../widgets/progress_card_close_button.dart';
import '../background/darkRadialBackground.dart';
import 'dart:convert';
import '../widgets/container_label.dart';
import 'package:http/http.dart' as http;
import '../../service/mongo_service.dart';
import '../profile/profile_verification.dart';
import '../profile/edit_profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileOverview extends StatefulWidget {
  final String sessionId;

  ProfileOverview({required this.sessionId});

  @override
  _ProfileOverviewState createState() => _ProfileOverviewState();
}

class _ProfileOverviewState extends State<ProfileOverview> {
  String? profilePictureUrl;
  

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      final bytes = file.readAsBytesSync();
      String base64Image = base64Encode(bytes);

      try {
        var response = await http.post(
          
          Uri.parse('https://63a5-2001-4454-415-8a00-d420-28e1-55cb-d200.ngrok-free.app/uploadProfilePicture'),
 
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "image": base64Image,
            "userId": widget.sessionId, // Accessing sessionId via widget
          }),
         
        );
 print('treat');

        if (response.statusCode == 200) {
          // Assuming the server returns the URL of the stored image
          var data = jsonDecode(response.body);
          setState(() {
            profilePictureUrl = data['imageUrl']; // Adjust based on your server's response
          });
        } else {
          // Handle error
          print('Failed to upload image: ${response.statusCode}');
        }
      } catch (e) {
        // Handle any errors during the HTTP request
        print('Error occurred: $e');
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final LoginSession loginSession = Provider.of<LoginSession>(context);
    TextEditingController contactNumberController = TextEditingController();

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
                            child: Column(
                              children: [
                                // ElevatedButton(
                                //   onPressed: () {
                                //     // Navigate to the EditProfilePage when the button is pressed
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(
                                //         builder: (context) => EditProfilePage(),
                                //       ),
                                //     );
                                //   },
                                //   child: Text('Edit Profile'),
                                // ),
                                SizedBox(
                                  height: 10,
                                ), // Add some spacing between buttons
                              ],
                            ),
                          ),
                          AppSpaces.verticalSpace20,
                          ContainerLabel(label: "Profile Data"),
                          AppSpaces.verticalSpace10,
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
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    // Move the verification logic here
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VerificationPage(),
                                      ),
                                    );
                                  },
                                  child: Text('Verify'),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors
                                        .red, // Customize the button's color
                                    onPrimary: Colors
                                        .white, // Customize the text color
                                  ),
                                ),

                              ],
                            ),
                          ),
                         
                          AppSpaces.verticalSpace20,
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
            // Error handling
            return Center(child: Text('Failed to load user data.'));
          }
        },
      ),
    );
  }
}
