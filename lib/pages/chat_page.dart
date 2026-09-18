import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
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
  bool _historyLoading = true;

  String _model = 'glm-4.7-flash';
  static const Map<String, String> _modelLabels = {
    'glm-4.7-flash': '长文本',
    'Qwen3.5-4B': '普通',
    'Qwen3-8B': '细腻',
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (widget.characterId == null || widget.characterId!.isEmpty) {
      setState(() => _historyLoading = false);
      _addGreeting();
      return;
    }
    try {
      final token = await Api.token;
      final resp = await http.get(
        Uri.parse('${Api.baseUrl}/api/chat/history?characterId=${widget.characterId}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = data is List ? data : (data['list'] ?? data['messages'] ?? []);
        if (list is List && list.isNotEmpty) {
          for (final m in list) {
            _messages.add({
              'role': m['role']?.toString() ?? 'assistant',
              'content': m['content']?.toString() ?? '',
            });
          }
        } else {
          _addGreeting();
        }
      } else {
        _addGreeting();
      }
    } catch (_) {
      _addGreeting();
    } finally {
      if (mounted) {
        setState(() => _historyLoading = false);
      }
      _scrollToBottom();
    }
  }

  void _addGreeting() {
    if (widget.greeting != null && widget.greeting!.isNotEmpty && _messages.isEmpty) {
      _messages.add({'role': 'assistant', 'content': widget.greeting!});
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
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
        _messages.last['content'] = '出错了，请重试';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '选择回复模式',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ..._modelLabels.entries.map((e) {
                final selected = _model == e.key;
                return ListTile(
                  leading: Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected ? const Color(0xFFFF69B4) : Colors.grey,
                  ),
                  title: Text(e.value),
                  subtitle: Text(e.key, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  onTap: () {
                    setState(() => _model = e.key);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portraitUrl = Api.portraitUrl(widget.portrait);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen portrait background
          if (portraitUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: portraitUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.pink[50]),
              errorWidget: (_, __, ___) => Container(color: Colors.pink[50]),
            )
          else
            Container(color: Colors.pink[50]),
          // Semi-transparent overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.pink[50]!.withOpacity(0.9),
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
          // Content
          Column(
            children: [
              // Top bar with character name
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.characterName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 4),
                                ],
                              ),
                            ),
                            Text(
                              _modelLabels[_model] ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 2),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Model switch button
                      GestureDetector(
                        onTap: _showModelPicker,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tune, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _modelLabels[_model] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Chat messages
              Expanded(
                child: _historyLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final m = _messages[i];
                          final isUser = m['role'] == 'user';
                          return _buildMessageBubble(m['content'] ?? '', isUser);
                        },
                      ),
              ),
              // Input bar
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: '和${widget.characterName}聊天...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: const Color(0xFFFFF0F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _loading ? null : _send,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _loading
                                ? Colors.grey[300]
                                : const Color(0xFFFF69B4),
                            shape: BoxShape.circle,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    if (text.isEmpty && _loading) {
      return _buildTypingIndicator();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFFFF69B4)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                      widget.characterName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.pink[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final portraitUrl = Api.portraitUrl(widget.portrait);
    return ClipOval(
      child: portraitUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: portraitUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 36,
                height: 36,
                color: Colors.pink[100],
              ),
              errorWidget: (_, __, ___) => Container(
                width: 36,
                height: 36,
                color: Colors.pink[200],
                child: Center(
                  child: Text(
                    widget.characterName.isNotEmpty ? widget.characterName[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          : Container(
              width: 36,
              height: 36,
              color: Colors.pink[200],
              child: Center(
                child: Text(
                  widget.characterName.isNotEmpty ? widget.characterName[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(200),
                const SizedBox(width: 4),
                _dot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFFF69B4),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
