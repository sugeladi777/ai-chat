import 'package:flutter/material.dart';
import 'api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController(); // 新增昵称输入框
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final nickname = _nicknameController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户名、邮箱、密码和昵称不能为空')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.register(username, email, password, nickname); // 调用注册接口，传递昵称
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册成功，请登录')),
      );
      Navigator.pop(context); // 返回登录界面
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('注册失败: $e')),
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
                  backgroundImage: const AssetImage('assets/images/anime_girl_register.jpg'),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(height: 16),
                const Text(
                  '创建你的少女AI账号',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF69B4), // 热粉色
                    fontFamily: 'CuteFont', // 可选：使用二次元风格字体
                  ),
                ),
                const SizedBox(height: 32),
                // 昵称输入框
                TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: '昵称',
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
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFF69B4)),
                  ),
                ),
                const SizedBox(height: 16),
                // 邮箱输入框
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: '邮箱',
                    labelStyle: const TextStyle(color: Color(0xFFFF69B4)),
                    filled: true,
                    fillColor: const Color(0xFFFFE4E1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email, color: Color(0xFFFF69B4)),
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
                // 注册按钮
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
                        onPressed: _register,
                        child: const Text(
                          '注册',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                // 返回登录按钮
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 返回登录界面
                  },
                  child: const Text(
                    '已有账号？点击登录',
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