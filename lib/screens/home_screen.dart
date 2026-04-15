import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_service.dart';
import '../services/usage_service.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart';
import '../models/user_usage.dart';
import '../widgets/response_card.dart';
import 'paywall_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _promptController = TextEditingController();
  final _aiService = AiService();
  final _usageService = UsageService();
  final _subscriptionService = SubscriptionService();
  final _authService = AuthService();

  UserUsage? _usage;
  String? _response;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Sync premium status from RevenueCat
    await _subscriptionService.checkPremiumStatus(user.uid);

    final usage = await _usageService.getUsage(user.uid);
    setState(() => _usage = usage);
  }

  Future<void> _ask() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _usage == null) return;

    if (!_usage!.canMakeRequest) {
      _showPaywall();
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() { _loading = true; _error = null; _response = null; });

    try {
      final response = await _aiService.ask(
        prompt: prompt,
        isPremium: _usage!.isPremium,
        userId: user.uid,
      );
      await _usageService.incrementUsage(user.uid);
      await _loadUsage();
      setState(() => _response = response);
      _promptController.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showPaywall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    ).then((_) => _loadUsage());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoResearch'),
        actions: [
          if (_usage?.isPremium == true)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Chip(label: Text('PRO')),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _authService.signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Usage bar
            if (_usage != null && !_usage!.isPremium)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt),
                      const SizedBox(width: 8),
                      Text(
                        '${_usage!.remainingFreeRequests} free requests left today',
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _showPaywall,
                        child: const Text('Upgrade'),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Response area
            Expanded(
              child: _response != null
                  ? ResponseCard(text: _response!)
                  : const Center(
                      child: Text('Ask me anything...'),
                    ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 8),

            // Input area
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _ask(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _ask,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
