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

  // Real-time research tracking
  int _currentAgent = 0;
  String _agentStatus = '';
  final List<String> _agentNames = [
    'Discovery', 'Reader', 'Innovation', 'Validation',
    'Writer', 'Builder', 'Evaluation', 'Explainer',
  ];

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

    final topic = _promptController.text.trim();
    if (topic.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _response = null;
      _canDownload = false;
      _currentAgent = 0;
      _agentStatus = 'Starting research...';
    });

    try {
      if (_usage!.isPremium) {
        // Premium: use full real-time 8-agent pipeline
        await for (final event in _aiService.streamResearch(topic)) {
          if (!mounted) break;

          final type = event['type'] as String? ?? '';

          if (type == 'agent_start') {
            setState(() {
              _currentAgent = (event['agent_index'] as int? ?? 0);
              _agentStatus = '${_agentNames[_currentAgent]} Agent working...';
            });
          } else if (type == 'complete') {
            final sections = event['sections'] as Map<String, dynamic>? ?? {};
            final result = sections.values
                .where((v) => v != null && v.toString().isNotEmpty)
                .join('\n\n---\n\n');
            setState(() {
              _response = result.isNotEmpty ? result : event['summary']?.toString() ?? 'Research complete.';
              _agentStatus = 'Research complete!';
            });
          } else if (type == 'error') {
            setState(() => _error = event['message']?.toString() ?? 'Research failed.');
          }
        }
      } else {
        // Free: simple single-paper summary
        setState(() => _agentStatus = 'Searching...');
        final response = await _aiService.ask(
          prompt: 'Find and summarize one research paper about: $topic',
          isPremium: false,
          userId: user.uid,
        );
        setState(() => _response = response);
      }

      await _usageService.incrementViewed(user.uid);
      await _loadUsage();
      setState(() => _canDownload = _usage!.canDownloadPaper);
      _promptController.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() { _loading = false; _agentStatus = ''; });
    }
  }

  Future<void> _download() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _usage == null || _response == null) return;

    if (!_usage!.canDownloadPaper) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download limit reached (3/month).')),
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
                                  ? '1 free paper available today'
                                  : 'Free limit reached today',
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

            // Agent progress (premium only)
            if (_loading && _usage?.isPremium == true)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_agentStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _agentNames.isEmpty ? 0 : (_currentAgent + 1) / _agentNames.length,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: _agentNames.asMap().entries.map((e) {
                          final done = e.key < _currentAgent;
                          final active = e.key == _currentAgent;
                          return Chip(
                            label: Text(e.value, style: const TextStyle(fontSize: 11)),
                            backgroundColor: done
                                ? Colors.green.withOpacity(0.3)
                                : active
                                    ? const Color(0xFF6C63FF).withOpacity(0.3)
                                    : null,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: _response != null
                  ? ResponseCard(
                      text: _response!,
                      canDownload: _canDownload,
                      onDownload: _download,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.science, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Search for research papers'),
                          const SizedBox(height: 8),
                          Text(
                            _usage?.isPremium == true
                                ? 'Pro: Full 8-agent analysis + 3 downloads/month'
                                : 'Free: View 1 paper/day\nPro ₹499/mo: Full research pipeline',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                      hintText: 'Enter research topic...',
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
