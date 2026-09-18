import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api.dart';

class ChatPage extends StatefulWidget {
  final String title;
  final String? portrait;
  final String? characterId;
  final String? greeting;
  final String characterName;

  const ChatPage({
    super.key,
    required this.title,
    this.portrait,
    this.characterId,
    this.greeting,
    required this.characterName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  String _model = 'normal';
  bool _showedBreak = false;

  @override
  void initState() {
    super.initState();
    if (widget.greeting != null && widget.greeting!.isNotEmpty) {
      _messages.add({'role': 'assistant', 'content': widget.greeting!});
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _ctrl.clear();
      _loading = true;
    });
    _scrollToBottom();
    try {
      final history = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
      final r = await Api.chat(
        model: _model,
        messages: history,
        characterId: widget.characterId,
      );
      setState(() {
        _messages.add({'role': 'assistant', 'content': r['reply'] ?? ''});
      });
      if (r['break_reminder'] == true && !_showedBreak) {
        _showedBreak = true;
        if (mounted) _showBreakDialog();
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': e.toString().replaceFirst('Exception: ', '')});
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _showBreakDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('注意休息'),
        content: const Text('你已经和AI聊了12小时啦，记得休息一下眼睛和身体哦~'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('我不玩了')),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('继续使用')),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.portrait != null && widget.portrait!.isNotEmpty)
              CircleAvatar(
                radius: 16,
                backgroundImage: CachedNetworkImageProvider(Api.portraitUrl(widget.portrait)),
              )
            else
              CircleAvatar(
                radius: 16,
                child: Text(widget.characterName.isNotEmpty ? widget.characterName[0] : '?'),
              ),
            const SizedBox(width: 8),
            Text(widget.title),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ChoiceChip(
              label: Text(_model == 'normal' ? '普通' : '细腻'),
              selected: _model == 'detailed',
              onSelected: (v) => setState(() => _model = v ? 'detailed' : 'normal'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return _bubble(m['content']!, isUser);
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(String text, bool isUser) {
    final url = Api.portraitUrl(widget.portrait);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && url.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(radius: 18, backgroundImage: CachedNetworkImageProvider(url)),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(text, style: const TextStyle(fontSize: 15)),
            ),
          ),
          if (isUser) const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  hintText: '说点什么...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _loading ? null : _send,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
