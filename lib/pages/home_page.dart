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
  int _cardIndex = 0;

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
      appBar: AppBar(title: const Text('发现伙伴'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chars.isEmpty
              ? _empty()
              : _buildCardSwiper(),
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

  Widget _buildCardSwiper() {
    final ch = _chars[_cardIndex];
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _openChat(ch),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ch['portrait'] != null && ch['portrait'].isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: Api.portraitUrl(ch['portrait']),
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(color: Colors.purple[100]),
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Center(
                              child: Text(ch['name']?[0] ?? '?', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold)),
                            ),
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.favorite, color: Colors.pinkAccent, size: 16),
                                const SizedBox(width: 4),
                                Text('${ch['likes'] ?? 0}', style: const TextStyle(color: Colors.white70)),
                                const SizedBox(width: 16),
                                Chip(label: Text(ch['category'] ?? ''), labelStyle: const TextStyle(fontSize: 12), padding: EdgeInsets.zero),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton.filledTonal(
                iconSize: 32,
                onPressed: _cardIndex > 0 ? () => setState(() => _cardIndex--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton.filled(
                iconSize: 36,
                onPressed: () => _openChat(ch),
                icon: const Icon(Icons.chat),
              ),
              IconButton.filledTonal(
                iconSize: 32,
                onPressed: _cardIndex < _chars.length - 1 ? () => setState(() => _cardIndex++) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openChat(dynamic ch) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(
      title: ch['name'] ?? '聊天',
      characterName: ch['name'] ?? '',
      portrait: ch['portrait'],
      characterId: ch['id'],
      greeting: ch['greeting'],
    )));
  }
}
