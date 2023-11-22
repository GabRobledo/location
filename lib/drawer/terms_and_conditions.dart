import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms and Conditions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'By accessing our app, you agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, you must not use our app.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              FaqItem(
                question: 'How do I create an account?',
                answer:
                    'To create an account, click on the "Sign Up" button on the login page and provide the required information.',
              ),
              FaqItem(
                question: 'How can I contact customer support?',
                answer:
                    'You can reach our customer support team by sending an email to raambservice@gmail.com.',
              ),
              FaqItem(
                question: 'What are the supported payment methods?',
                answer:
                    'We accept payments via cash on delivery, GCash, and Maya.',
              ),
              FaqItem(
                question: 'Is my personal information secure?',
                answer:
                    'Yes, we take the security of your personal information seriously. We use industry-standard encryption to protect your data.',
              ),
              FaqItem(
                question: 'How do I report a problem with the app?',
                answer:
                    'If you encounter any issues or have suggestions for improvements, please contact our support team via email at raambservice@gmail.com.',
              ),
              SizedBox(height: 16),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ListTile(
                leading: Icon(Icons.email),
                title: Text('Email: raambservice@gmail.com'),
              ),
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Phone: 092764321'),
              ),
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text('Address: La Paz, Iloilo City, Philippines 5000'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          answer,
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
