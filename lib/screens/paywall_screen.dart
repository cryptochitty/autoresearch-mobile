import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _subscriptionService = SubscriptionService();
  bool _loading = false;
  String? _error;

  Future<void> _purchase() async {
    setState(() { _loading = true; _error = null; });
    try {
      final success = await _subscriptionService.purchasePremium();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to AutoResearch Pro!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() { _loading = true; _error = null; });
    try {
      final restored = await _subscriptionService.restorePurchases(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restored ? 'Subscription restored!' : 'No active subscription found.',
            ),
          ),
        );
        if (restored) Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoResearch Pro'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.science, size: 80, color: Color(0xFF6C63FF)),
            const SizedBox(height: 24),
            const Text(
              'AutoResearch Pro',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Download & save research papers every day',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Free vs Pro comparison
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _planRow('Free', 'View 1 paper/day', false),
                  Divider(height: 1, color: Colors.grey.shade300),
                  _planRow('Pro ₹499/mo', 'Download 3 papers/month', true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ...[
              ('Download papers as PDF', Icons.download),
              ('3 downloads per month', Icons.file_download),
              ('Full paper content', Icons.article),
              ('Priority AI analysis', Icons.psychology),
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(item.$2, color: const Color(0xFF6C63FF)),
                    const SizedBox(width: 12),
                    Text(item.$1, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),

            const Spacer(),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            FilledButton(
              onPressed: _loading ? null : _purchase,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF6C63FF),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Subscribe ₹499 / month',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: _loading ? null : _restore,
              child: const Text('Restore Purchases'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cancel anytime. Billed monthly in INR.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _planRow(String plan, String benefit, bool isPro) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            isPro ? Icons.star : Icons.star_border,
            color: isPro ? const Color(0xFF6C63FF) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(benefit, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
