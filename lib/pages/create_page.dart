import 'package:flutter/material.dart';
import '../api.dart';

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('创作中心'),
          bottom: const TabBar(tabs: [
            Tab(text: '角色'),
            Tab(text: '故事'),
            Tab(text: 'AI创作'),
          ]),
        ),
        body: const TabBarView(children: [
          _CreateCharacterTab(),
          _CreateStoryTab(),
          _AICreateTab(),
        ]),
      ),
    );
  }
}

class _CreateCharacterTab extends StatefulWidget {
  const _CreateCharacterTab();

  @override
  State<_CreateCharacterTab> createState() => _CreateCharacterTabState();
}

class _CreateCharacterTabState extends State<_CreateCharacterTab> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _greeting = TextEditingController();
  final _system = TextEditingController();
  String? _portrait;
  bool _saving = false;

  Future<void> _generatePortrait() async {
    final prompt = _desc.text.isEmpty ? 'anime character portrait' : _desc.text;
    try {
      final r = await Api.generatePortrait('anime style, $prompt');
      setState(() => _portrait = r['url']);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _publish() async {
    if (_name.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写角色名')));
      return;
    }
    setState(() => _saving = true);
    try {
      await Api.createCharacter({
        'name': _name.text, 'description': _desc.text,
        'greeting': _greeting.text, 'systemPrompt': _system.text,
        'portrait': _portrait ?? '', 'category': '创作',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发布成功')));
        _name.clear(); _desc.clear(); _greeting.clear(); _system.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_portrait != null)
          Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(image: NetworkImage(Api.portraitUrl(_portrait)), fit: BoxFit.cover),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _generatePortrait,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('AI生成立绘'),
        ),
        const SizedBox(height: 16),
        TextField(controller: _name, decoration: const InputDecoration(labelText: '角色名', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _desc, maxLines: 2, decoration: const InputDecoration(labelText: '角色描述', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _greeting, decoration: const InputDecoration(labelText: '开场白', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _system, maxLines: 4, decoration: const InputDecoration(labelText: '角色设定（系统提示词）', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _publish,
          child: _saving ? const CircularProgressIndicator() : const Text('发布角色'),
        ),
      ],
    );
  }
}

class _CreateStoryTab extends StatefulWidget {
  const _CreateStoryTab();

  @override
  State<_CreateStoryTab> createState() => _CreateStoryTabState();
}

class _CreateStoryTabState extends State<_CreateStoryTab> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _narrator = TextEditingController();
  final _global = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_name.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Api.createStory({
        'name': _name.text, 'description': _desc.text,
        'narrator': _narrator.text, 'globalPrompt': _global.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('故事已保存')));
        _name.clear(); _desc.clear(); _narrator.clear(); _global.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: '故事名称', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _desc, maxLines: 2, decoration: const InputDecoration(labelText: '故事描述', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _narrator, decoration: const InputDecoration(labelText: '旁白风格', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _global, maxLines: 4, decoration: const InputDecoration(labelText: '全局提示词/约束', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        FilledButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('保存故事')),
      ],
    );
  }
}

class _AICreateTab extends StatefulWidget {
  const _AICreateTab();

  @override
  State<_AICreateTab> createState() => _AICreateTabState();
}

class _AICreateTabState extends State<_AICreateTab> {
  final _ctrl = TextEditingController();
  final _messages = <Map<String, String>>[];
  bool _loading = false;

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() { _messages.add({'role': 'user', 'content': t}); _ctrl.clear(); _loading = true; });
    try {
      final r = await Api.chat(model: 'detailed', messages: _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList());
      setState(() => _messages.add({'role': 'assistant', 'content': r['reply'] ?? ''}));
    } catch (e) {
      setState(() => _messages.add({'role': 'assistant', 'content': e.toString()}));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              final isUser = m['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(m['content'] ?? ''),
                ),
              );
            },
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: '和AI聊聊你的创意...', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
          ]),
        ),
      ],
    );
  }
}
