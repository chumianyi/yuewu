import 'dart:convert';
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'create_character_page.dart';
import 'create_story_page.dart';
import 'ai_assist_dialog.dart';

const Color _kPrimary = Color(0xFFFFB6C1);
const Color _kBg = Color(0xFFFFF0F5);
const Color _kCard = Colors.white;

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF4A4A4A)),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFFFFB6C1),
            unselectedLabelColor: Color(0xFF9E9E9E),
            indicatorColor: _kPrimary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
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

// ── 捏形象 Tab ────────────────────────────────────────────────

class _PortraitTab extends StatefulWidget {
  const _PortraitTab();

  @override
  State<_PortraitTab> createState() => _PortraitTabState();
}

class _PortraitTabState extends State<_PortraitTab> {
  final _ctrl = TextEditingController();
  String? _portraitUrl;
  bool _generating = false;
  bool _aiWriting = false;
  int _styleIndex = 0;

  static const _styles = [
    _StyleItem('通用', Color(0xFFE0E0E0)),
    _StyleItem('CG概念', Color(0xFF90CAF9)),
    _StyleItem('言情漫画', Color(0xFFF8BBD0)),
    _StyleItem('像素画', Color(0xFFA5D6A7)),
    _StyleItem('全部', Color(0xFFCE93D8)),
  ];

