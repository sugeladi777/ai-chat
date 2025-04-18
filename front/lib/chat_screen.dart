import 'package:flutter/material.dart';
import "api_service.dart";
import "model_selector.dart";
import "message_bubble.dart";

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _fetchConversations(); // 初始化时加载对话历史
  }

  // 获取对话历史
  Future<void> _fetchConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await ApiService.fetchConversations();
      setState(() => _conversationHistory = conversations);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载对话失败: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 保存当前对话
  Future<void> _saveConversation() async {
    try {
      await ApiService.saveConversation(_messages);
      _fetchConversations(); // 刷新对话历史
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存对话失败: $e')));
    }
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;

    setState(() {
      // 添加用户消息
      _messages.add({
        'user': userMessage,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    _controller.clear();

    // 模拟模型回复
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          // 添加模型回复
          _messages.add({
            'bot': '这是对 "$userMessage" 的回复，用于验证对话功能是否正常。',
            'timestamp': DateTime.now().toIso8601String(),
          });
        });
        _scrollToBottom(); // 滚动到底部
      }
    });
  }

  // 开始新对话
  void _startNewConversation() {
    if (_messages.isNotEmpty) {
      _saveConversation(); // 保存当前对话
    }
    setState(() {
      _messages.clear();
      _showModelSelector = true; // 显示模型选择器
    });
  }

  // 加载指定对话
  Future<void> _loadConversation(int id) async {
    setState(() => _isLoading = true);
    try {
      final conversation = await ApiService.loadConversation(id);
      setState(() {
        _messages.clear();
        _messages.addAll(conversation);
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
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFFFB6C1)), // 粉红色
              child: Text(
                '对话历史',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            // 显示对话历史列表
            ..._conversationHistory.map((conversation) {
              final id = conversation['id'];
              final lastMessage =
                  conversation['messages'].isNotEmpty
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
              );
            }).toList(),
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
                      userAvatar: 'assets/images/user.jpg', // 用户头像
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
