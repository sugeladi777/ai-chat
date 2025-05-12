import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
  static const String _apiBaseUrl = 'http://1.92.96.135:8000/api/v1';

  // 创建对话，返回对话 ID
  static Future<int> createChat() async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/chats/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['id']; // 返回对话 ID
    } else {
      throw Exception('Failed to create chat');
    }
  }

  // 获取所有对话
  static Future<List<Map<String, dynamic>>> fetchChats() async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/chats/'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch chats');
    }
  }

  // 删除指定对话
  static Future<void> deleteChat(int chatId) async {
    final response = await http.delete(
      Uri.parse('$_apiBaseUrl/chats/$chatId'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete chat');
    }
  }

  // 与模型对话
  static Future<Map<String, dynamic>> sendMessage(
    int chatId,
    String message,
  ) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/chats/$chatId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'message': message}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body); // 返回模型的回复
    } else {
      throw Exception('Failed to send message');
    }
  }

  // 更新对话标题
  static Future<void> updateChatTitle(int chatId, String title) async {
    final response = await http.put(
      Uri.parse('$_apiBaseUrl/chats/$chatId/title'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': title}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update chat title');
    }
  }

  // 根据用户获取所有历史对话
  static Future<List<Map<String, dynamic>>> fetchUserChats(String userId) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/chats/$userId/title'),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch user chats');
    }
  }

  // 模拟登录接口
  static Future<int> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('http://1.92.96.135:8000/api/v1/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['chatId']; // 假设登录成功返回 chatId
    } else {
      throw Exception('登录失败');
    }
  }

  // 注册接口
  static Future<void> register(String username, String password, String nickname) async {
    final response = await http.post(
      Uri.parse('http://1.92.96.135:8000/api/v1/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password,'nickname': nickname}),
    );
    if (response.statusCode != 201) {
      throw Exception('注册失败');
    }
  }

  // 获取用户头像
  static Future<String> getUserAvatar(String userId) async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/users/$userId/avatar'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['avatarUrl']; // 返回头像 URL
    } else {
      throw Exception('Failed to fetch user avatar');
    }
  }

  // 上传用户头像
  static Future<String> uploadUserAvatar(String userId, File avatarFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_apiBaseUrl/users/$userId/avatar'),
    );
    request.files.add(await http.MultipartFile.fromPath('avatar', avatarFile.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      return data['avatarUrl']; // 返回新的头像 URL
    } else {
      throw Exception('Failed to upload user avatar');
    }
  }

  // 获取用户资料
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/users/$userId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user profile');
    }
  }

  // 更新用户昵称
  static Future<void> updateNickname(String userId, String nickname) async {
    final response = await http.put(
      Uri.parse('$_apiBaseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'nickname': nickname}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update nickname');
    }
  }
}
