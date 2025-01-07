import 'package:http/http.dart' as http;
import 'dart:convert';

class GeminiChatbotService {
  final String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
  final String apiKey = 'Enter your api key here';

  Stream<String> sendMessage(String message) async* {
    final response = await http.post(
      Uri.parse('$apiUrl?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': message}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Response Data: $responseData'); // Log the full response data
      if (responseData != null &&
          responseData['candidates'] != null &&
          responseData['candidates'].isNotEmpty) {
        for (var part in responseData['candidates'][0]['content']['parts']) {
          yield part[
              'text']; // Adjust based on the actual API response structure
        }
      } else {
        yield 'Error: Unexpected response structure. Full response: $responseData';
      }
    } else {
      yield 'Error: Failed to load response from Gemini API';
    }
  }
}
