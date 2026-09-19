import 'package:flutter/material.dart';
import '../api_service.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final ApiService _api = ApiService();
  List<dynamic> _characters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.getCharacters(1, 50);
      if (mounted) {
        setState(() {
          _characters = res['list'] ?? res['data'] ?? res['characters'] ?? [];
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
      appBar: AppBar(title: const Text('伙伴')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB6C1)))
          : RefreshIndicator(
              color: const Color(0xFFFFB6C1),
              onRefresh: _load,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _characters.length,
                itemBuilder: (_, i) => _buildCard(_characters[i]),
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final portrait = c['portrait'] as String?;
    final name = c['name'] ?? '未知';
    final brief = c['brief'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/character_detail',
        arguments: {'characterId': c['id']},
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (portrait != null && portrait.isNotEmpty)
                Image.network(
                  _api.imageUrl(portrait),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              else
                _placeholder(),
              Positioned(
                left: 12, right: 12, bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
                    if (brief.isNotEmpty)
                      Text(brief, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFB6C1), Color(0xFFFFF0F5)],
      ),
    ),
    child: const Center(child: Icon(Icons.person, size: 48, color: Colors.white38)),
  );
}
