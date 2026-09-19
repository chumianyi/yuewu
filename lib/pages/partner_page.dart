import 'package:flutter/material.dart';
import 'api_service.dart';

class PartnerPage extends StatefulWidget {
  const PartnerPage({super.key});

  @override
  State<PartnerPage> createState() => _PartnerPageState();
}

class _PartnerPageState extends State<PartnerPage> {
  final ApiService _api = ApiService();
  final _pink = const Color(0xFFFFB6C1);

  Map<String, dynamic> _partner = {
    'name': '悟悟',
    'brief': '你的专属 AI 伙伴，随时陪伴你聊天。',
    'description': '你的专属 AI 伙伴，随时陪伴你聊天。',
    'portrait': null,
    'greeting': '你好呀，我是悟悟，今天想聊点什么？',
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _api.getPartner();
      if (mounted && p.isNotEmpty) {
        setState(() => _partner = {..._partner, ...p});
      }
    } catch (_) {
      // 接口不可用时保持默认「悟悟」
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _name => (_partner['name'] ?? '悟悟').toString();
  String get _intro =>
      (_partner['brief'] ?? _partner['description'] ?? '你的专属 AI 伙伴').toString();
  int? get _characterId =>
      (_partner['characterId'] ?? _partner['id']) is int
          ? (_partner['characterId'] ?? _partner['id']) as int
          : int.tryParse('${_partner['characterId'] ?? _partner['id'] ?? ''}');

  String _portraitUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.startsWith('http') ? path : '${_api.baseUrl}$path';
  }

  void _openChat() {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {'characterId': _characterId, 'characterName': _name},
    );
  }

  @override
  Widget build(BuildContext context) {
    final portrait = _partner['portrait']?.toString();
    final url = _portraitUrl(portrait);
    return Scaffold(
      appBar: AppBar(title: const Text('伙伴'), centerTitle: true),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _pink))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _openChat,
                          child: Hero(
                            tag: 'partner_$_name',
                            child: Container(
                              height: 420,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: _pink.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (url.isNotEmpty)
                                      Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _placeholder(),
                                      )
                                    else
                                      _placeholder(),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.55),
                                          ],
                                          stops: const [0.6, 1.0],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 20,
                                      right: 20,
                                      bottom: 20,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _intro,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _openChat,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('开始聊天', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _pink,
                              side: BorderSide(color: _pink),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _showSwitchSheet,
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('更换伙伴', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
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
          _name.isNotEmpty ? _name[0] : '悟',
          style: const TextStyle(fontSize: 96, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _showSwitchSheet() async {
    List<dynamic> mine = [];
    bool loading = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          if (loading) {
            _api.getMyCharacters().then((list) {
              mine = list;
              setSheet(() => loading = false);
            }).catchError((_) {
              setSheet(() => loading = false);
            });
          }
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                const Text('选择你的伙伴', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (loading)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: _pink),
                  )
                else if (mine.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('你还没有创建角色，先去创作一个吧',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...mine.map((c) {
                    final name = (c['name'] ?? '角色').toString();
                    final portrait = c['portrait']?.toString();
                    final url = _portraitUrl(portrait);
                    final isCurrent = _characterId == c['id'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _pink.withValues(alpha: 0.2),
                        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
                        child: url.isEmpty
                            ? Text(name.isNotEmpty ? name[0] : '?',
                                style: const TextStyle(color: Colors.white))
                            : null,
                      ),
                      title: Text(name),
                      trailing: isCurrent
                          ? Icon(Icons.check_circle, color: _pink)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await _api.updatePartner(c['id'] as int);
                          await _load();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
