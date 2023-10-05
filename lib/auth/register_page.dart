import 'package:flutter/material.dart';
import '../main.dart';
import 'package:flutter_dropdown/flutter_dropdown.dart';
import '../home_page.dart';
import 'login_page.dart';
import '../service/mongo_service.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController homeAddressController = TextEditingController();
  TextEditingController emailVerificationController = TextEditingController();
  TextEditingController mobileNumberVerificationController =
      TextEditingController();
  TextEditingController uploadPhotoController = TextEditingController();
  String selectedRole = "";
  List<String> selectedVehicleTypes = [];

  bool isUserRegistered = false;
  bool isLoading = false;

  void register() async {
    final email = emailController.text;
    final firstName = firstNameController.text;
    final lastName = lastNameController.text;
    final phoneNumber = phoneNumberController.text;
    final password = passwordController.text;
    final role = selectedRole;
    final homeAddress = homeAddressController.text;
    // final emailVerification = emailVerificationController.text;
    final mobileNumberVerification = mobileNumberVerificationController.text;
    final uploadPhoto = uploadPhotoController.text;

    // Validate inputs
    if (email.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        phoneNumber.isEmpty ||
        password.isEmpty ||
        role.isEmpty ||
        homeAddress.isEmpty ||
        // emailVerification.isEmpty ||
        mobileNumberVerification.isEmpty ||
        uploadPhoto.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please fill in all required fields.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
        .hasMatch(email)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content:
              Text('Invalid email format. Please enter a valid email address.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    // Validate password strength (minimum 6 characters)
    if (password.length < 6) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Password should be at least 6 characters long.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    if (role.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please select a role.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    // Validate selected vehicle types if the role is "Mechanic"
    if (role == "Mechanic" && selectedVehicleTypes.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please select at least one vehicle type.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    Map<String, dynamic>? registrationResult = await registerUser(
      email,
      firstName,
      lastName,
      phoneNumber,
      password,
      role,
      selectedVehicleTypes,
    );

    Navigator.pop(context); // Dismiss the loading dialog

    if (registrationResult != null && registrationResult['success'] == true) {
      setState(() {
        isUserRegistered = true;
        isLoading = false;
      });

      final loginSession = Provider.of<LoginSession>(context, listen: false);
      loginSession.setUserId(registrationResult['user']['_id']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Registration failed. Please try again.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email Verification'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: homeAddressController,
                decoration: InputDecoration(labelText: 'Home Address'),
              ),
              // SizedBox(height: 16.0),
              // TextField(
              //   controller: emailVerificationController,
              //   decoration: InputDecoration(labelText: 'Email Verification'),
              // ),
              SizedBox(height: 16.0),
              TextField(
                controller: mobileNumberVerificationController,
                decoration:
                    InputDecoration(labelText: 'Mobile Number Verification'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: uploadPhotoController,
                decoration: InputDecoration(labelText: 'Upload Photo'),
              ),
              SizedBox(height: 16.0),
              DropDown(
                items: ["Driver", "Mechanic"],
                hint: Text("Role"),
                icon: Icon(
                  Icons.expand_more,
                  color: Colors.blue,
                ),
                onChanged: (v) {
                  setState(() {
                    selectedRole = v!;
                    selectedVehicleTypes.clear();
                  });
                },
              ),
              // Show vehicle type checkboxes only if the role is "Mechanic"
              if (selectedRole == "Mechanic")
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Vehicle Types:",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: Text("Automotive"),
                      value: selectedVehicleTypes.contains("Automotive"),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            selectedVehicleTypes.add("Automotive");
                          } else {
                            selectedVehicleTypes.remove("Automotive");
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text("Motorcycle"),
                      value: selectedVehicleTypes.contains("Motorcycle"),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            selectedVehicleTypes.add("Motorcycle");
                          } else {
                            selectedVehicleTypes.remove("Motorcycle");
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text("Bicycle"),
                      value: selectedVehicleTypes.contains("Bicycle"),
                      onChanged: (value) {
                        setState(() {
                          if (value!) {
                            selectedVehicleTypes.add("Bicycle");
                          } else {
                            selectedVehicleTypes.remove("Bicycle");
                          }
                        });
                      },
                    ),
                  ],
                ),
              SizedBox(height: 24.0),
              ElevatedButton(
                child: Text('Register'),
                onPressed: register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
