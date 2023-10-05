import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help Center'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              buildFAQ('How do I create an account?',
                  'To create an account, click on the "Sign Up" button on the login page and provide the required information.'),
              buildFAQ('How can I reset my password?',
                  'If you\'ve forgotten your password, you can click on the "Forgot Password" link on the login page to reset it.'),
              buildFAQ('How do I contact customer support?',
                  'You can reach our customer support team by sending an email to support@example.com or by calling our toll-free number at 1-800-123-4567.'),
              buildFAQ('What are the supported payment methods?',
                  'We accept payments via credit/debit cards, PayPal, and in-app wallet.'),
              buildFAQ('Is my personal information secure?',
                  'Yes, we take the security of your personal information seriously. We use industry-standard encryption to protect your data.'),
              buildFAQ('How do I report a problem with the app?',
                  'If you encounter any issues or have suggestions for improvements, please use the in-app feedback feature or contact our support team.'),
              SizedBox(height: 24),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Email: support@example.com\nPhone: 1-800-123-4567\nAddress: 123 Main Street, City, Country',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFAQ(String question, String answer) {
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
