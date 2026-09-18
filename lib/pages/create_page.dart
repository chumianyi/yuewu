import 'package:flutter/material.dart';
import 'create_character_page.dart';
import 'create_story_page.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final Color primaryPink = const Color(0xFFFFB6C1);
  final Color bgPink = const Color(0xFFFFF0F5);
  final Color accentPink = const Color(0xFFFF69B4);

  final List<String> _tabs = const ['捏形象', '角色', '故事'];

  final List<Map<String, dynamic>> _stylePresets = const [
    {'label': '通用', 'color': Color(0xFFFFD1DC)},
    {'label': 'CG概念', 'color': Color(0xFFE6E6FA)},
    {'label': '言情漫画', 'color': Color(0xFFFFC0CB)},
    {'label': '像素画', 'color': Color(0xFF98FB98)},
    {'label': '全部', 'color': Color(0xFFFFDEAD)},
  ];

  final List<String> _characterChips = const [
    '养只美男鱼',
    '强娶豪夺',
    '穿越',
    '京圈太子爷',
    '你的醋精老公',
    '你的闺蜜',
    '经营模拟器',
    '更多',
  ];

  final List<String> _storyChips = const [
    '弹幕系统',
    '拒绝PUA',
    '角色失忆了',
    '我是副本Boss',
    '我有隐藏实力',
    '更多',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,
      appBar: AppBar(
        backgroundColor: bgPink,
        elevation: 0,
        title: Text(
          '创作',
          style: TextStyle(
            color: accentPink,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentPink,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: accentPink,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPortraitTab(),
          _buildCharacterTab(),
          _buildStoryTab(),
        ],
      ),
    );
  }

  Widget _buildPortraitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '输入你脑海中的形象',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton('+ 参考图', Icons.image_outlined),
              const SizedBox(width: 12),
              _buildActionButton('+ AI帮写', Icons.auto_awesome),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '风格预设',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _stylePresets.length,
              itemBuilder: (context, index) {
                final preset = _stylePresets[index];
                return Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: preset['color'] as Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preset['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '输入你想创建的角色',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: _buildActionButton('+ AI助手', Icons.auto_awesome),
          ),
          const SizedBox(height: 24),
          Text(
            '快捷灵感',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _characterChips.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: ActionChip(
                    label: Text(
                      _characterChips[index],
                      style: const TextStyle(fontSize: 13),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: primaryPink),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateCharacterPage(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: accentPink,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Text(
                        '剧情故事',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        '开放故事',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: _buildActionButton('+ 参与角色', Icons.person_add_outlined),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '输入你想构建的世界观',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: _buildActionButton('+ AI助手', Icons.auto_awesome),
          ),
          const SizedBox(height: 24),
          Text(
            '快捷灵感',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _storyChips.map((chip) {
              return ActionChip(
                label: Text(chip, style: const TextStyle(fontSize: 13)),
                backgroundColor: Colors.white,
                side: BorderSide(color: primaryPink),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateStoryPage(),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryPink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accentPink),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accentPink,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
