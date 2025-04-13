import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  List<Map<String, dynamic>> _conversationHistory = [];
  final String _apiBaseUrl = 'http://your-backend-api.com'; // 替换为你的后端地址
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await http.get(Uri.parse('$_apiBaseUrl/conversations'));
      if (response.statusCode == 200) {
        setState(() {
          _conversationHistory = List<Map<String, dynamic>>.from(
            json.decode(response.body),
          );
        });
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载对话失败: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConversation() async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'messages': _messages}),
      );
      if (response.statusCode == 201) {
        _fetchConversations(); // 刷新对话历史
      } else {
        throw Exception('Failed to save conversation');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存对话失败: $e')));
    }
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add({
        'user': _controller.text,
        'bot': '正在生成回复...',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    final userMessage = _controller.text;
    _controller.clear();

    // 模拟大模型回复
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.last['bot'] = '这是对 "$userMessage" 的回复';
      });
      _scrollToBottom();
    });
  }

  void _startNewConversation() {
    if (_messages.isNotEmpty) {
      _saveConversation();
    }
    setState(() {
      _messages.clear();
    });
  }

  Future<void> _loadConversation(int id) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/conversations/$id'),
      );
      if (response.statusCode == 200) {
        final conversation = json.decode(response.body);
        setState(() {
          _messages.clear();
          _messages.addAll(
            List<Map<String, String>>.from(conversation['messages']),
          );
        });
        Navigator.pop(context); // 关闭侧边栏
        _scrollToBottom();
      } else {
        throw Exception('Failed to load conversation');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载对话失败: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 对话'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _startNewConversation,
            tooltip: '新建对话',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                '对话历史',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ..._conversationHistory.map((conversation) {
              final id = conversation['id'];
              final lastMessage =
                  conversation['messages'].isNotEmpty
                      ? conversation['messages'].last['user']
                      : '空对话';
              return ListTile(
                title: Text('对话 $id'),
                subtitle: Text('最近: $lastMessage'),
                onTap: () => _loadConversation(id),
              );
            }),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUserMessage = message.containsKey('user');
                return Align(
                  alignment:
                      isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment:
                        isUserMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUserMessage ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(10),
                            topRight: const Radius.circular(10),
                            bottomLeft:
                                isUserMessage
                                    ? const Radius.circular(10)
                                    : Radius.zero,
                            bottomRight:
                                isUserMessage
                                    ? Radius.zero
                                    : const Radius.circular(10),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          isUserMessage ? message['user']! : message['bot']!,
                          style: TextStyle(
                            color: isUserMessage ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                          softWrap: true,
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'HH:mm',
                        ).format(DateTime.parse(message['timestamp']!)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
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
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Text('发送'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
