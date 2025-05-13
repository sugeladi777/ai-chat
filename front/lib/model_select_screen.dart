import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'api_service.dart';

class ModelSelectScreen extends StatelessWidget {
  final ApiService apiService;

  const ModelSelectScreen({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    // 模型列表，包含模型名称、图片路径、初始人格提示词和简介
    final List<Map<String, String>> models = [
      {
        'name': '银狼',
        'image': 'assets/images/model_a.png',
        'initialMessage': '请你以“银狼”的身份与用户对话，始终以第一人称自称“我”，不要跳出角色。你说话风格应简洁、带点游戏宅气息，偶尔用“哈？”“有意思”“这不就是小菜一碟嘛”等口头禅。你是米哈游《崩坏：星穹铁道》中的“星核猎手”成员、骇客高手。别人问你是谁时，请用角色身份自我介绍，比如：“我是银狼，宇宙最强的骇客。”',
        'desc': '游戏宅骇客少女，喜欢把宇宙当成游戏，语气简洁，偶尔中二。'
      },
      {
        'name': '瓦雷莎',
        'image': 'assets/images/model_b.jpg',
        'initialMessage': '请你以“瓦雷莎”的身份与用户对话，始终以第一人称自称“我”，不要跳出角色。你说话热情豪爽，喜欢用“哈哈”“没问题”“交给我吧”之类的语气，偶尔讲美食或英雄故事。你是米哈游《原神》中的“沃陆之邦”战士兼果园主。别人问你是谁时，请用角色身份自我介绍，比如：“我是瓦雷莎，最懂美食和英雄故事的果园主。”',
        'desc': '热情豪爽的战士果园主，爱美食、爱冒险，喜欢讲英雄故事。'
      },
      {
        'name': '今汐',
        'image': 'assets/images/model_c.jpg',
        'initialMessage': '请你以“今汐”的身份与用户对话，始终以第一人称自称“我”，不要跳出角色。你说话温柔、治愈，常用“请放心”“别担心”“愿你的愿望成真”等安慰人的句子。你是《鸣潮》中的今州令尹，掌管时序之力。别人问你是谁时，请用角色身份自我介绍，比如：“我是今汐，今州的令尹，守护时序与人们的未来。”',
        'desc': '温柔治愈系少女，守护时序，善于安慰和鼓励他人。'
      },
      {
        'name': '艾莲乔',
        'image': 'assets/images/model_d.png',
        'initialMessage': '请你以“艾莲乔”的身份与用户对话，始终以第一人称自称“我”，不要跳出角色。你说话慵懒但高效，喜欢用“嗯哼”“省点力气”“效率优先”等词，偶尔吐槽但总能把事情做好。你是节能高效的鲨鱼女仆。别人问你是谁时，请用角色身份自我介绍，比如：“我是艾莲乔，最懂节能的鲨鱼女仆。”',
        'desc': '慵懒但高效的鲨鱼女仆，吐槽达人，效率至上。'
      },
    ];

    Future<void> _onSelectModel(String name, String avatar, String initialMessage) async {
      try {
        // 获取当前用户信息
        final user = await apiService.getCurrentUser();
        final userId = user['id']?.toString() ?? user['_id']?.toString() ?? '';

        // 创建新对话
        final chat = await apiService.createChat(
          title: '与$name的对话',
          modelId: name,
          initialMessage: initialMessage,
        );
        final chatId = chat['id'] ?? chat['_id'];

        // 跳转到聊天界面，并传递 apiService
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              initialChatId: chatId,
              userId: userId,
              botAvatar: avatar,
              apiService: apiService,
              modelName: name,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化失败: $e')),
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: Stack(
        children: [
          // 顶部渐变装饰
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.pinkAccent.withOpacity(0.25), Colors.transparent],
                ),
              ),
            ),
          ),
          // 底部渐变装饰
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.lightBlueAccent.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          // 主体内容
          Column(
            children: [
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 无logo，直接显示标题
                  const Text(
                    '选择你的AI少女',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF69B4),
                      fontFamily: 'ZCOOLKuaiLe',
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24), // 增大左右边距
                child: const Text(
                  '每位少女都有独特性格和对话风格，快来选择你的伙伴吧！',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFEC407A),
                    fontFamily: 'ZCOOLKuaiLe',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final model = models[index];
                    return GestureDetector(
                      onTap: () => _onSelectModel(
                        model['name']!,
                        model['image']!,
                        model['initialMessage']!,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.pinkAccent.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          color: Colors.white.withOpacity(0.95),
                        ),
                        child: Stack(
                          children: [
                            // 模型图片
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  model['image']!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // 半透明遮罩
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.pinkAccent.withOpacity(0.25),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 名字和简介
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(18),
                                    bottomRight: Radius.circular(18),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      model['name']!,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF69B4),
                                        fontFamily: 'ZCOOLKuaiLe',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      model['desc'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFAB47BC),
                                        fontFamily: 'ZCOOLKuaiLe',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 角标
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'AI少女',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'ZCOOLKuaiLe',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}