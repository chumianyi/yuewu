import 'package:flutter/material.dart';
import '../api_service.dart';

const Color _kPrimary = Color(0xFFFFB6C1);
const Color _kBg = Color(0xFFFFF0F5);
const Color _kCard = Colors.white;

class _ChapterDraft {
  String name;
  String description;
  String backgroundPath;
  String openingLine;
  bool generatingBg;
  _ChapterDraft({
    this.name = '',
    this.description = '',
    this.backgroundPath = '',
    this.openingLine = '',
    this.generatingBg = false,
  });
}

class CreateStoryPage extends StatefulWidget {
  final String prefill;
  final List<String> selectedCharIds;
  const CreateStoryPage({
    super.key,
    this.prefill = '',
    this.selectedCharIds = const [],
  });

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final _nameCtrl = TextEditingController();
  final _userNameCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _globalPromptCtrl = TextEditingController();
  final _constraintCtrl = TextEditingController();

  List<dynamic> _myCharacters = [];
  final Set<String> _selectedCharIds = {};
  String? _openingCharId;
  bool _ends = false;
  bool _advanced = false;
  bool _loadingChars = false;
  bool _publishing = false;
  String? _coverPath;
  bool _generatingCover = false;

  final List<_ChapterDraft> _chapters = [_ChapterDraft()];

