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


import '../widgets/profileanimatedbutton.dart'; // Adjust this import based on your project structure


class ProfileEdit extends StatefulWidget {
  final String sessionId;

  ProfileEdit({required this.sessionId});

  @override
  _ProfileEditState createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  String? profilePictureUrl;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }
Future<void> _fetchUserData() async {
    setState(() => isLoading = true);
    try {
      userData = await getUserData(widget.sessionId);
      if (userData != null) {
        _populateTextFields(userData!);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  void _populateTextFields(Map<String, dynamic> data) {
    usernameController.text = data['username'] ?? '';
    firstNameController.text = data['firstName'] ?? '';
    lastNameController.text = data['lastName'] ?? '';
    addressController.text = data['address'] ?? '';
    dobController.text = data['dateOfBirth'] ?? '';
    contactNumberController.text = data['phoneNumber'] ?? '';
  }

  Future<void> saveProfile() async {
  setState(() => isLoading = true);
  print ('doin');
  try {
    Map<String, dynamic> updatedProfile = {
      'username': usernameController.text,
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'address': addressController.text,
      'dateOfBirth': dobController.text,
      'phoneNumber': contactNumberController.text,
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
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now())
      setState(() {
        controller.text = "${picked.toLocal()}".split(' ')[0];
      });
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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userData == null
              ? Center(child: Text('Failed to load user data.'))
              : Stack(
                  children: [
                    DarkRadialBackground(
                      color: HexColor.fromHex("#1f1818"),
                      position: "topLeft",
                    ),
                    Padding(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      child: SafeArea(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 40),
                                _buildHeader(userData!),
                                _buildEditableUserInfoRow("Username", usernameController),
                                _buildEditableUserInfoRow("First Name", firstNameController),
                                _buildEditableUserInfoRow("Last Name", lastNameController),
                                _buildEditableUserInfoRow("Address", addressController),
                                _buildEditableUserInfoRow("Date of Birth", dobController, isDate: true),
                                _buildEditableUserInfoRow(
  "Enter Phone Number",
  contactNumberController,
  validator: validateContactNumber,
),

                                SizedBox(height: 20),
                              Center( // Centering the Save Changes button
                                child: AnimatedButton(
                                  label: 'Save Changes',
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      saveProfile();
                                    }
                                  },
                                ),
                              ),
                          // Additional buttons or widgets can be added here
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Positioned(
  top: 40,
  left: 10,
 
  child: IconButton(
    icon: Icon(Icons.arrow_back),
    color: Colors.white, // Use 'color' instead of 'colors'
    onPressed: () => Navigator.of(context).pop(),
  ),
),

                  ],
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
  Widget _buildEditableUserInfoRow(String label, TextEditingController controller, {bool isDate = false, String? Function(String?)? validator}) {
  FocusNode focusNode = FocusNode();
  bool isDataNull = controller.text.isEmpty;
  TextInputType keyboardType = isDate ? TextInputType.datetime : TextInputType.text;
  if (label.toLowerCase().contains("contact number")) {
    keyboardType = TextInputType.number;
  }

  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: TextFormField(
      focusNode: focusNode,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: focusNode.hasFocus || !isDataNull ? Colors.white : Colors.grey,
        ),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white24,
      ),
      style: TextStyle(
        color: Colors.white, // Text is always white
      ),
      onTap: isDate ? () => _selectDate(context, controller) : null,
      readOnly: isDate,
      validator: validator,
    ),
  );
}






  
  String? validateContactNumber(String? value) {
  if (value == null || value.isEmpty) {
    return 'Contact number cannot be empty';
  }
  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
    return 'Only numbers are allowed';
  }
  if (value.length < 11) {
    return 'Contact number must be at least 11 digits';
  }
  return null;
}


  Widget _buildProfileDataField(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildHeader(Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${user['firstName']} ${user['lastName']}", 
             style: GoogleFonts.lato(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
        Text(user['email'], style: GoogleFonts.lato(color: HexColor.fromHex("#ffb3ff"), fontSize: 17)),
        SizedBox(height: 20),
      ],
    );
  }
  @override
  void dispose() {
    usernameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    dobController.dispose();
    contactNumberController.dispose();
    super.dispose();
  }
}

  

// Add other necessary classes (e.g., LoginSession) or imports as needed based on your project structure.
