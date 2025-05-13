import 'package:flutter/material.dart';
import "api_service.dart";
import "message_bubble.dart";
import "profile_screen.dart";
import "model_select_screen.dart";

class ChatScreen extends StatefulWidget {
  final String? initialChatId;
  final String? userAvatarPath;
  final String? userId;
  final String? botAvatar;
  final String? modelName;
  final ApiService apiService;

  const ChatScreen({
    super.key,
    required this.apiService,
    this.initialChatId,
    this.userAvatarPath,
    this.userId,
    this.botAvatar,
    this.modelName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 控制器和状态
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  List<Map<String, dynamic>> _conversationHistory = [];
  bool _isLoading = false;

  // 用户和会话相关
  String? _currentChatId;
  String? _userAvatarUrl;
  String? _userId;
  String? _nickname;
  String _selectedModel = '默认模型';
  String _botAvatar = 'assets/images/model_a.jpg';
  String _appBarTitle = '少女 AI 大世界';

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.initialChatId?.toString();
    _userAvatarUrl = widget.userAvatarPath;
    _botAvatar = widget.botAvatar ?? 'assets/images/model_a.jpg';
    _selectedModel = widget.modelName ?? '默认模型';
    _fetchUserProfile();
    _fetchConversationHistories();
  }

  /// 获取用户信息（头像、昵称、UID）
  Future<void> _fetchUserProfile() async {
    try {
      final user = await widget.apiService.getCurrentUser();
      setState(() {
        _userAvatarUrl =
            (user['avatar_url'] == null || user['avatar_url'].isEmpty)
                ? 'assets/images/default_avatar.jpg'
                : user['avatar_url'];
        _nickname = user['nickname'] ?? '未知昵称';
        _userId = user['id']?.toString() ?? user['_id']?.toString() ?? '未知用户';
      });
    } catch (e) {
      setState(() {
        _userAvatarUrl = 'assets/images/default_avatar.jpg';
        _nickname = '未知昵称';
        _userId = '未知用户';
      });
    }
  }

  /// 获取历史对话
  Future<void> _fetchConversationHistories() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await widget.apiService.fetchUserHistory();
      setState(
        () =>
            _conversationHistory =
                (conversations['chats'] as List<dynamic>?)
                    ?.map((e) => e as Map<String, dynamic>)
                    .toList() ??
                [],
      );
    } catch (e) {
      _showSnackBar('加载对话失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 新建对话
  Future<void> _startNewConversation() async {
    String customTitle = '';
    if (_currentChatId != null) {
      try {
        await widget.apiService.setChatTitle(_currentChatId!, customTitle);
      } catch (e) {
        _showSnackBar('设置对话标题失败: $e');
      }
    }
    // 跳转到模型选择界面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelSelectScreen(apiService: widget.apiService),
      ),
    );
  }

