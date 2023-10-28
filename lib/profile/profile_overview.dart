import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../values/values.dart';
import '../widgets/primary_progress_button.dart';
import '../widgets/progress_card_close_button.dart';
import '../background/darkRadialBackground.dart';
import '../widgets/badged_container.dart';
import '../widgets/text_outlined_button.dart';
import '../widgets/container_label.dart';
import '../widgets/profile_dummy.dart';
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
                          // Display the profile picture or a default image
                          Container(
                            width: 150.0,
                            height: 150.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: profilePictureUrl != null
                                    ? FileImage(
                                        File(
                                            profilePictureUrl!)) as ImageProvider<
                                        Object> // Cast to ImageProvider<Object>
                                    : NetworkImage(user['profilePictureUrl'] ??
                                        ''), // Use the default profile picture URL
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Implement the logic to upload a new profile picture
                                // You can use image picker libraries for this purpose.
                              },
                              child: profilePictureUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 100.0,
                                      color: Colors.grey,
                                    )
                                  : null, // Display a default icon if there's no profile picture
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _uploadProfilePicture,
                            child: Text('Upload Profile Picture'),
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
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    // Navigate to the EditProfilePage when the button is pressed
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfilePage(),
                                      ),
                                    );
                                  },
                                  child: Text('Edit Profile'),
                                ),
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

                                //   AppSpaces.verticalSpace10,
                                //   ContainerLabel(label: "Contact Number"),
                                //   AppSpaces.verticalSpace10,
                                //   Container(
                                //     width: double.infinity,
                                //     height: 50,
                                //     padding: EdgeInsets.all(10.0),
                                //     decoration: BoxDecoration(
                                //       color: AppColors.primaryBackgroundColor,
                                //       borderRadius: BorderRadius.circular(10),
                                //     ),
                                //     child: Row(
                                //       mainAxisAlignment:
                                //           MainAxisAlignment.spaceBetween,
                                //       children: [
                                //         Expanded(
                                //           child: TextField(
                                //             controller: contactNumberController,
                                //             decoration: InputDecoration(
                                //               hintText:
                                //                   'Enter your contact number',
                                //               border: InputBorder.none,
                                //             ),
                                //             style: TextStyle(color: Colors.white),
                                //           ),
                                //         ),
                                //         PrimaryProgressButton(
                                //           width: 90,
                                //           height: 40,
                                //           label: "Verify",
                                //           textStyle: GoogleFonts.lato(
                                //             color: Colors.white,
                                //             fontWeight: FontWeight.bold,
                                //           ),
                                //           // onPressed: () {
                                //           //   // Implement contact number verification logic here
                                //           //   String contactNumber =
                                //           //       contactNumberController.text;
                                //           //   // You can send the contact number for verification and handle the result.
                                //           //   // You may want to show a confirmation dialog or update the UI accordingly.
                                //           // },
                                //         ),
                                //       ],
                                //     ),
                                //   ),
                                // ],
                              ],
                            ),
                          ),
                          // AppSpaces.verticalSpace20,
                          // ContainerLabel(label: "Notification"),
                          // AppSpaces.verticalSpace10,
                          // BadgedContainer(
                          //   label: "Do not disturb",
                          //   callback: () {},
                          //   value: "Off",
                          //   badgeColor: "FDA5FF",
                          // ),
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
