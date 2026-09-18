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
  final PageController _pageController = PageController();
  List<dynamic> _chars = [];
  bool _loading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
            )
          : _chars.isEmpty
              ? _buildEmpty()
              : _buildPageView(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.pink[200]),
          const SizedBox(height: 16),
          Text(
            '还没有角色',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '上下滑动浏览角色',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemCount: _chars.length,
          itemBuilder: (ctx, i) => _buildCharacterCard(_chars[i]),
        ),
        // Page indicator dots
        Positioned(
          right: 12,
          top: MediaQuery.of(context).padding.top + 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_chars.length, (i) {
              final active = i == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(vertical: 3),
                width: active ? 8 : 6,
                height: active ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? const Color(0xFFFF69B4) : Colors.pink[200]?.withOpacity(0.5),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard(dynamic ch) {
    final portrait = ch['portrait'];
    final name = ch['name'] ?? '';
    final desc = ch['description'] ?? '';

    return GestureDetector(
      onTap: () => _openChat(ch),
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: portrait != null && portrait.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: Api.portraitUrl(portrait),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.pink[50],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF69B4),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.pink[100],
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0] : '?',
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.pink[100],
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (ch['category'] != null && ch['category'].isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ch['category'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          desc,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.grey[700],
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(dynamic ch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          title: ch['name'] ?? '聊天',
          characterName: ch['name'] ?? '',
          portrait: ch['portrait'],
          characterId: ch['id']?.toString(),
          greeting: ch['greeting'],
        ),
      ),
    );
  }
}
