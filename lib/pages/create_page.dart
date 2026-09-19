import 'dart:convert';
import 'package:flutter/material.dart';
import '../api.dart';
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

  final _portraitCtrl = TextEditingController();
  final _characterCtrl = TextEditingController();
  final _storyCtrl = TextEditingController();

  Future<void> _aiHelp(String type, TextEditingController ctrl) async {
    if (type == 'portrait') {
      // 捏形象：AI帮写优化prompt
      final inputCtrl = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('描述你的形象'),
          content: TextField(
            controller: inputCtrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: '如：傲娇猫娘，白发红瞳...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, inputCtrl.text), child: const Text('生成')),
          ],
        ),
      );
      if (result == null || result.isEmpty) return;
      ctrl.text = result;
      return;
    }

    // 角色/故事：AI直接创建
    if (ctrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先输入你的想法')));
      return;
    }
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final prompt = type == 'character'
          ? '请根据这个想法创建一个完整的AI角色，返回JSON格式：{"name":"角色名","description":"简介","greeting":"开场白","systemPrompt":"详细设定"}。想法：${ctrl.text}'
          : '请根据这个想法创建一个故事，返回JSON格式：{"name":"故事名","description":"简介","content":"世界观设定"}。想法：${ctrl.text}';
      final r = await Api.chat(model: 'normal', messages: [{'role': 'user', 'content': prompt}]);
      final reply = r['reply'] ?? '';
      // 简单解析JSON
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(reply);
      if (jsonMatch != null) {
        final data = jsonDecode(jsonMatch.group(0)!);
        if (type == 'character') {
          await Api.createCharacter({
            'name': data['name'] ?? '未命名',
            'description': data['description'] ?? '',
            'greeting': data['greeting'] ?? '',
            'systemPrompt': data['systemPrompt'] ?? '',
            'portrait': '',
            'category': 'AI创作',
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('角色创建成功！')));
        } else {
          await Api.createStory({
            'name': data['name'] ?? '未命名',
            'description': data['description'] ?? '',
            'content': data['content'] ?? '',
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('故事创建成功！')));
        }
      } else {
        ctrl.text = reply;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

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
        actions: [
          TextButton(
            onPressed: () {
              if (_tabController.index == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCharacterPage()));
              } else if (_tabController.index == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStoryPage()));
              }
            },
            child: Text('自定义创建', style: TextStyle(color: accentPink, fontSize: 14)),
          ),
        ],
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
              controller: _portraitCtrl,
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
              _buildActionButton('+ AI帮写', Icons.auto_awesome, onTap: () => _aiHelp('portrait', _portraitCtrl)),
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
              controller: _characterCtrl,
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
            child: _buildActionButton('+ AI助手', Icons.auto_awesome, onTap: () => _aiHelp('character', _characterCtrl)),
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
              controller: _storyCtrl,
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
            child: _buildActionButton('+ AI助手', Icons.auto_awesome, onTap: () => _aiHelp('story', _storyCtrl)),
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

  Widget _buildActionButton(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
