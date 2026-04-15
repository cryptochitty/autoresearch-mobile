import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // Replace with your Render backend URL
  static const String _baseUrl = 'https://autoresearch-4l69.onrender.com';

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
    } else if (response.statusCode == 429) {
      throw Exception('Daily limit reached. Upgrade to Premium for unlimited access.');
    } else {
      throw Exception('AI request failed: ${response.statusCode}');
    }
  }
}
