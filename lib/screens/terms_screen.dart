import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: January 2025\n\n'
              'By using this app you agree to these terms.\n\n'
              'Free Tier: 5 AI requests per day. '
              'Premium Tier: Unlimited requests, billed monthly.\n\n'
              'Subscriptions automatically renew unless cancelled at least 24 hours '
              'before the end of the current period. Manage subscriptions in your '
              'App Store or Google Play account settings.\n\n'
              'No refunds except as required by law. '
              'We reserve the right to suspend accounts that violate these terms.\n\n'
              'Contact: support@yourapp.com',
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
