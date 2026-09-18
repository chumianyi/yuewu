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
  bool _showKeyboard = false;

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
      _messages.add({'role': 'assistant', 'content': ''});
    });
    _scrollToBottom();
    try {
      final history = _messages
          .where((m) => m['content']!.isNotEmpty)
          .map((m) => {'role': m['role']!, 'content': m['content']!})
          .toList();
      final stream = Api.chatStream(
        model: _model,
        messages: history,
        characterId: widget.characterId,
      );
      await for (final delta in stream) {
        setState(() {
          _messages.last['content'] = (_messages.last['content'] ?? '') + delta;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.last['content'] = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final portraitUrl = Api.portraitUrl(widget.portrait);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen portrait background
          if (portraitUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: portraitUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey[900]),
              errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
            )
          else
            Container(color: Colors.grey[900]),
          // Gradient overlay at bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Chat messages area
                Expanded(
                  flex: 4,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = _messages[i];
                      final isUser = m['role'] == 'user';
                      return _bubble(m['content']!, isUser);
                    },
                  ),
                ),
                // Character info bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.characterName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('@user', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          ],
                        ),
                      ),
                      _iconBtn(Icons.favorite, '2316'),
                      _iconBtn(Icons.share, '6'),
                      _iconBtn(Icons.comment, '98'),
                      _iconBtn(Icons.history, '历史'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Input bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _showKeyboard ? _keyboardInput() : _voiceInput(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _bubble(String text, bool isUser) {
    if (text.isEmpty && _loading) return const SizedBox.shrink();
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.withOpacity(0.8) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }

  Widget _voiceInput() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text('按住说话', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard, color: Colors.white),
            onPressed: () => setState(() => _showKeyboard = true),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _keyboardInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '说点什么...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _loading ? null : _send,
          icon: const Icon(Icons.send),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_voice, color: Colors.white),
          onPressed: () => setState(() => _showKeyboard = false),
        ),
      ],
    );
  }
}
