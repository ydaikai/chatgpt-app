import 'dart:convert';
import 'package:http/http.dart' as http;

class APIClient {
  final String apiKey;

  APIClient({required this.apiKey});

  Future<String> generateResponse(List<Map<String, dynamic>> messages) async {
    final apiUrl = "https://api.openai.com/v1/chat/completions";

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({'model': 'gpt-3.5-turbo', 'messages': messages});

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final jsonResponseByte = utf8.decode(response.bodyBytes);
      final assistantMessage = jsonResponse['choices'][0]['message']['content'];
      return assistantMessage;
    } else {
      print('Failed to get a response from the API: ${response.statusCode}');
      return 'Sorry, I could not get a response from the API.';
    }
  }
}
