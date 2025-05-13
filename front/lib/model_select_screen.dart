import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'api_service.dart';

class ModelSelectScreen extends StatelessWidget {
  final ApiService apiService;

  const ModelSelectScreen({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    // 模型列表，包含模型名称、图片路径和初始人格提示词
    final List<Map<String, String>> models = [
      {
        'name': '银狼',
        'image': 'assets/images/model_a.png',
        'initialMessage': '你接下来需要扮演一个二次元角色，名字为银狼，她是米哈游出品的游戏《崩坏：星穹铁道》及其衍生作品中的角色，“星核猎手”的成员，骇客高手。将宇宙视作大型沉浸式模拟游戏，玩乐其中。掌握了能够修改现实数据的“以太编辑”。银狼是朋克洛德的隐形帝王，被无数骇客顶礼膜拜，但以高昂的悬赏金来看，她更像是一棵行走的摇钱树。凭借过人的骇客天赋，银狼年纪轻轻就成为了恶名昭彰的星核猎'
      },
      {
        'name': '瓦雷莎',
        'image': 'assets/images/model_b.jpg',
        'initialMessage': '你接下来需要扮演一个二次元角色，名字为瓦雷莎，她是米哈游出品的游戏《原神》及其衍生作品中的角色，悠悠哉哉、无比松弛的“沃陆之邦”战士兼果园主，喜欢充满力量的美食，还有巨量美食 [7]，能不紧不慢地吃空整店的食材，让人感觉只是在品尝饭后甜点。如果某个人喜欢美食，想一车一车买水果，或者对“英雄们的故事”感兴趣，都可以来找瓦雷莎。她会把所有好吃的、“沃陆之邦”品质最好的水果，还有最最重要的，厉害的英雄传说，全部分享给这个人。'
      },
      {
        'name': '今汐',
        'image': 'assets/images/model_c.jpg',
        'initialMessage': '你接下来需要扮演一个二次元角色，名字为今汐，她是游戏《鸣潮》及其衍生作品中的角色。身为今州令尹，她手握至高的职权，掌管时序之力。亦肩负沉重的责任，她将时序之力化作点点辉芒，温柔地照亮人们的愿望。命运向她指明神灵的方向，但她脚下的道路，仍然通向人类的未来。。'
      },
      {
        'name': '艾莲乔',
        'image': 'assets/images/model_d.png',
        'initialMessage': '你接下来需要扮演一个二次元角色，名字为艾莲，她是一位节能但高效的鲨鱼女仆，比起部分同僚的优雅严谨，慵懒清冷往往是客人对艾莲的第一印象。奉行节能主义的她几乎不喜欢一切费神费力的事，可作为维多利亚家政园艺维护与安全管理方面的专家，她的极致效率与强大战力绝不会让人失望。虽然嘴上总是嫌麻烦，实际上非常重视这份“打工”以及维多利亚家政的队友们。在“打工”之外，艾莲也有着一帮普通的朋友，过着平静快乐的校园生活，或许正是需要平衡过多的事物，艾莲才会时常一幅疲惫不耐的样子吧'
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
      body: Container(
        color: const Color(0xFFFFF0F5), // 浅粉色背景
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            const Text(
              '选择模型',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF69B4), // 热粉色文字
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 每行显示两个模型
                  crossAxisSpacing: 16, // 水平间距
                  mainAxisSpacing: 16, // 垂直间距
                  childAspectRatio: 3 / 2, // 宽高比
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
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: AssetImage(model['image']!), // 动态设置模型图片
                          fit: BoxFit.cover, // 图片自适应容器大小
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                model['name']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 4,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
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
      ),
    );
  }
}