  Future<void> _generatePortrait(String prompt) async {
    setState(() => _generating = true);
    try {
      final r = await ApiService().generatePortrait(prompt);
      final path = r['url'] ?? r['path'] ?? r['image'] ?? '';
      setState(() => _portraitUrl = path.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _aiHelpWrite() async {
    final userInput = _ctrl.text.trim();
    if (userInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先描述一下你脑海中的形象吧')),
      );
      return;
    }
    setState(() => _aiWriting = true);
    try {
      final res = await ApiService().chat(
        'default',
        [
          {
            'role': 'system',
            'content':
                '你是一个绘画prompt优化专家。用户会用简短的中文描述他想要的角色形象，请将其扩展为详细、生动的英文绘画prompt，包含外貌、服饰、发型、表情、画风、光线、背景等细节。直接输出优化后的英文prompt，不要解释。',
          },
          {'role': 'user', 'content': userInput},
        ],
        null,
        null,
      );
      String optimized = '';
      if (res is Map) {
        optimized = (res['content'] ??
                res['reply'] ??
                res['message'] ??
                res['text'] ??
                '')
            .toString();
      }
      if (optimized.isEmpty) optimized = userInput;
      _ctrl.text = optimized;
      await _generatePortrait(optimized);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI优化失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _aiWriting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final styleName = _styles[_styleIndex].name;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _portraitUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              ApiService().baseUrl + _portraitUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey, size: 48),
                              ),
                            ),
                          )
                        : TextField(
                            controller: _ctrl,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                            decoration: const InputDecoration(
                              hintText: '输入你脑海中的形象',
                              hintStyle:
                                  TextStyle(color: Color(0xFFBDBDBD), fontSize: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(24),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('上传参考图'),
                                content: const Text('请输入参考图URL，AI将根据参考图生成相似风格的立绘'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_photo_alternate, size: 18),
                          label: const Text('参考图'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimary,
                            side: const BorderSide(color: _kPrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: (_generating || _aiWriting)
                              ? null
                              : _aiHelpWrite,
                          icon: _aiWriting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(_aiWriting ? 'AI优化中' : 'AI帮写'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
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
        // 风格预设横滑
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('风格预设',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(styleName,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _styles.length,
            itemBuilder: (context, i) {
              final selected = _styleIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _styleIndex = i),
                child: Container(
                  width: 68,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? _kPrimary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _styles[i].color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_styles[i].name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? _kPrimary : const Color(0xFF757575),
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StyleItem {
  final String name;
  final Color color;
  const _StyleItem(this.name, this.color);
}

// ── 角色 Tab ────────────────────────────────────────────────

class _CharacterTab extends StatefulWidget {
  const _CharacterTab();

  @override
  State<_CharacterTab> createState() => _CharacterTabState();
}

class _CharacterTabState extends State<_CharacterTab> {
  final _ctrl = TextEditingController();
  static const _chips = [
    '养只美男鱼',
    '强娶豪夺',
    '穿越',
    '京圈太子爷',
    '你的醋精老公',
    '你的闺蜜',
    '经营模拟器',
  ];

  void _openAiAssist() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AiAssistDialog(
        title: 'AI创造角色',
        hint: '描述你想创建的角色，比如：一个霸道总裁类型的学长',
        systemPrompt:
            '你是一个AI角色创作助手。用户会用一句话描述想要的角色，请据此生成完整的角色人设，包含：角色名、性格、外貌、身份背景、说话风格、与用户的关系。用中文输出，格式清晰。',
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _ctrl.text = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 右上角自定义创建
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateCharacterPage(prefill: _ctrl.text),
                    ),
                  );
                },
                child: const Text('自定义创建',
                    style: TextStyle(color: _kPrimary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: '输入你想创建的角色',
                        hintStyle:
                            TextStyle(color: Color(0xFFBDBDBD), fontSize: 18),
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
                        onPressed: _openAiAssist,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('AI助手'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 快捷chip横滑
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _chips.length,
            itemBuilder: (context, i) {
              return Container(
                margin: const EdgeInsets.only(right: 10),
                child: ActionChip(
                  label: Text(_chips[i]),
                  onPressed: () => _ctrl.text = _chips[i],
                  backgroundColor: _kCard,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  labelStyle: const TextStyle(fontSize: 13),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── 故事 Tab ────────────────────────────────────────────────

class _StoryTab extends StatefulWidget {
  const _StoryTab();

  @override
  State<_StoryTab> createState() => _StoryTabState();
}

class _StoryTabState extends State<_StoryTab> {
  final _ctrl = TextEditingController();
  bool _isPlot = true; // true=剧情故事, false=开放故事
  List<dynamic> _myCharacters = [];
  final Set<int> _selectedCharIds = {};
  bool _loadingChars = false;
  static const _chips = [
    '弹幕系统',
    '拒绝PUA',
    '角色失忆了',
    '我是副本Boss',
    '我有隐藏实力',
  ];

  @override
  void initState() {
    super.initState();
    _loadMyCharacters();
  }

  Future<void> _loadMyCharacters() async {
    setState(() => _loadingChars = true);
    try {
      final chars = await ApiService().getMyCharacters();
      setState(() => _myCharacters = chars);
    } catch (_) {
      // 静默失败
    } finally {
      if (mounted) setState(() => _loadingChars = false);
    }
  }

  void _openAiAssist() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AiAssistDialog(
        title: 'AI构建世界观',
        hint: '描述你想构建的故事世界观，比如：修仙世界，宗门对立',
        systemPrompt:
            '你是一个AI故事创作助手。用户会描述想要的世界观，请据此生成详细的故事设定，包含：世界观背景、主要人物关系、剧情走向、核心冲突。用中文输出。',
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _ctrl.text = result);
    }
  }

  void _showCharacterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('选择参与角色',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_loadingChars)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: _kPrimary),
              )
            else if (_myCharacters.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('还没有自己的角色，先去创建吧',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _myCharacters.length,
                  itemBuilder: (context, i) {
                    final c = _myCharacters[i];
                    final id = (c['id'] ?? c['_id'] ?? 0) as int;
                    final name = (c['name'] ?? '未命名').toString();
                    final selected = _selectedCharIds.contains(id);
                    return CheckboxListTile(
                      value: selected,
                      activeColor: _kPrimary,
                      title: Text(name),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedCharIds.add(id);
                          } else {
                            _selectedCharIds.remove(id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部切换 + 右上角自定义创建
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 剧情故事 | 开放故事 切换
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isPlot = true),
                    child: Text(
                      '剧情故事',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _isPlot ? FontWeight.bold : FontWeight.normal,
                        color: _isPlot ? _kPrimary : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => setState(() => _isPlot = false),
                    child: Text(
                      '开放故事',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: !_isPlot ? FontWeight.bold : FontWeight.normal,
                        color: !_isPlot ? _kPrimary : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
              // 自定义创建按钮（剧情故事禁用）
              TextButton(
                onPressed: _isPlot
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateStoryPage(
                              prefill: _ctrl.text,
                              selectedCharIds: _selectedCharIds.toList(),
                            ),
                          ),
                        );
                      },
                style: TextButton.styleFrom(
                  foregroundColor: _isPlot
                      ? Colors.grey[400]
                      : _kPrimary,
                ),
                child: Text(
                  '自定义创建',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isPlot ? Colors.grey[400] : _kPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // +参与角色
                  GestureDetector(
                    onTap: _showCharacterPicker,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add,
                              size: 18, color: _kPrimary),
                          const SizedBox(width: 6),
                          Text(
                            _selectedCharIds.isEmpty
                                ? '+ 参与角色'
                                : '已选 ${_selectedCharIds.length} 个角色',
                            style: const TextStyle(
                                color: _kPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: '输入你想构建的世界观',
                        hintStyle:
                            TextStyle(color: Color(0xFFBDBDBD), fontSize: 18),
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
                        onPressed: _openAiAssist,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('AI助手'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 快捷chip横滑
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _chips.length,
            itemBuilder: (context, i) {
              return Container(
                margin: const EdgeInsets.only(right: 10),
                child: ActionChip(
                  label: Text(_chips[i]),
                  onPressed: () => _ctrl.text = _chips[i],
                  backgroundColor: _kCard,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  labelStyle: const TextStyle(fontSize: 13),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
