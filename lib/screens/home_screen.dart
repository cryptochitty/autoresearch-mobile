import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/usage_service.dart';
import '../models/user_usage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'paywall_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _subscriptionService = SubscriptionService();
  final _usageService = UsageService();

  WebViewController? _webController;
  UserUsage? _usage;
  bool _pageLoading = true;

  static const String _appUrl = 'https://autoresearch-4l69.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadUsage();
    if (!kIsWeb) _initWebView();
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _pageLoading = true),
          onPageFinished: (_) => setState(() => _pageLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(_appUrl));
  }

  Future<void> _loadUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _subscriptionService.checkPremiumStatus(user.uid);
    final usage = await _usageService.getUsage(user.uid);
    setState(() => _usage = usage);
  }

  void _showPaywall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    ).then((_) => _loadUsage());
  }

  @override
  Widget build(BuildContext context) {
    // On web — redirect to the actual site
    if (kIsWeb) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.science, size: 80, color: Color(0xFF6C63FF)),
              const SizedBox(height: 24),
              const Text(
                'AutoResearch',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open AutoResearch'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              if (_usage != null && !_usage!.isPremium)
                TextButton(
                  onPressed: _showPaywall,
                  child: const Text('Upgrade to Pro ₹499/mo'),
                ),
            ],
          ),
        ),
      );
    }

    // On mobile — show full WebView
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          WebViewWidget(controller: _webController!),
          if (_pageLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('AutoResearch'),
      actions: [
        if (_usage?.isPremium == true)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Chip(label: Text('PRO')),
          ),
        if (_usage != null && !_usage!.isPremium)
          TextButton(
            onPressed: _showPaywall,
            child: const Text('₹499/mo'),
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _authService.signOut,
        ),
      ],
    );
  }
}
