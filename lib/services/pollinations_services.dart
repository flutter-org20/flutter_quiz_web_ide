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
      final url = Uri.parse('$baseUrl/$encodedPrompt');

      final response = await http
          .get(
            url,
            headers: {'Accept': 'text/plain', 'User-Agent': 'Flutter-Web-App'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Pollinations API returns plain text, not JSON
        final responseText = response.body.trim();
        if (responseText.isNotEmpty) {
          return PollinationsResponse(text: responseText);
        } else {
          return PollinationsResponse.error('Empty response from API');
        }
      } else {
        return PollinationsResponse.error(
          'API Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return PollinationsResponse.error('Network Error: ${e.toString()}');
    }
  }

  /// Generate multiple different code samples for the same prompt
  /// Each sample will have slight variations to ensure diversity
  static Future<List<PollinationsResponse>> generateMultipleSamples({
    required String prompt,
    int count = 4,
  }) async {
    if (prompt.trim().isEmpty) {
      return [PollinationsResponse.error('Prompt cannot be empty')];
    }

    final List<Future<PollinationsResponse>> futures = [];
    final variations = _createPromptVariations(prompt, count);

    for (int i = 0; i < count; i++) {
      final variationPrompt = variations[i];
      futures.add(generateText(variationPrompt));

      // Add small delay between requests to avoid overwhelming the API
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    try {
      final results = await Future.wait(futures);
      return results;
    } catch (e) {
      // If batch request fails, return error responses
      return List.generate(
        count,
        (_) =>
            PollinationsResponse.error('Batch request failed: ${e.toString()}'),
      );
    }
  }

  /// Create variations of the same prompt to get diverse responses
  static List<String> _createPromptVariations(String basePrompt, int count) {
    final variations = <String>[];

    // Add the original prompt
    variations.add(
      'Using $basePrompt, generate a Python program, Keep the code simple, under 30 lines, without functions or classes, and return only raw Python code. Do not add anything else just give me the code. do not use markdown/backticks',
    );

    if (count > 1) {
      // Add variations with different approaches
      variations.add(
        'Write Python code demonstrating $basePrompt. The program should be different from standard loops, simple, under 30 lines, and no markdown or comments. Do not add anything else just give me the code,do not use markdown/backticks.',
      );
    }

    if (count > 2) {
      // Add variation asking for alternative implementation
      variations.add(
        'Generate a Python script for $basePrompt. Avoid functions or classes, do not use markdown/backticks, and keep code under 30 lines.Do not add anything else just give me the code',
      );
    }

    if (count > 3) {
      // Add variation asking for optimized version
      variations.add(
        'Provide a Python program using $basePrompt . Keep it beginner-friendly, under 30 lines, and output only plain Python code.Do not add anything else just give me the code, do not use markdown/backticks.',
      );
    }

    if (count > 4) {
      // Add variations with more specific requests
      final additionalVariations = [
        'Produce a Python snippet demonstrating $basePrompt in a different way from previous examples,. Keep the code short but medium-level, under 30 lines, with no comments or markdown. Do not add anything else just give me the code',
        '$basePrompt. Include error handling.',
        '$basePrompt. Add detailed comments.',
        '$basePrompt. Use a different Python library or approach.',
        '$basePrompt. Make it more beginner-friendly.',
      ];

      for (int i = 4; i < count && i - 4 < additionalVariations.length; i++) {
        variations.add(additionalVariations[i - 4]);
      }
    }

    // Fill remaining slots with the original prompt if needed
    while (variations.length < count) {
      variations.add('$basePrompt. Version ${variations.length + 1}.');
    }

    return variations.take(count).toList();
  }
}
