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
  bool _canDownload = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _subscriptionService.checkPremiumStatus(user.uid);
    final usage = await _usageService.getUsage(user.uid);
    setState(() => _usage = usage);
  }

  Future<void> _search() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _usage == null) return;

    if (!_usage!.canViewPaper) {
      _showPaywall();
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() { _loading = true; _error = null; _response = null; _canDownload = false; });

    try {
      final response = await _aiService.ask(
        prompt: prompt,
        isPremium: _usage!.isPremium,
        userId: user.uid,
      );
      await _usageService.incrementViewed(user.uid);
      await _loadUsage();
      setState(() {
        _response = response;
        _canDownload = _usage!.canDownloadPaper;
      });
      _promptController.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _usage == null || _response == null) return;

    if (!_usage!.canDownloadPaper) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download limit reached (3/day). Try again tomorrow.')),
      );
      return;
    }

    await _usageService.incrementDownloaded(user.uid);
    await _loadUsage();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloaded! ${_usage!.remainingDownloads} downloads remaining this month.')),
    );
  }

  void _showPaywall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    ).then((_) => _loadUsage());
  }

  @override
  Widget build(BuildContext context) {
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
            // Usage banner
            if (_usage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.article),
                      const SizedBox(width: 8),
                      _usage!.isPremium
                          ? Text('${_usage!.remainingDownloads} downloads left this month')
                          : Text(
                              _usage!.papersViewed < UserUsage.freeViewLimit
                                  ? '1 free paper available'
                                  : 'Free limit reached',
                            ),
                      const Spacer(),
                      if (!_usage!.isPremium)
                        TextButton(
                          onPressed: _showPaywall,
                          child: const Text('Upgrade ₹499/mo'),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Expanded(
              child: _response != null
                  ? ResponseCard(
                      text: _response!,
                      canDownload: _canDownload,
                      onDownload: _download,
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Search for research papers'),
                          SizedBox(height: 8),
                          Text(
                            'Free: View 1 paper/day\nPro ₹499/mo: Download 3 papers/day',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: 'Search research topic...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
