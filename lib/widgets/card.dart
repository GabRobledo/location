import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/location.dart';
import '../values/values.dart';
import '../widgets/green_done_icon.dart';
import '../widgets/profile_dummy.dart';

class ProjectTaskInActiveCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double distance;

  const ProjectTaskInActiveCard({
    Key? key,
    required this.user,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.distance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void callUser(String phoneNumber) async {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to make the phone call.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }

    return InkWell(
      onTap: () {},
      child: Container(
          width: double.infinity,
          height: 160,
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
              //color: AppColors.primaryBackgroundColor,
              border:
                  Border.all(color: AppColors.primaryBackgroundColor, width: 4),
              borderRadius: BorderRadius.circular(10)),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBackgroundColor,
                ),
                child: IconButton(
                  icon: GreenDoneIcon(),
                  onPressed: () {
                    callUser(user['phoneNumber'] ?? '');
                  },
                ),
              ),
              AppSpaces.horizontalSpace20,
              Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: ${user['firstName']?.toString() ?? 'Unknown'} ${user['lastName']?.toString() ?? ''}',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Phone: ${user['phoneNumber'] ?? 'Unknown'}',
                      style: GoogleFonts.lato(color: Colors.white),
                    ),
                    Text(
                      'Latitude: ${latitude?.toStringAsFixed(6) ?? 'Unknown'}', // Use ?. to safely access 'latitude'
                      style:
                          GoogleFonts.lato(color: HexColor.fromHex("EA9EEE")),
                    ),
                    Text(
                      'Longitude: ${longitude?.toStringAsFixed(6) ?? 'Unknown'}', // Use ?. to safely access 'longitude'
                      style:
                          GoogleFonts.lato(color: HexColor.fromHex("8ECA84")),
                    ),
                    Text(
                      '${address ?? 'Unknown'}',
                      style: GoogleFonts.lato(color: Colors.grey),
                    ),
                    Text(
                      'Distance: ${latitude != null && longitude != null ? distance.toStringAsFixed(2) : 'Unknown'} meters',
                      style: GoogleFonts.lato(color: Colors.grey),
                    )
                  ])
            ]),
            ProfileDummy(
                color: Colors.green,
                dummyType: ProfileDummyType.Icon,
                image: "",
                scale: 1.0),
          ])),
    );
  }
}
