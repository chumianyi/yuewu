import 'package:flutter/material.dart';
import '../api_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ApiService _api = ApiService();
  final _pink = const Color(0xFFFFB6C1);

  List<dynamic> _convs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getMyStories(),
        _api.getMyCharacters(),
      ]);
      if (mounted) {
        setState(() {
          _convs = [...results[0], ...results[1]];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final now = DateTime.now();
    final local = dt.toLocal();
    String hh(int n) => n.toString().padLeft(2, '0');
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return '${hh(local.hour)}:${hh(local.minute)}';
    }
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(local.year, local.month, local.day))
        .inDays;
    if (diff == 1) return '昨天 ${hh(local.hour)}:${hh(local.minute)}';
    if (diff < 7) return '$diff天前';
    return '${local.month}-${local.day}';
  }

  String _url(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.startsWith('http') ? path : '${_api.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息'), centerTitle: true),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _pink))
          : RefreshIndicator(
              color: _pink,
              onRefresh: _load,
              child: _convs.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: _pink.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chat_bubble_outline, size: 44, color: _pink),
                              ),
                              const SizedBox(height: 20),
                              const Text('还没有聊天记录',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              const Text('去认识一位新伙伴，开始第一句话吧',
                                  style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _convs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                      itemBuilder: (_, i) => _buildTile(_convs[i]),
                    ),
            ),
    );
  }

  Widget _buildTile(Map<String, dynamic> item) {
    final name = (item['characterName'] ?? item['name'] ?? '对话').toString();
    final lastMsg = (item['lastMessage'] ?? item['last_message'] ?? '').toString();
    final time = _fmtTime(
        (item['updatedAt'] ?? item['createdAt'] ?? item['updated_at'] ?? '').toString());
    final portrait = item['portrait']?.toString();
    final url = _url(portrait);
    final cid = item['characterId'] ?? item['id'];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: _pink.withValues(alpha: 0.2),
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        child: url.isEmpty
            ? Text(name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            : null,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(
        lastMsg.isEmpty ? '开始和TA聊天吧' : lastMsg,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: lastMsg.isEmpty ? Colors.grey[400] : Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: time.isEmpty
          ? null
          : Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      onTap: () => Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'characterId': cid,
          'characterName': name,
          'storyId': item['storyId'],
        },
      ),
    );
  }
}
