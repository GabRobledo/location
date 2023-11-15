import 'package:flutter/material.dart';
import '../main.dart';
import 'package:flutter_dropdown/flutter_dropdown.dart';
// import '../home_page.dart';
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
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool isLoading = false;
  bool isUserRegistered = false;
 

  void register() async {
    if (_formKey.currentState!.validate()) {
    // If the form passes validation, then proceed with the registration logic
    setState(() => isLoading = true);
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
        //  uploadPhoto.isEmpty ||
        // homeAddress.isEmpty ||
        // emailVerification.isEmpty ||
        // mobileNumberVerification.isEmpty ||
        role.isEmpty
        ) {
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
  } else {
    // If the form doesn't pass validation, enable auto-validation to give feedback to the user
    setState(() => _autoValidate = true);
  }
}
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty || !RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty || !RegExp(r'^\+?(\d.*){3,}$').hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  Widget _buildCustomTextField(TextEditingController controller, String label, bool isPassword, String? Function(String?) validator, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
        ),
        obscureText: isPassword,
        validator: validator,
      ),
    );
  }
  Widget _buildRoleDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: selectedRole.isEmpty ? null : selectedRole,
        decoration: InputDecoration(
          labelText: 'Role',
          border: OutlineInputBorder(),
        ),
        items: <String>['Driver', 'Mechanic'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            selectedRole = newValue!;
            selectedVehicleTypes.clear();
          });
        },
        validator: (value) => value == null ? 'Please select a role' : null,
      ),
    );
  }

  Widget _buildVehicleTypeCheckboxes() {
    return Column(
      children: <String>['Automotive', 'Motorcycle', 'Bicycle'].map((String vehicleType) {
        return CheckboxListTile(
          title: Text(vehicleType),
          value: selectedVehicleTypes.contains(vehicleType),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                selectedVehicleTypes.add(vehicleType);
              } else {
                selectedVehicleTypes.remove(vehicleType);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildRegisterButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: isLoading ? null : register,
        child: isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text('Register'),
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCustomTextField(emailController, 'Email', false, _validateEmail, Icons.email),
                _buildCustomTextField(firstNameController, 'First Name', false, _validateName, Icons.person),
                _buildCustomTextField(lastNameController, 'Last Name', false, _validateName, Icons.person_outline),
                _buildCustomTextField(phoneNumberController, 'Phone Number', false, _validatePhoneNumber, Icons.phone),
                _buildCustomTextField(passwordController, 'Password', true, _validatePassword, Icons.lock),
                _buildRoleDropdown(),
                if (selectedRole == "Mechanic") _buildVehicleTypeCheckboxes(),
                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
    
    
  }
  }

