import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _apiBaseUrl = 'http://1.92.96.135:8000/api/v1';

  String? _accessToken;

  ApiService([this._accessToken]);

  void setAccessToken(String token) {
    _accessToken = token;
  }

  Map<String, String> _headers({bool withAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  static Future<void> register(
    String username,
    String email,
    String password,
    String nickname,
  ) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'nickname': nickname,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('注册失败: ${response.body}');
    }
  }

  static Future<ApiService> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ApiService(data['access_token']);
    } else {
      throw Exception('登录失败: ${response.body}');
    }
  }

  // 获取当前用户信息
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/auth/me'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('获取用户信息失败: ${response.body}');
    }
  }

  // 获取用户历史对话
  Future<Map<String, dynamic>> fetchUserHistory() async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/history/user'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('获取历史对话失败: ${response.body}');
    }
  }

  // 创建新对话
  Future<Map<String, dynamic>> createChat({
    required String title,
    required String modelId,
    required String initialMessage,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/chats/'),
      headers: _headers(withAuth: true),
      body: json.encode({
        'title': title,
        'model_id': modelId,
        'initial_message': initialMessage,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('创建对话失败: ${response.body}');
    }
  }

  Future<String?> getUserAvatar() async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/auth/avatar'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['avatar_url'] as String?;
    } else {
      throw Exception('获取用户头像失败: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String chatId, String message) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/chats/$chatId/messages'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      },
      body: 'content=${Uri.encodeComponent(message)}',
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('发送消息失败: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchChatDetail(String chatId) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/chats/$chatId'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('获取对话详情失败: ${response.body}');
    }
  }

  Future<void> deleteChat(String chatId) async {
    final response = await http.delete(
      Uri.parse('$_apiBaseUrl/chats/$chatId'),
      headers: _headers(withAuth: true),
    );
    if (response.statusCode != 200) {
      throw Exception('删除对话失败: ${response.body}');
    }
  }

  Future<void> uploadUserAvatar(String filePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_apiBaseUrl/auth/avatar'),
    );
    request.headers.addAll(_headers(withAuth: true));
    request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw Exception('上传头像失败: ${response.body}');
    }
  }

  Future<void> updateNickname(String nickname) async {
    final response = await http.patch(
      Uri.parse('$_apiBaseUrl/auth/nickname'),
      headers: _headers(withAuth: true),
      body: json.encode({'nickname': nickname}),
    );
    if (response.statusCode != 200) {
      throw Exception('更改昵称失败: ${response.body}');
    }
  }

  Future<void> setChatTitle(String chatId, String title, {String autoGenerate = 'false'}) async {
    final Map<String, String> body = {
      'auto_generate': autoGenerate,
    };
    if (title.isNotEmpty) {
      body['title'] = title;
    } else {
      body['title'] = '';
    }
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
    final response = await http.put(
      Uri.parse('$_apiBaseUrl/chats/$chatId/title'),
      headers: headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('设置对话标题失败: ${response.body}');
    }
  }
}
