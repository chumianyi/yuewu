import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _chars = [];
  bool _loading = true;
  final _controller = PageController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.getCharacters(limit: 50);
      setState(() {
        _chars = r['list'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chars.isEmpty
              ? _empty()
              : PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  itemCount: _chars.length,
                  itemBuilder: (ctx, i) => _card(_chars[i]),
                ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('还没有角色，去创作一个吧'),
          const SizedBox(height: 8),
          FilledButton(onPressed: () {}, child: const Text('去创作')),
        ],
      ),
    );
  }

  Widget _card(dynamic ch) {
    final url = Api.portraitUrl(ch['portrait']);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(
        title: ch['name'] ?? '聊天',
        characterName: ch['name'] ?? '',
        portrait: ch['portrait'],
        characterId: ch['id'],
        greeting: ch['greeting'],
      ))),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              url.isNotEmpty
                  ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFFFB6C1),
                      child: Center(child: Text(ch['name']?[0] ?? '?', style: const TextStyle(fontSize: 80, color: Colors.white))),
                    ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ch['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(ch['description'] ?? '', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
