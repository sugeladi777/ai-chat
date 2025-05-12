import 'package:flutter/material.dart';

class ModelSelector extends StatelessWidget {
  final Function(String, String) onSelectModel; // 回调函数，传递模型名称和图片路径

  const ModelSelector({super.key, required this.onSelectModel});

  @override
  Widget build(BuildContext context) {
    // 模型列表，包含模型名称和对应图片路径
    final List<Map<String, String>> models = [
      {'name': '银狼', 'image': 'assets/images/model_a.png'},
      {'name': '瓦雷莎', 'image': 'assets/images/model_b.jpg'},
      {'name': '今汐', 'image': 'assets/images/model_c.jpg'},
      {'name': '艾莲乔', 'image': 'assets/images/model_d.png'},
    ];

    return Container(
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
                  onTap: () => onSelectModel(model['name']!, model['image']!),
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
    );
  }
}
