import 'dart:ui';
import 'package:flutter/material.dart';
import 'api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<dynamic> _characters = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().getCharacters(1, 20);
      setState(() {
        _characters = res['data'] ?? res['characters'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFB6C1)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFFFB6C1)),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCharacters,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_characters.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Color(0xFFFFB6C1)),
            SizedBox(height: 16),
            Text('还没有角色，去创建一个吧', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemCount: _characters.length,
          itemBuilder: (_, i) => _CharacterCard(
            character: _characters[i],
            onTap: () => _openChat(_characters[i]),
          ),
        ),
        // 右侧圆点指示器
        Positioned(
          right: 8,
          top: MediaQuery.of(context).size.height * 0.4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_characters.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(vertical: 3),
                width: active ? 8 : 6,
                height: active ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? const Color(0xFFFFB6C1) : Colors.white54,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _openChat(Map<String, dynamic> character) {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'characterId': character['id'],
        'characterName': character['name'] ?? '',
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Map<String, dynamic> character;
  final VoidCallback onTap;

  const _CharacterCard({required this.character, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final portrait = character['portrait'] as String?;
    final name = character['name'] ?? '未知角色';
    final brief = character['brief'] ?? character['title'] ?? '';
    final description = character['description'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景：立绘或粉色渐变占位
            if (portrait != null && portrait.isNotEmpty)
              Image.network(
                portrait.startsWith('http') ? portrait : '${ApiService().baseUrl}$portrait',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),

            // 底部渐变遮罩
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.5, 0.75, 1.0],
                ),
              ),
            ),

            // 文字信息
            Positioned(
              left: 24,
              right: 80,
              bottom: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                    ),
                  ),
                  if (brief.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      brief,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFB6C1), Color(0xFFFFC0CB), Color(0xFFFFF0F5)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 120, color: Colors.white38),
      ),
    );
  }
}
