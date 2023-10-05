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
import '../../service/mongo_service.dart'; // Import your MongoDB service file
// Import your login session class

class ProfileOverview extends StatelessWidget {
  final String sessionId;

  const ProfileOverview({Key? key, required this.sessionId}) : super(key: key);

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
                          Align(
                            alignment: Alignment.center,
                            child: ProfileDummy(
                              color: HexColor.fromHex("f19494"),
                              dummyType: ProfileDummyType.Icon,
                              scale: 3.0,
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
                            child: OutlinedButtonWithText(
                              width: 150,
                              content: "Edit Profile",
                              onPressed: () {},
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
                                PrimaryProgressButton(
                                  width: 90,
                                  height: 40,
                                  label: "Verify",
                                  textStyle: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
                          AppSpaces.verticalSpace20,
                          ContainerLabel(label: "Notification"),
                          AppSpaces.verticalSpace10,
                          BadgedContainer(
                            label: "Do not disturb",
                            callback: () {},
                            value: "Off",
                            badgeColor: "FDA5FF",
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
