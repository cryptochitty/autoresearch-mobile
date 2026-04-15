import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: January 2025\n\n'
              'We collect your email address to create your account. '
              'We store your usage data (requests per day) in Firebase Firestore. '
              'We do not sell your data to third parties.\n\n'
              'Subscription payments are processed by the App Store or Google Play. '
              'We do not store payment information.\n\n'
              'Your AI queries may be processed by third-party AI providers. '
              'Do not share sensitive personal information in your queries.\n\n'
              'Contact: support@yourapp.com',
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
