import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _baseUrl = 'https://autoresearch-4l69.onrender.com';

  // Stream real-time research progress events
  Stream<Map<String, dynamic>> streamResearch(String topic) async* {
    final startResponse = await http.post(
      Uri.parse('$_baseUrl/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'topic': topic}),
    );

    if (startResponse.statusCode != 200) {
      throw Exception('Failed to start research');
    }

    final sessionId = jsonDecode(startResponse.body)['session_id'];
    final client = http.Client();

    try {
      final request = http.Request('GET', Uri.parse('$_baseUrl/stream/$sessionId'));
      final streamedResponse = await client.send(request);

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty) continue;
            try {
              final event = jsonDecode(jsonStr) as Map<String, dynamic>;
              yield event;
              if (event['type'] == 'complete' || event['type'] == 'error') break;
            } catch (_) {}
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // Simple Q&A for free tier
  Future<String> ask({
    required String prompt,
    required bool isPremium,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/ai/ask'),
      headers: {
        'Content-Type': 'application/json',
        'X-User-ID': userId,
      },
      body: jsonEncode({
        'prompt': prompt,
        'tier': isPremium ? 'premium' : 'free',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] as String;
    } else {
      throw Exception('Request failed: ${response.statusCode}');
    }
  }
}
