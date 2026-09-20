import 'package:flutter/material.dart';
import '../api_service.dart';

const Color _kPrimary = Color(0xFFFFB6C1);
const Color _kBg = Color(0xFFFFF0F5);
const Color _kCard = Colors.white;

class InteractivePage extends StatefulWidget {
  const InteractivePage({super.key});

  @override
  State<InteractivePage> createState() => _InteractivePageState();
}

class _InteractivePageState extends State<InteractivePage> {
  final ApiService _api = ApiService();
  final _ctrl = TextEditingController();
  bool _creating = false;
  List<dynamic> _drafts = [];
  List<dynamic> _published = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    try {
      final all = await _api.interactiveList();
      _drafts = all.where((w) => w['published'] != true).toList();
      _published = all.where((w) => w['published'] == true).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先描述你想要的互动剧')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final res = await _api.interactiveCreate(prompt);
      if (!mounted) return;
      _ctrl.clear();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InteractivePlayPage(
            appId: res['appId'].toString(),
            title: res['title']?.toString() ?? '互动剧',
            initialScene: res['scene']?.toString() ?? '',
            initialChoices: (res['choices'] as List?)?.map((e) => e.toString()).toList() ?? const [],
          ),
        ),
      );
      _loadList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _openItem(dynamic w) async {
    final detail = await _api.interactiveGet(w['id'].toString());
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InteractivePlayPage(
          appId: w['id'].toString(),
          title: detail['title']?.toString() ?? '互动剧',
          initialScene: detail['scene']?.toString() ?? '',
          initialChoices: (detail['choices'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        ),
      ),
    ).then((_) => _loadList());
  }

  Future<void> _deleteItem(dynamic w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除互动剧'),
        content: Text('确定删除「${w['title']}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.interactiveDelete(w['id'].toString());
      _loadList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  Widget _buildItem(dynamic w, {required bool isDraft}) {
    return Card(
      color: _kCard,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: w['cover'] != null && w['cover'].toString().isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(ApiService().imageUrl(w['cover'].toString()),
                    width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.auto_stories, color: _kPrimary, size: 32)),
              )
            : const Icon(Icons.auto_stories, color: _kPrimary, size: 32),
        title: Text(w['title']?.toString() ?? '互动剧'),
        subtitle: Text(
          isDraft ? '草稿 · ${w['scene']?.toString() ?? ''}' : '已发布 · ${w['scene']?.toString() ?? ''}',
          maxLines: 2, overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: () => _deleteItem(w),
        ),
        onTap: () => _openItem(w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _ctrl,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: '描述你的互动剧，如：古风仙侠，主角踏入修仙宗门',
                      border: InputBorder.none,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _creating ? null : _create,
                      icon: _creating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(_creating ? 'AI创作中' : '一键生成互动剧'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                : RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: _loadList,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        if (_drafts.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('草稿箱', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ..._drafts.map((w) => _buildItem(w, isDraft: true)),
                        ],
                        if (_published.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('已发布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          ..._published.map((w) => _buildItem(w, isDraft: false)),
                        ],
                        if (_drafts.isEmpty && _published.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: Text('还没有作品，快来创作一部吧', style: TextStyle(color: Colors.grey))),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class InteractivePlayPage extends StatefulWidget {
  final String appId;
  final String title;
  final String initialScene;
  final List<String> initialChoices;

  const InteractivePlayPage({
    super.key,
    required this.appId,
    required this.title,
    required this.initialScene,
    required this.initialChoices,
  });

  @override
  State<InteractivePlayPage> createState() => _InteractivePlayPageState();
}

class _InteractivePlayPageState extends State<InteractivePlayPage> {
  final ApiService _api = ApiService();
  final List<_SceneLine> _lines = [];
  List<String> _choices = [];
  bool _loading = false;
  bool _ended = false;
  bool _imageToggle = false;
  bool _published = false;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _lines.add(_SceneLine(text: widget.initialScene));
    _choices = List.of(widget.initialChoices);
  }

  Future<void> _choose(String choice) async {
    setState(() {
      _lines.add(_SceneLine(text: choice, isChoice: true));
      _choices = [];
      _loading = true;
    });
    try {
      final res = await _api.interactiveChoice(widget.appId, choice);
      if (!mounted) return;
      setState(() {
        _lines.add(_SceneLine(text: res['scene']?.toString() ?? ''));
        _choices = (res['choices'] as List?)?.map((e) => e.toString()).toList() ?? [];
        _ended = res['end'] == true;
      });
    } catch (e) {
      if (mounted) setState(() => _lines.add(_SceneLine(text: '出错了: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      await _api.interactivePublish(widget.appId);
      if (!mounted) return;
      setState(() => _published = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已发布到主页')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败: $e')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // 图片开关
          Row(
            children: [
              const Icon(Icons.image, size: 18, color: Colors.grey),
              Switch(
                value: _imageToggle,
                activeColor: _kPrimary,
                onChanged: (v) => setState(() => _imageToggle = v),
              ),
            ],
          ),
          // 发布按钮
          if (!_published)
            TextButton.icon(
              onPressed: _publishing ? null : _publish,
              icon: _publishing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                  : const Icon(Icons.publish, size: 18),
              label: const Text('发布', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.bold)),
            ),
          if (_published)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _lines.length,
              itemBuilder: (_, i) {
                final line = _lines[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    line.text,
                    style: TextStyle(
                      fontSize: 16, height: 1.6,
                      fontStyle: line.isChoice ? FontStyle.italic : FontStyle.normal,
                      fontWeight: line.isChoice ? FontWeight.w600 : FontWeight.normal,
                      color: line.isChoice ? _kPrimary : const Color(0xFF4A4A4A),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: _kPrimary))
          else if (_ended)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('—— 剧情已结束 ——', style: TextStyle(color: Colors.grey, fontSize: 15)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _choices
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _kPrimary, foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () => _choose(c),
                              child: Text(c),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SceneLine {
  final String text;
  final bool isChoice;
  _SceneLine({required this.text, this.isChoice = false});
}
