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
          const SnackBar(content: Text('Welcome to Premium!')),
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
              restored ? 'Premium restored!' : 'No active subscription found.',
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
            const Icon(Icons.auto_awesome, size: 80, color: Color(0xFF6C63FF)),
            const SizedBox(height: 24),
            const Text(
              'Unlock AutoResearch Pro',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Get unlimited AI research every day',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Feature list
            ...[
              ('Unlimited AI requests', Icons.all_inclusive),
              ('Priority responses', Icons.speed),
              ('Advanced AI models', Icons.psychology),
              ('No daily limits', Icons.lock_open),
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
                      'Subscribe \$4.99 / month',
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
              'Cancel anytime. Billed monthly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
