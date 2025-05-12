import 'package:flutter/material.dart';
import 'dart:io'; // 用于处理文件
import "api_service.dart";
import "model_selector.dart";
import "message_bubble.dart";
import "profile_screen.dart"; // 导入个人中心页面

class ChatScreen extends StatefulWidget {
  final int? initialChatId; // 初始 chatId
  final String? userAvatarPath; // 用户头像路径
  final String? userId; // 用户 ID

  const ChatScreen({super.key, this.initialChatId, this.userAvatarPath, this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController(); // 输入框控制器
  final ScrollController _scrollController = ScrollController(); // 滚动控制器
  final List<Map<String, String>> _messages = []; // 当前对话消息列表
  List<Map<String, dynamic>> _conversationHistory = []; // 对话历史记录
  bool _isLoading = false; // 是否正在加载
  bool _showModelSelector = true; // 控制模型选择按钮的显示
  String _selectedModel = '默认模型'; // 当前选择的模型
  String _botAvatar = 'assets/images/model_a.jpg'; // 默认 AI 头像
  int? _currentChatId; // 当前对话 ID

  String? _userAvatarPath; // 用户头像路径
  String? _userId; // 用户 ID
  String? _nickname; // 用户昵称

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.initialChatId; // 初始化时设置 chatId
    _userId = widget.userId ?? '0000001'; // 初始化用户 ID
    _fetchUserAvatar(); // 获取用户头像
    _fetchConversations(); // 加载对话历史
  }

  // 从后端获取用户头像
  Future<void> _fetchUserAvatar() async {
    try {
      final avatarUrl = await ApiService.getUserAvatar(_userId!);
      setState(() {
        _userAvatarPath = avatarUrl; // 更新用户头像 URL
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取用户头像失败: $e')),
      );
    }
  }

  // 获取对话历史
  Future<void> _fetchConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await ApiService.fetchChats();
      setState(() => _conversationHistory = conversations);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载对话失败: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 创建新对话
  Future<void> _startNewConversation() async {
    if (_messages.isNotEmpty) {
      await _saveConversation(); // 保存当前对话
    }
    setState(() {
      _messages.clear();
      _showModelSelector = true; // 显示模型选择器
    });

    try {
      final chatId = await ApiService.createChat();
      setState(() => _currentChatId = chatId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('新对话已创建，ID: $chatId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建新对话失败: $e')),
      );
    }
  }

  // 保存当前对话
  Future<void> _saveConversation() async {
    try {
      if (_currentChatId != null) {
        await ApiService.updateChatTitle(_currentChatId!, '新标题');
        _fetchConversations(); // 刷新对话历史
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存对话失败: $e')));
    }
  }

  // 加载指定对话
  Future<void> _loadConversation(int id) async {
    setState(() => _isLoading = true);
    try {
      final conversation = await ApiService.fetchChats();
      setState(() {
        _messages.clear();
        _messages.addAll(conversation.map((message) => message.cast<String, String>()));
        _currentChatId = id;
      });
      Navigator.pop(context); // 关闭侧边栏
      _scrollToBottom(); // 滚动到底部
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载对话失败: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 删除对话
  Future<void> _deleteConversation(int id) async {
    try {
      await ApiService.deleteChat(id);
      _fetchConversations(); // 刷新对话历史
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('对话 $id 已删除')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除对话失败: $e')),
      );
    }
  }

  // 发送消息
  void _sendMessage() async {
    if (_controller.text.isEmpty || _currentChatId == null) return;

    final userMessage = _controller.text;

    setState(() {
      // 添加用户消息
      _messages.add({
        'user': userMessage,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 添加 "加载中" 消息
      _messages.add({
        'loading': 'true',
      });
    });

    _controller.clear();

    try {
      final response = await ApiService.sendMessage(_currentChatId!, userMessage);
      setState(() {
        // 移除 "加载中" 消息
        _messages.removeWhere((message) => message.containsKey('loading'));

        // 添加模型回复
        _messages.add({
          'bot': response['reply'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom(); // 滚动到底部
    } catch (e) {
      setState(() {
        _messages.removeWhere((message) => message.containsKey('loading'));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送消息失败: $e')),
      );
    }
  }

  // 滚动到底部
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

  // 选择模型
  void _selectModel(String model, String avatar) {
    setState(() {
      _selectedModel = model;
      _botAvatar = avatar; // 更新 AI 头像
      _showModelSelector = false; // 隐藏模型选择器
    });
  }

  // 上传附件
  void _uploadAttachment() {
    // 模拟上传附件逻辑
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // 粉色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC0CB), // 浅粉色标题栏
        title: const Text('AI 对话', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _startNewConversation, // 新建对话按钮
            tooltip: '新建对话',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFFFE4E1), // 浅粉色抽屉背景
        child: ListView(
          children: [
            GestureDetector(
              onTap: () {
                // 跳转到个人中心页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      userId: _userId,
                      onAvatarChanged: (newAvatarPath) {
                        setState(() {
                          _userAvatarPath = newAvatarPath; // 更新头像 URL
                        });
                      },
                    ),
                  ),
                );
              },
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFFFFB6C1)), // 粉红色背景
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _userAvatarPath != null
                          ? NetworkImage(_userAvatarPath!) // 从网络加载头像
                          : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _nickname ?? '未知昵称', // 显示昵称
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
            ),
            // 显示对话历史列表
            ..._conversationHistory.map((conversation) {
              final id = conversation['id'];
              final lastMessage = conversation['messages'].isNotEmpty
                  ? conversation['messages'].last['user']
                  : '空对话';
              return ListTile(
                title: Text(
                  '对话 $id',
                  style: const TextStyle(color: Colors.black),
                ),
                subtitle: Text(
                  '最近: $lastMessage',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () => _loadConversation(id), // 加载指定对话
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteConversation(id), // 删除对话
                ),
              );
            }),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isLoading) const LinearProgressIndicator(), // 加载指示器
              const SizedBox(height: 16), // 在顶部留出一定的空间
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
                      userAvatar: _userAvatarPath ?? 'assets/images/default_avatar.jpg', // 用户头像
                      botAvatar: _botAvatar, // 动态设置 AI 头像
                      modelName: _selectedModel, // 动态传递模型名称
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
                        controller: _controller, // 输入框
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: '输入消息...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFFFE4E1), // 浅粉色输入框
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
                      onPressed: _uploadAttachment, // 上传附件按钮
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF69B4), // 热粉色按钮
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _sendMessage, // 发送消息按钮
                      child: const Text('发送'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showModelSelector)
            ModelSelector(onSelectModel: _selectModel), // 模型选择器
        ],
      ),
    );
  }
}
