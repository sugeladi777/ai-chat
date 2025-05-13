import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final Function(String) onAvatarChanged;
  final ApiService apiService;

  const ProfileScreen({
    super.key,
    this.userId,
    required this.onAvatarChanged,
    required this.apiService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _avatarUrl;
  String? _nickname;
  String? _username;
  String? _email;
  String? _userId;
  String? _createdAt;
  bool _isLoading = false;

  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService;
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.getCurrentUser();
      setState(() {
        _avatarUrl = profile['avatar_url'];
        _nickname = profile['nickname'];
        _username = profile['username'];
        _email = profile['email'];
        _userId = profile['_id']?.toString() ?? '';
        _createdAt = profile['created_at']?.toString().substring(0, 10) ?? '';
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
        await _apiService.uploadUserAvatar(pickedFile.path);
        final profile = await _apiService.getCurrentUser();
        setState(() => _avatarUrl = profile['avatar_url']);
        widget.onAvatarChanged(_avatarUrl ?? '');
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

  Future<void> _showEditNicknameDialog() async {
    final controller = TextEditingController(text: _nickname ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入新昵称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != _nickname) {
      await _updateNickname(result);
    }
  }

  Future<void> _updateNickname(String newNickname) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateNickname(newNickname);
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

  Widget _buildInfoRow(String label, String value, {IconData? icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            if (icon != null) Icon(icon, color: Color(0xFFFF69B4), size: 20),
            if (icon != null) const SizedBox(width: 6),
            Text(
              '$label：',
              style: const TextStyle(
                color: Color(0xFFFF69B4),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              const Icon(Icons.edit, size: 18, color: Color(0xFFFF69B4)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB6C1),
        title: const Text(
          '个人中心',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'CuteFont',
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 用户头像
                      GestureDetector(
                        onTap: _changeAvatar,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
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
                      // 用户基本信息
                      Card(
                        color: const Color(0xFFFFE4E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildInfoRow('UID', _userId ?? '', icon: Icons.perm_identity),
                              _buildInfoRow('用户名', _username ?? '', icon: Icons.account_circle),
                              _buildInfoRow('邮箱', _email ?? '', icon: Icons.email),
                              _buildInfoRow(
                                '昵称',
                                _nickname ?? '',
                                icon: Icons.person,
                                onTap: _showEditNicknameDialog,
                              ),
                              _buildInfoRow('注册时间', _createdAt ?? '', icon: Icons.calendar_today),
                            ],
                          ),
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
