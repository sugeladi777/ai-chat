import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'api_service.dart';
import 'register_screen.dart'; // 导入注册界面

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户名和密码不能为空')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chatId = await ApiService.login(username, password); // 假设 API 返回 chatId
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(initialChatId: chatId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // 浅粉色背景
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 二次元少女头像
                CircleAvatar(
                  radius: 60,
                  backgroundImage: const AssetImage('assets/images/anime_girl.jpg'),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(height: 16),
                const Text(
                  '欢迎来到少女AI世界',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF69B4), // 热粉色
                    fontFamily: 'CuteFont', // 可选：使用二次元风格字体
                  ),
                ),
                const SizedBox(height: 32),
                // 用户名输入框
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    labelStyle: const TextStyle(color: Color(0xFFFF69B4)),
                    filled: true,
                    fillColor: const Color(0xFFFFE4E1), // 浅粉色输入框
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: Color(0xFFFF69B4)),
                  ),
                ),
                const SizedBox(height: 16),
                // 密码输入框
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '密码',
                    labelStyle: const TextStyle(color: Color(0xFFFF69B4)),
                    filled: true,
                    fillColor: const Color(0xFFFFE4E1), // 浅粉色输入框
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF69B4)),
                  ),
                ),
                const SizedBox(height: 32),
                // 登录按钮
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF69B4), // 热粉色按钮
                          padding: const EdgeInsets.symmetric(
                            horizontal: 64,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          shadowColor: const Color(0xFFFFB6C1), // 按钮阴影
                          elevation: 10,
                        ),
                        onPressed: _login,
                        child: const Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                // 注册按钮
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '没有账号？点击注册',
                    style: TextStyle(
                      color: Color(0xFFB22222), // 深粉红色
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}