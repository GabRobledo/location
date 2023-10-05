import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  // final String termsAndConditionsText;

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
                'Frequently Asked Questions (FAQs)',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              FaqItem(
                question: 'How do I create an account?',
                answer:
                    'To create an account, click on the "Sign Up" button on the login page and provide the required information.',
              ),
              FaqItem(
                question: 'How can I reset my password?',
                answer:
                    'If you\'ve forgotten your password, you can click on the "Forgot Password" link on the login page to reset it.',
              ),
              FaqItem(
                question: 'How do I contact customer support?',
                answer:
                    'You can reach our customer support team by sending an email to support@example.com or by calling our toll-free number at 1-800-123-4567.',
              ),
              FaqItem(
                question: 'What are the supported payment methods?',
                answer:
                    'We accept payments via credit/debit cards, PayPal, and in-app wallet.',
              ),
              FaqItem(
                question: 'Is my personal information secure?',
                answer:
                    'Yes, we take the security of your personal information seriously. We use industry-standard encryption to protect your data.',
              ),
              FaqItem(
                question: 'How do I report a problem with the app?',
                answer:
                    'If you encounter any issues or have suggestions for improvements, please use the in-app feedback feature or contact our support team.',
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
                title: Text('Email: support@example.com'),
              ),
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Phone: 1-800-123-4567'),
              ),
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text('Address: 123 Main Street, City, Country'),
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
