import 'package:flutter/material.dart';
import '../api_service.dart';

class StoryDetailPage extends StatefulWidget {
  final String storyId;
  final String characterId;

  const StoryDetailPage({
    super.key,
    required this.storyId,
    required this.characterId,
  });

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = await _api.getChatHistory(widget.characterId, widget.storyId);
      if (mounted) {
        setState(() {
          _detail = {'messages': history};
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('剧情故事')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB6C1)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: (_detail?['messages'] as List?)?.length ?? 0,
              itemBuilder: (_, i) {
                final msg = (_detail!['messages'] as List)[i];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFFFB6C1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: TextStyle(color: isUser ? Colors.white : const Color(0xFF4A4A4A), height: 1.5),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFB6C1),
        icon: const Icon(Icons.chat, color: Colors.white),
        label: Text('继续对话', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'characterId': widget.characterId,
            'storyId': widget.storyId,
          },
        ),
      ),
    );
  }
}
