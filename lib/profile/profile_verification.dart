import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerificationPage extends StatefulWidget {
  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController emailController = TextEditingController();
  String emailError = '';

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> submitVerification() async {
    if (emailController.text.isNotEmpty && isValidEmail(emailController.text)) {
      setState(() {
        emailError = '';
      });

      var data = {
        'email': emailController.text,
        // Add other fields if needed
      };

      var response = await http.post(
        Uri.parse('https://63a5-2001-4454-415-8a00-d420-28e1-55cb-d200.ngrok-free.app/submitVerification'), // Replace with your server's address
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        // Handle successful response
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Verification submitted successfully!"),
        ));
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to submit verification."),
        ));
      }
    } else {
      setState(() {
        emailError = 'Invalid email';
      });
    }
  }

  bool isValidEmail(String value) {
    // Implement your email validation logic here
    return true; // Dummy implementation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // UI elements for email input
            _buildTextField('Enter Email', 'Email', TextInputType.emailAddress),

            Spacer(),
            ElevatedButton(
              onPressed: submitVerification,
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
                minimumSize: Size(double.infinity, 50.0),
              ),
              child: Text('Submit Verification', style: TextStyle(fontSize: 20.0)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, String hintText, TextInputType keyboardType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
        TextField(
          controller: emailController,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: emailError.isEmpty ? null : emailError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
