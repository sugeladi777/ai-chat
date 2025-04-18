import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, String> message;
  final bool isUserMessage;
  final String userAvatar; // 用户头像路径
  final String botAvatar; // AI 头像路径
  final String modelName; // 当前模型名称

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUserMessage,
    required this.userAvatar, // 传递用户头像路径
    required this.botAvatar, // 传递 AI 头像路径
    required this.modelName, // 传递模型名称
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // 增加左右边距
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 调整对齐方式
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // 显示头像（非用户消息时）
          if (!isUserMessage)
            Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(botAvatar), // 动态设置 AI 头像
                ),
                const SizedBox(height: 4), // 间距
                Text(
                  modelName, // 动态显示模型名称
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          if (!isUserMessage) const SizedBox(width: 8), // 间距
          // 消息气泡
          Flexible(
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
                    gradient:
                        isUserMessage
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // 显示头像（用户消息时）
          if (isUserMessage) const SizedBox(width: 8), // 间距
          if (isUserMessage)
            Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(userAvatar), // 动态设置用户头像
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
