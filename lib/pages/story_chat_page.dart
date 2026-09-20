import 'package:flutter/material.dart';
import '../api_service.dart';

/// 多角色故事对话页面：用户发一条，所有参与角色轮流回复。
class StoryChatPage extends StatefulWidget {
  final String storyId;
  final String storyName;

  const StoryChatPage({super.key, required this.storyId, required this.storyName});

  @override
  State<StoryChatPage> createState() => _StoryChatPageState();
}

class _StoryChatPageState extends State<StoryChatPage> {
  final ApiService _api = ApiService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  /// 消息列表：每条 {role, content, character?}
  /// role=user / assistant / narrator
  final List<Map<String, String>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Map<String, dynamic>? _story;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await _api.getStory(widget.storyId);
      _story = s;
      // 开场白自动显示
      final opening = (s['opening'] ?? '').toString();
      if (opening.isNotEmpty) {
        _messages.add({'role': 'narrator', 'content': opening, 'character': '旁白'});
      }
      // 读取已保存的对话历史
      final history = await _api.getChatHistory(widget.storyId, null);
      for (final m in history) {
        _messages.add({
          'role': (m['role'] ?? 'user').toString(),
          'content': (m['content'] ?? '').toString(),
          if (m['character'] != null) 'character': m['character'].toString(),
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _sending = true;
    });
    _scrollToBottom();

    try {
      // 发给后端的 messages（去掉空内容）
      final reqMessages = _messages
          .where((m) => m['content']!.isNotEmpty)
          .map((m) => {'role': m['role']!, 'content': m['content']!})
          .toList();

      final res = await _api.storyChat(widget.storyId, reqMessages);

      if (res['blocked'] == true) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': (res['message'] ?? '你好，这个问题我无法回答').toString(),
            'character': '系统',
          });
        });
      } else {
        final replies = (res['replies'] as List? ?? []);
        for (final r in replies) {
          final m = r as Map;
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': (m['text'] ?? '').toString(),
              'character': (m['character'] ?? '角色').toString(),
            });
          });
        }
      }
      _scrollToBottom();
      _autoSave();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': '出错了: $e', 'character': '系统'});
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _autoSave() async {
    try {
      final saveMsgs = _messages
          .where((m) => m['content']!.isNotEmpty && m['role'] != 'narrator')
          .map((m) => {'role': m['role']!, 'content': m['content']!})
          .toList();
      await _api.saveChat(widget.storyId, null, saveMsgs, 'long');
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storyName.isNotEmpty ? widget.storyName : '故事'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9575CD)));
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _bubble(_messages[i]),
    );
  }

  Widget _bubble(Map<String, String> m) {
    final role = m['role'];
    final content = m['content'] ?? '';
    final charName = m['character'] ?? '';

    if (role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            color: const Color(0xFF9575CD),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(content, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
        ),
      );
    }

    if (role == 'narrator') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCE93D8), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎭 故事开场', style: TextStyle(fontSize: 12, color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF4A4A4A), height: 1.6, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    // assistant (多角色)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFCE93D8),
            child: Text(
              charName.isNotEmpty ? charName[0] : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(charName, style: const TextStyle(fontSize: 12, color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE1BEE7)),
                  ),
                  child: Text(content, style: const TextStyle(fontSize: 15, color: Color(0xFF4A4A4A), height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: '对故事里的角色说点什么...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _sending ? Colors.grey : const Color(0xFF9575CD),
                  shape: BoxShape.circle,
                ),
                child: Icon(_sending ? Icons.stop : Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
