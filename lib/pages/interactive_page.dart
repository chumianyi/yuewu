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
  List<dynamic> _works = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    try {
      _works = await _api.interactiveList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(24),
              ),
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
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(_creating ? 'AI创作中' : 'AI生成互动剧'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: const Text('我的互动剧',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                : _works.isEmpty
                    ? const Center(
                        child: Text('还没有作品，快来创作一部吧',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _works.length,
                        itemBuilder: (_, i) {
                          final w = _works[i];
                          return Card(
                            color: _kCard,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: const Icon(Icons.auto_stories, color: _kPrimary),
                              title: Text(w['title']?.toString() ?? '互动剧'),
                              subtitle: Text(
                                w['scene']?.toString() ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                final detail = await _api.interactiveGet(w['id'].toString());
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InteractivePlayPage(
                                      appId: w['id'].toString(),
                                      title: detail['title']?.toString() ?? '互动剧',
                                      initialScene: detail['scene']?.toString() ?? '',
                                      initialChoices: (detail['choices'] as List?)
                                              ?.map((e) => e.toString())
                                              .toList() ??
                                          const [],
                                    ),
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
        _choices =
            (res['choices'] as List?)?.map((e) => e.toString()).toList() ?? [];
        _ended = res['end'] == true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _lines.add(_SceneLine(text: '出错了: $e'));
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                      fontSize: 16,
                      height: 1.6,
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: _kPrimary),
            )
          else if (_ended)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('—— 剧情已结束 ——',
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
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
                                backgroundColor: _kPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
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
