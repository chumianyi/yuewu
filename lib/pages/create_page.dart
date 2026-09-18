import 'package:flutter/material.dart';
import '../api.dart';
import 'create_character_form.dart';
import 'create_story_form.dart';

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF0F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.transparent,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 16),
            tabs: [
              Tab(text: '捏形象'),
              Tab(text: '角色'),
              Tab(text: '故事'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          _PortraitTab(),
          _CharacterTab(),
          _StoryTab(),
        ]),
      ),
    );
  }
}

class _PortraitTab extends StatefulWidget {
  const _PortraitTab();

  @override
  State<_PortraitTab> createState() => _PortraitTabState();
}

class _PortraitTabState extends State<_PortraitTab> {
  final _ctrl = TextEditingController();
  String? _portraitUrl;
  bool _generating = false;
  int _styleIndex = 0;

  final _styles = [
    {'name': '通用', 'color': Color(0xFFFFB6C1)},
    {'name': 'CG概念', 'color': Color(0x98FB98)},
    {'name': '言情漫画', 'color': Color(0xFFFFD700)},
    {'name': '像素画', 'color': Color(0x87CEEB)},
  ];

  Future<void> _generate() async {
    if (_ctrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先描述形象')));
      return;
    }
    setState(() => _generating = true);
    try {
      final prompt = 'anime style, ${_styles[_styleIndex]['name']}, ${_ctrl.text}';
      final r = await Api.generatePortrait(prompt);
      setState(() => _portraitUrl = r['url']);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _portraitUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(Api.portraitUrl(_portraitUrl), fit: BoxFit.cover),
                          )
                        : TextField(
                            controller: _ctrl,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              hintText: '输入你脑海中的形象',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(24),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_photo_alternate, size: 18),
                          label: const Text('参考图'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _generate,
                          icon: _generating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, size: 18, color: Colors.green),
                          label: const Text('AI帮写', style: TextStyle(color: Colors.green)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('风格', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text('Kolors', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (int i = 0; i < _styles.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _styleIndex = i),
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _styleIndex == i ? Colors.pink : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: _styles[i]['color'] as Color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_styles[i]['name'] as String, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              Container(
                width: 72,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('...', style: TextStyle(fontSize: 24))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CharacterTab extends StatefulWidget {
  const _CharacterTab();

  @override
  State<_CharacterTab> createState() => _CharacterTabState();
}

class _CharacterTabState extends State<_CharacterTab> {
  final _ctrl = TextEditingController();
  final _chips = ['养只美男鱼', '强娶豪夺', '穿越', '京圈太子爷', '你的醋精老公', '你的闺蜜', '经营模拟器'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: '输入你想创建的角色',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(24),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateCharacterForm(prefill: _ctrl.text)));
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.green),
                        label: const Text('AI助手', style: TextStyle(color: Colors.green)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in _chips)
                ActionChip(
                  label: Text(chip),
                  onPressed: () => _ctrl.text = chip,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ActionChip(
                label: const Text('... 更多'),
                onPressed: () {},
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StoryTab extends StatefulWidget {
  const _StoryTab();

  @override
  State<_StoryTab> createState() => _StoryTabState();
}

class _StoryTabState extends State<_StoryTab> {
  final _ctrl = TextEditingController();
  bool _isPlot = true;
  final _chips = ['弹幕系统', '拒绝PUA', '角色失忆了', '我是副本Boss', '我有隐藏实力'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _isPlot = true),
                child: Text('剧情故事', style: TextStyle(
                  fontSize: 18,
                  fontWeight: _isPlot ? FontWeight.bold : FontWeight.normal,
                  color: _isPlot ? Colors.black : Colors.grey,
                )),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => setState(() => _isPlot = false),
                child: Text('开放故事', style: TextStyle(
                  fontSize: 18,
                  fontWeight: !_isPlot ? FontWeight.bold : FontWeight.normal,
                  color: !_isPlot ? Colors.black : Colors.grey,
                )),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('+ 参与角色（可选）', style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: '输入你想构建的世界观',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(24),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateStoryForm(prefill: _ctrl.text)));
                        },
                        icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.green),
                        label: const Text('AI助手', style: TextStyle(color: Colors.green)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in _chips)
                ActionChip(
                  label: Text(chip),
                  onPressed: () => _ctrl.text = chip,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ActionChip(
                label: const Text('... 更多'),
                onPressed: () {},
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
