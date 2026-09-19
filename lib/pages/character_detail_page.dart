import 'package:flutter/material.dart';
import '../api_service.dart';

class CharacterDetailPage extends StatefulWidget {
  final int characterId;
  const CharacterDetailPage({super.key, required this.characterId});

  @override
  State<CharacterDetailPage> createState() => _CharacterDetailPageState();
}

class _CharacterDetailPageState extends State<CharacterDetailPage> {
  final ApiService _api = ApiService();
  final _pink = const Color(0xFFFFB6C1);
  final _commentCtrl = TextEditingController();

  Map<String, dynamic>? _detail;
  List<dynamic> _comments = [];
  bool _loading = true;
  bool _liking = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _api.getCharacterDetail(widget.characterId),
        _api.getCharacterComments(widget.characterId),
      ]);
      if (mounted) {
        setState(() {
          _detail = results[0] as Map<String, dynamic>;
          _comments = results[1] as List;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _name => (_detail?['name'] ?? '角色').toString();

  String _portraitUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.startsWith('http') ? path : '${_api.baseUrl}$path';
  }

  int get _likes =>
      (_detail?['likes'] ?? _detail?['likesCount'] ?? _detail?['likeCount'] ?? 0) as int;

  Future<void> _like() async {
    if (_liking) return;
    setState(() => _liking = true);
    try {
      await _api.likeCharacter(widget.characterId);
      if (mounted) {
        setState(() => _detail?['likes'] = (_likes) + 1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _api.commentCharacter(widget.characterId, text);
      _commentCtrl.clear();
      final list = await _api.getCharacterComments(widget.characterId);
      if (mounted) setState(() => _comments = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _report() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('举报这个角色'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: '请描述举报原因…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final reason = ctrl.text.trim();
              if (reason.isEmpty) return;
              try {
                await _api.reportCharacter(widget.characterId, reason);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已收到举报，我们会尽快处理')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('提交', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }

  void _startChat() {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'characterId': widget.characterId,
        'characterName': _name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final portrait = _detail?['portrait']?.toString();
    final url = _portraitUrl(portrait);
    final desc = (_detail?['description'] ?? _detail?['brief'] ?? '').toString();

    return Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _pink))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 480,
                  pinned: true,
                  backgroundColor: _pink,
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.flag_outlined),
                      tooltip: '举报',
                      onPressed: _report,
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: url.isNotEmpty
                        ? Image.network(url, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _name,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            _buildLikeButton(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          desc.isEmpty ? '这个角色还没有简介。' : desc,
                          style: const TextStyle(
                              color: Color(0xFF6B6B6B), fontSize: 14, height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _startChat,
                            icon: const Icon(Icons.chat),
                            label: const Text('开始聊天', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            const Text('评论',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text('${_comments.length}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (_comments.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('还没有评论，来说第一句吧',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildCommentTile(_comments[i]),
                      childCount: _comments.length,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendComment(),
                            decoration: const InputDecoration(
                              hintText: '友善评论，和TA打个招呼…',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: _pink),
                          onPressed: _sending ? null : _sendComment,
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLikeButton() {
    return Row(
      children: [
        IconButton(
          onPressed: _liking ? null : _like,
          icon: Icon(Icons.favorite, color: _pink, size: 30),
        ),
        Text('$_likes', style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> c) {
    final user = (c['username'] ?? c['userName'] ?? c['nickname'] ?? '匿名用户').toString();
    final content = (c['content'] ?? '').toString();
    final time = (c['createdAt'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _pink.withValues(alpha: 0.25),
            child: Text(
              user.isNotEmpty ? user[0] : '?',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(user, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (time.isNotEmpty)
                      Text(time.split('T').first,
                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFB6C1), Color(0xFFFFF0F5)],
        ),
      ),
      child: Center(
        child: Text(
          _name.isNotEmpty ? _name[0] : '?',
          style: const TextStyle(fontSize: 120, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