  @override
  void initState() {
    super.initState();
    if (widget.prefill.isNotEmpty) _contentCtrl.text = widget.prefill;
    _selectedCharIds.addAll(widget.selectedCharIds);
    _loadMyCharacters();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userNameCtrl.dispose();
    _contentCtrl.dispose();
    _globalPromptCtrl.dispose();
    _constraintCtrl.dispose();
    super.dispose();
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
            const Text('选择参与角色（仅自己的角色）',
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
                    final id = (c['id'] ?? c['_id'] ?? '').toString();
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
                            if (_openingCharId == id) _openingCharId = null;
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

  Future<void> _genCover() async {
    setState(() => _generatingCover = true);
    try {
      final prompt =
          'story cover illustration, ${_nameCtrl.text}, ${_contentCtrl.text}';
      final r = await ApiService().generatePortrait(prompt);
      _coverPath =
          (r['imageUrl'] ?? r['url'] ?? r['path'] ?? r['image'] ?? '').toString();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('封面生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingCover = false);
    }
  }

  Future<void> _genChapterBg(_ChapterDraft ch) async {
    setState(() => ch.generatingBg = true);
    try {
      final prompt =
          'chapter background illustration, ${ch.name}, ${ch.description}, ${_nameCtrl.text}';
      final r = await ApiService().generatePortrait(prompt);
      ch.backgroundPath =
          (r['imageUrl'] ?? r['url'] ?? r['path'] ?? r['image'] ?? '').toString();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('章节背景生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => ch.generatingBg = false);
    }
  }

  Future<void> _publish() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写故事名称')),
      );
      return;
    }
    setState(() => _publishing = true);
    try {
      await ApiService().createStory({
        'name': _nameCtrl.text.trim(),
        'description': _contentCtrl.text.trim(),
        'userName': _userNameCtrl.text.trim(),
        'characterIds': _selectedCharIds.toList(),
        'openingCharacterId': _openingCharId,
        'ended': _ends,
        'globalPrompt': _globalPromptCtrl.text.trim(),
        'constraint': _constraintCtrl.text.trim(),
        'cover': _coverPath ?? '',
        'chapters': _chapters
            .map((c) => {
                  'name': c.name,
                  'description': c.description,
                  'background': c.backgroundPath,
                  'openingLine': c.openingLine,
                })
            .toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('故事发布成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final openingCharName = _openingCharId == null
        ? '请选择'
        : (_myCharacters.firstWhere(
            (c) => '${c['id'] ?? c['_id']}' == _openingCharId,
            orElse: () => {},
          )['name'] ?? '请选择')
            .toString();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('创建故事',
            style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 封面
                _buildCover(),
                const SizedBox(height: 20),
                // 故事名称
                _label('故事名称'),
                _boxField(_nameCtrl, hint: '请填写故事名称'),
                const SizedBox(height: 16),
                // 用户名字（可选）
                _label('用户名字（可选）'),
                _boxField(_userNameCtrl, hint: '给故事里的你起个名字，如"旅人"；留空则AI自动称呼'),
                const SizedBox(height: 20),
                // 参与角色
                _label('参与角色（多选）'),
                GestureDetector(
                  onTap: _showCharacterPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people, size: 20, color: _kPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedCharIds.isEmpty
                                ? '+ 选择参与角色（仅自己的角色）'
                                : '已选 ${_selectedCharIds.length} 个角色',
                            style: TextStyle(
                              color: _selectedCharIds.isEmpty
                                  ? Colors.grey[500]
                                  : const Color(0xFF4A4A4A),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 开场角色 + 开场白
                _label('开场角色与开场白'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5F8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String?>(
                              value: _openingCharId,
                              underline: const SizedBox(),
                              hint: const Text('请选择开场角色',
                                  style: TextStyle(
                                      color: _kPrimary, fontSize: 13)),
                              items: _selectedCharIds.map((id) {
                                final c = _myCharacters.firstWhere(
                                  (c) => '${c['id'] ?? c['_id']}' == id,
                                  orElse: () => {},
                                );
                                return DropdownMenuItem(
                                  value: id,
                                  child: Text((c['name'] ?? id).toString(),
                                      style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _openingCharId = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: '开场白内容（开场角色说的第一句话）',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 故事内容
                _label('故事内容 / 世界观'),
                TextField(
                  controller: _contentCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: '描述你想构建的世界观，如人物关系、主题背景、玩法规则等',
                    filled: true,
                    fillColor: _kCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 章节列表
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('章节',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _chapters.add(_ChapterDraft())),
                      icon: const Icon(Icons.add, size: 18, color: _kPrimary),
                      label: const Text('添加章节',
                          style: TextStyle(color: _kPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._chapters.asMap().entries.map((e) =>
                    _buildChapterCard(e.key, e.value)),
                const SizedBox(height: 16),
                // 故事是否结束
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('故事是否会结束'),
                      Switch(
                        value: _ends,
                        activeColor: _kPrimary,
                        onChanged: (v) => setState(() => _ends = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 高级设定
                GestureDetector(
                  onTap: () => setState(() => _advanced = !_advanced),
                  child: Row(
                    children: [
                      const Text('全局设置',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Icon(_advanced
                          ? Icons.expand_less
                          : Icons.expand_more),
                    ],
                  ),
                ),
                if (_advanced) ...[
                  const SizedBox(height: 8),
                  const Text('全局提示词',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _globalPromptCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '全局AI提示词，影响整个故事的走向和风格',
                      filled: true,
                      fillColor: _kCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('约束词',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _constraintCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '约束AI不要做的事，如：不要出现暴力描写',
                      filled: true,
                      fillColor: _kCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 发布按钮
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: _publishing ? null : _publish,
                child: _publishing
                    ? const CircularProgressIndicator()
                    : const Text('发布故事',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _boxField(TextEditingController c, {String? hint}) => TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: _kCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );

  Widget _buildCover() {
    return GestureDetector(
      onTap: _generatingCover ? null : _genCover,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _generatingCover
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _coverPath != null && _coverPath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      ApiService().imageUrl(_coverPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderCover(),
                    ),
                  )
                : _placeholderCover(),
      ),
    );
  }

  Widget _placeholderCover() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 32, color: _kPrimary),
            SizedBox(height: 6),
            Text('点击生成故事封面',
                style: TextStyle(color: _kPrimary, fontSize: 13)),
          ],
        ),
      );

  Widget _buildChapterCard(int index, _ChapterDraft ch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('第 ${index + 1} 章',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_chapters.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.grey),
                  onPressed: () => setState(() => _chapters.removeAt(index)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 背景图
          GestureDetector(
            onTap: ch.generatingBg ? null : () => _genChapterBg(ch),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFFFF5F8),
              ),
              child: ch.generatingBg
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary))
                  : ch.backgroundPath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ApiService().imageUrl(ch.backgroundPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined,
                                  color: _kPrimary, size: 26),
                              SizedBox(height: 4),
                              Text('生成章节背景',
                                  style: TextStyle(
                                      color: _kPrimary, fontSize: 12)),
                            ],
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => ch.name = v,
            decoration: const InputDecoration(
              hintText: '章节名称',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => ch.description = v,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: '章节描述',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => ch.openingLine = v,
            decoration: const InputDecoration(
              hintText: '章节开场白',
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