  /// 发送消息
  void _sendMessage() async {
    if (_controller.text.isEmpty || _currentChatId == null) return;
    final userMessage = _controller.text;

    setState(() {
      _messages.add({
        'user': userMessage,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _messages.add({'loading': 'true'});
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await widget.apiService.sendMessage(
        _currentChatId!,
        userMessage,
      );
      setState(() {
        _messages.removeWhere((message) => message.containsKey('loading'));
        if (response['ai_message'] != null) {
          final aiMsg = response['ai_message'];
          _messages.add({
            'bot': aiMsg['content'] ?? '',
            'timestamp': aiMsg['timestamp'] ?? '',
          });
        }
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeWhere((message) => message.containsKey('loading'));
      });
      _showSnackBar('发送消息失败: $e');
      print('Error sending message: $e');
    }
  }

  /// 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 加载历史对话内容
  Future<void> _loadConversation(String id) async {
    setState(() => _isLoading = true);
    try {
      final chatDetail = await widget.apiService.fetchChatDetail(id);
      print('Chat detail: $chatDetail');
      final messages = chatDetail['messages'] as List<dynamic>? ?? [];

      // model_id 到头像和名字的映射
      const modelAvatarMap = {
        '银狼': 'assets/images/model_a.png',
        '瓦雷莎': 'assets/images/model_b.jpg',
        '今汐': 'assets/images/model_c.jpg',
        '艾莲乔': 'assets/images/model_d.png',
      };

      final modelId = chatDetail['model_id']?.toString() ?? '';
      final botAvatar = modelAvatarMap[modelId] ?? 'assets/images/model_a.jpg';
      final title = chatDetail['title']?.toString() ?? 'AI 对话';

      setState(() {
        _messages
          ..clear()
          ..addAll(messages.map((msg) {
            final map = Map<String, dynamic>.from(msg);
            return map['role'] == 'user'
                ? {
                    'user': map['content'] ?? '',
                    'timestamp': map['timestamp'] ?? '',
                  }
                : {
                    'bot': map['content'] ?? '',
                    'timestamp': map['timestamp'] ?? '',
                  };
          }));
        _currentChatId = id;
        _botAvatar = botAvatar;
        _selectedModel = modelId.isNotEmpty ? modelId : '默认模型';
        _appBarTitle = title;
      });
      Navigator.pop(context);
      _scrollToBottom();
    } catch (e) {
      _showSnackBar('加载对话失败: $e');
      print('Error loading conversation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 删除对话
  Future<void> _deleteConversation(String id) async {
    try {
      await widget.apiService.deleteChat(id);
      await _fetchConversationHistories();
      _showSnackBar('对话 $id 已删除');
    } catch (e) {
      _showSnackBar('删除对话失败: $e');
    }
  }

  /// 附件上传（未实现）
  void _uploadAttachment() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('上传附件'),
            content: const Text('选择附件上传功能尚未实现'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  /// 显示提示
  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 构建侧边栏用户信息
  Widget _buildDrawerHeader() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              userId: _userId,
              onAvatarChanged: (newAvatarPath) {
                setState(() {
                  _userAvatarUrl = newAvatarPath;
                });
              },
              apiService: widget.apiService, // 传递
            ),
          ),
        );
      },
      child: DrawerHeader(
        decoration: const BoxDecoration(color: Color(0xFFFFB6C1)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage:
                  (_userAvatarUrl != null &&
                          _userAvatarUrl!.isNotEmpty &&
                          (_userAvatarUrl!.startsWith('http://') ||
                              _userAvatarUrl!.startsWith('https://')))
                      ? NetworkImage(_userAvatarUrl!)
                      : const AssetImage('assets/images/default_avatar.jpg')
                          as ImageProvider,
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 8),
            Text(
              _nickname ?? '未知昵称',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'UID：${_userId ?? '未知用户'}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建历史对话列表
  List<Widget> _buildConversationList() {
    return _conversationHistory.map((conversation) {
      final id = conversation['_id'] ?? conversation['id'];
      final title = conversation['title'] ?? '无标题';
      return ListTile(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        onTap: () => _loadConversation(id.toString()),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteConversation(id.toString()),
        ),
      );
    }).toList();
  }

  /// 构建主界面
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC0CB),
        title: Text(_appBarTitle, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _startNewConversation,
            tooltip: '新建对话',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFFFE4E1),
        child: ListView(
          children: [_buildDrawerHeader(), ..._buildConversationList()],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isLoading) const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUserMessage = message.containsKey('user');
                    return MessageBubble(
                      message: message,
                      isUserMessage: isUserMessage,
                      userAvatar:
                          _userAvatarUrl ?? 'assets/images/default_avatar.jpg',
                      botAvatar: _botAvatar,
                      modelName: _selectedModel,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: '输入消息...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFFFE4E1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.pink),
                      onPressed: _uploadAttachment,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF69B4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _sendMessage,
                      child: const Text('发送'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
