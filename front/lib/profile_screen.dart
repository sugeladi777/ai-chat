import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final Function(String) onAvatarChanged;

  const ProfileScreen({
    super.key,
    this.userId,
    required this.onAvatarChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _userId;
  String? _avatarUrl;
  String? _nickname;
  bool _isLoading = false;

  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userId = widget.userId ?? '未知用户';
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getUserProfile(_userId);
      setState(() {
        _avatarUrl = profile['avatarUrl'];
        _nickname = profile['nickname'];
        _nicknameController.text = _nickname ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取用户资料失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final newAvatarUrl = await ApiService.uploadUserAvatar(_userId, File(pickedFile.path));
        setState(() => _avatarUrl = newAvatarUrl);
        widget.onAvatarChanged(newAvatarUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像已更新')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传头像失败: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateNickname() async {
    final newNickname = _nicknameController.text;
    if (newNickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('昵称不能为空')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.updateNickname(_userId, newNickname);
      setState(() => _nickname = newNickname);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('昵称已更新')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新昵称失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB6C1), // 浅粉色标题栏
        title: const Text(
          '个人中心',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'CuteFont', // 使用可爱的字体
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 用户头像
                      GestureDetector(
                        onTap: _changeAvatar,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
                          backgroundColor: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.pinkAccent,
                                width: 4,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 用户昵称
                      TextField(
                        controller: _nicknameController,
                        decoration: InputDecoration(
                          labelText: '昵称',
                          labelStyle: const TextStyle(
                            color: Color(0xFFFF69B4),
                            fontFamily: 'CuteFont',
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFFE4E1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.person, color: Color(0xFFFF69B4)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF69B4),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          shadowColor: Colors.pinkAccent,
                          elevation: 10,
                        ),
                        onPressed: _updateNickname,
                        child: const Text(
                          '更新昵称',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'CuteFont'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF69B4),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          shadowColor: Colors.pinkAccent,
                          elevation: 10,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '返回',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'CuteFont'),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}