import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../api_service.dart';

enum ChatMode { long, normal, delicate, extreme }

class ChatPage extends StatefulWidget {
  final int characterId;
  final int? storyId;
  final String characterName;

  const ChatPage({
    super.key,
    required this.characterId,
    this.storyId,
    required this.characterName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _api = ApiService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  final List<_StoryChoice> _choices = [];
  bool _loadingHistory = true;
  bool _streaming = false;
  ChatMode _mode = ChatMode.normal;
  String? _currentModel;
  Map<String, dynamic>? _characterDetail;
  bool _restShowed = false;

  // TTS 播放
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingIndex;

  // 录音
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadCharacterDetail(),
      _loadHistory(),
    ]);
    if (mounted) setState(() => _loadingHistory = false);
  }

  Future<void> _loadCharacterDetail() async {
    try {
      final res = await _api.getCharacterDetail(widget.characterId);
      if (mounted) {
        setState(() => _characterDetail = res);
        _currentModel = res['model'] ?? 'deepseek-chat';
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _api.getChatHistory(widget.characterId, widget.storyId);
      if (history.isNotEmpty) {
        setState(() {
          for (final item in history) {
            _messages.add({
              'role': item['role'] ?? 'user',
              'content': item['content'] ?? '',
            });
          }
        });
      }
    } catch (_) {}
  }

  String get _modelForMode {
    switch (_mode) {
      case ChatMode.long:
        return 'deepseek-reasoner';
      case ChatMode.normal:
        return 'deepseek-chat';
      case ChatMode.delicate:
        return 'deepseek-v3';
      case ChatMode.extreme:
        return 'extreme';
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _streaming) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _messages.add({'role': 'assistant', 'content': ''});
      _streaming = true;
      _choices.clear();
    });
    _scrollToBottom();

    try {
      final stream = _api.chatStream(
        _modelForMode,
        _messages.sublist(0, _messages.length - 1).map((m) => Map<String, String>.from(m)).toList(),
        widget.characterId,
        widget.storyId,
      );

      final buffer = StringBuffer();
      await for (final chunk in stream) {
        buffer.write(chunk);
        if (mounted) {
          setState(() {
            _messages.last['content'] = buffer.toString();
          });
          _scrollToBottom();
        }
      }

      // 检测剧情模式选项
      _parseStoryChoices(buffer.toString());

      // 自动保存
      _autoSave();
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.last['content'] = '出错了: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _streaming = false);
    }
  }

  void _parseStoryChoices(String content) {
    if (widget.storyId == null) return;
    final regex = RegExp(r'【选项[：:](.+?)】', dotAll: true);
    final match = regex.firstMatch(content);
    if (match != null) {
      final options = match.group(1)!.split(RegExp(r'[、，,\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      setState(() {
        _choices
          ..clear()
          ..addAll(options.map((o) => _StoryChoice(label: o)));
      });
    }
  }

  Future<void> _selectChoice(_StoryChoice choice) async {
    setState(() {
      _messages.add({'role': 'user', 'content': choice.label});
      _choices.clear();
      _streaming = true;
    });
    _scrollToBottom();

    try {
      final res = await _api.storyChoice(widget.storyId!, choice.label);
      final reply = res['reply'] ?? res['content'] ?? '';
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
      _parseStoryChoices(reply);
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': '出错了: $e'});
      });
    } finally {
      if (mounted) setState(() => _streaming = false);
    }
  }

  Future<void> _autoSave() async {
    try {
      await _api.saveChat(
        widget.characterId,
        widget.storyId,
        _messages.where((m) => m['content']!.isNotEmpty).toList(),
        _modelForMode,
      );
    } catch (_) {}
  }

  // ── TTS 朗读 ──────────────────────────────────────────

  Future<void> _playTts(String text, int index) async {
    // 点击正在播放的 → 停止
    if (_playingIndex == index) {
      await _audioPlayer.stop();
      setState(() => _playingIndex = null);
      return;
    }
    try {
      setState(() => _playingIndex = index);
      final res = await _api.tts(text, 'default');
      final url = res['url'] ?? res['audioUrl'] ?? res['data'];
      if (url != null) {
        await _audioPlayer.play(UrlSource(url.toString()));
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _playingIndex = null);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _playingIndex = null);
    }
  }

  // ── ASR 语音输入 ──────────────────────────────────────

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/yuewu_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path,
      );
      setState(() => _recording = true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (path == null) return;
    try {
      final res = await _api.asr(File(path));
      final text = res['text'] ?? res['result'] ?? '';
      if (text.isNotEmpty) {
        setState(() {
          _inputCtrl.text = text;
          _inputCtrl.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('语音识别失败')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showRestDialogIfNeeded() {
    if (_restShowed) return;
    final hour = DateTime.now().hour;
    if (hour >= 2 && hour < 6) {
      _restShowed = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('夜深了'),
          content: const Text('已经很晚了，注意休息哦～\n明天再继续聊天吧！'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('继续聊天'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final portrait = _characterDetail?['portrait'] as String?;

    return Scaffold(
      body: Stack(
        children: [
          // 全屏立绘背景
          if (portrait != null && portrait.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                portrait.startsWith('http') ? portrait : '${_api.baseUrl}$portrait',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFB6C1), Color(0xFFFFF0F5)],
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFB6C1), Color(0xFFFFF0F5)],
                  ),
                ),
              ),
            ),

          // 渐变遮罩
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildChatList()),
              if (_choices.isNotEmpty) _buildChoiceBar(),
              _buildInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                widget.characterName.isNotEmpty ? widget.characterName[0] : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.characterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _streaming ? '正在输入...' : '在线',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 模式切换
            Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: PopupMenuButton<ChatMode>(
                initialValue: _mode,
                color: const Color(0xFFFFF0F5),
                onSelected: (m) => setState(() => _mode = m),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: ChatMode.long, child: Text('长文本')),
                  const PopupMenuItem(value: ChatMode.normal, child: Text('普通')),
                  const PopupMenuItem(value: ChatMode.delicate, child: Text('细腻')),
                  const PopupMenuItem(value: ChatMode.extreme, child: Row(children: [Icon(Icons.bolt, size: 16, color: Color(0xFFFFB6C1)), SizedBox(width: 8), Text('极致 (Xing4.0-29B)')])),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text('模式', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (_loadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFB6C1)),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white30,
              child: Text(
                widget.characterName.isNotEmpty ? widget.characterName[0] : '?',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '和${widget.characterName}开始对话吧',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i], i),
    );
  }

  Widget _buildBubble(Map<String, String> msg, int index) {
    final isUser = msg['role'] == 'user';
    final content = msg['content'] ?? '';
    final isLast = index == _messages.length - 1;
    final isStreaming = _streaming && isLast && !isUser && content.isEmpty;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB6C1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(content, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white54,
            child: Text(
              widget.characterName.isNotEmpty ? widget.characterName[0] : '?',
              style: const TextStyle(color: Color(0xFFFFB6C1), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isStreaming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB6C1)),
                        )
                      : Text(
                          content,
                          style: const TextStyle(color: Color(0xFF4A4A4A), fontSize: 15, height: 1.5),
                        ),
                ),
                // 朗读按钮
                if (!isStreaming && content.isNotEmpty)
                  GestureDetector(
                    onTap: () => _playTts(content, index),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      child: Icon(
                        _playingIndex == index ? Icons.volume_up : Icons.volume_up_outlined,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withValues(alpha: 0.1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _choices.map((c) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(c.label),
                backgroundColor: const Color(0xFFFFB6C1),
                labelStyle: const TextStyle(color: Colors.white),
                onPressed: () => _selectChoice(c),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: '说点什么...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 麦克风按钮：按住录音 → 松开闭识别
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _recording ? Colors.redAccent : Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _recording ? Icons.mic : Icons.mic_none,
                  color: _recording ? Colors.white : const Color(0xFFFFB6C1),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _streaming ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _streaming ? Colors.grey : const Color(0xFFFFB6C1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _streaming ? Icons.stop : Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryChoice {
  final String label;
  _StoryChoice({required this.label});
}
