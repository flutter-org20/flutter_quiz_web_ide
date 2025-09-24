import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';

class PollinationsServices {
  static const String baseUrl = 'https://text.pollinations.ai';

  static Future<PollinationsResponse> generateText(String prompt) async {
    if (prompt.trim().isEmpty) {
      return PollinationsResponse.error('Prompt cannot be empty');
    }
    try {
      final encodedPrompt = Uri.encodeComponent(prompt);
      final url = Uri.parse('$baseUrl/generate?prompt=$encodedPrompt');

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'Flutter-Web-App',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PollinationsResponse.fromJson(data);
      } else {
        return PollinationsResponse.error(
          'API Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return PollinationsResponse.error('Network Error: ${e.toString()}');
    }
  }
}
