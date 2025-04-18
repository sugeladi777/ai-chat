import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _apiBaseUrl = 'http://your-backend-api.com';

  static Future<List<Map<String, dynamic>>> fetchConversations() async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/conversations'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load conversations');
    }
  }

  static Future<void> saveConversation(
    List<Map<String, String>> messages,
  ) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/conversations'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'messages': messages}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to save conversation');
    }
  }

  static Future<List<Map<String, String>>> loadConversation(int id) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/conversations/$id'),
    );
    if (response.statusCode == 200) {
      final conversation = json.decode(response.body);
      return List<Map<String, String>>.from(conversation['messages']);
    } else {
      throw Exception('Failed to load conversation');
    }
  }
}
