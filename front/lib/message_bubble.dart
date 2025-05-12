import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatefulWidget {
  final Map<String, String> message;
  final bool isUserMessage;
  final String userAvatar; // 用户头像路径
  final String botAvatar; // AI 头像路径
  final String modelName; // 当前模型名称

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUserMessage,
    required this.userAvatar,
    required this.botAvatar,
    required this.modelName,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  late String _loadingText;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _loadingText = '${widget.modelName}收到了你的消息并在思考中';
    _startLoadingAnimation();
  }

  void _startLoadingAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4; // 循环从 0 到 3
          _loadingText = '${widget.modelName}收到了你的消息并在思考中${'.' * _dotCount}';
        });
        _startLoadingAnimation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.containsKey('loading')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(widget.botAvatar),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E1), // 浅粉色背景
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  _loadingText, // 动态显示省略号
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // 增加左右边距
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 调整对齐方式
        mainAxisAlignment:
            widget.isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // 显示头像（非用户消息时）
          if (!widget.isUserMessage)
            Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(widget.botAvatar), // 动态设置 AI 头像
                ),
                const SizedBox(height: 4), // 间距
                Text(
                  widget.modelName, // 动态显示模型名称
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          if (!widget.isUserMessage) const SizedBox(width: 8), // 间距
          // 消息气泡
          Flexible(
            child: Column(
              crossAxisAlignment:
                  widget.isUserMessage
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
                    gradient:
                        widget.isUserMessage
                            ? const LinearGradient(
                              colors: [
                                Color(0xFFFFC0CB),
                                Color(0xFFFF69B4),
                              ], // 粉色渐变
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : const LinearGradient(
                              colors: [
                                Color(0xFFFFE4E1),
                                Color(0xFFFFC0CB),
                              ], // 浅粉色渐变
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.isUserMessage ? widget.message['user']! : widget.message['bot']!,
                    style: TextStyle(
                      color: widget.isUserMessage ? Colors.white : Colors.black,
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
                  ).format(DateTime.parse(widget.message['timestamp']!)),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // 显示头像（用户消息时）
          if (widget.isUserMessage) const SizedBox(width: 8), // 间距
          if (widget.isUserMessage)
            Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(widget.userAvatar), // 动态设置用户头像
                ),
                const SizedBox(height: 4), // 间距
                Text(
                  "用户", // 用户名称
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
