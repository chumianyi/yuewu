import 'package:flutter/material.dart';
import '../api_service.dart';
import '../l10n.dart';
import 'interactive_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  final PageController _pageController = PageController();
  final TextEditingController _searchCtrl = TextEditingController();
  int _currentPage = 0;
  List<dynamic> _characters = [];
  List<dynamic> _interactive = [];
  List<dynamic> _searchChars = [];
  bool _loading = true;
  bool _searching = false;
  String? _query;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _pageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    if (_query == null || _query!.isEmpty) _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService().getRandomCharacters(10),
        ApiService().interactivePublished(),
      ]);
      setState(() {
        _characters = results[0];
        _interactive = results[1];
        _loading = false;
        _currentPage = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _query = null;
        _searching = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _query = q;
    });
    try {
      final res = await ApiService().search(q);
      setState(() {
        _searchChars = (res['characters'] as List? ?? []);
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _query = null;
      _searchChars = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocale.instance;
    final searching = _query != null && _query!.isNotEmpty;
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _doSearch,
                      decoration: InputDecoration(
                        hintText: l10n.t('搜索角色...'),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFFF69B4)),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _clearSearch();
                                },
                              )
                            : null,
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.t('换一批'),
                    icon: const Icon(Icons.shuffle, color: Color(0xFFFF69B4)),
                    onPressed: _loading ? null : _loadData,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: searching ? _buildSearchResults(l10n) : _buildFeed(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(AppLocale l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFB6C1)));
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
            ElevatedButton(onPressed: _loadData, child: Text(l10n.t('重试'))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFFF69B4),
      onRefresh: _loadData,
      child: Column(
        children: [
          // 互动剧横滑
          if (_interactive.isNotEmpty) _buildInteractiveSection(l10n),
          Expanded(
            child: _characters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: Color(0xFFFFB6C1)),
                        const SizedBox(height: 16),
                        Text(l10n.t('暂无结果'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        physics: const AlwaysScrollableScrollPhysics(),
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemCount: _characters.length,
                        itemBuilder: (_, i) => _CharacterCard(
                          character: _characters[i],
                          onTap: () => _openChat(_characters[i]),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: MediaQuery.of(context).size.height * 0.35,
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
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveSection(AppLocale l10n) {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('热门互动剧', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple.shade300)),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _interactive.length,
              itemBuilder: (_, i) {
                final item = _interactive[i];
                final cover = item['cover']?.toString() ?? '';
                return GestureDetector(
                  onTap: () => _openInteractive(item),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: cover.isNotEmpty
                                ? Image.network(ApiService().imageUrl(cover), fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildInteractivePlaceholder())
                                : _buildInteractivePlaceholder(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            item['title']?.toString() ?? '互动剧',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractivePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCE93D8), Color(0xFFE1BEE7), Color(0xFFF3E5F5)],
        ),
      ),
      child: const Center(child: Icon(Icons.auto_stories, size: 36, color: Colors.white)),
    );
  }

  Widget _buildSearchResults(AppLocale l10n) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF69B4)));
    }
    if (_searchChars.isEmpty) {
      return Center(child: Text(l10n.t('暂无结果'), style: const TextStyle(fontSize: 16, color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Text(l10n.t('角色'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFE91E63))),
        ),
        ..._searchChars.map((c) => _resultTile(c, l10n)),
      ],
    );
  }

  Widget _resultTile(Map<String, dynamic> c, AppLocale l10n) {
    final portrait = c['portrait'] as String?;
    final name = AppLocale.instance.translateContent(c['name']?.toString());
    final desc = AppLocale.instance.translateContent(c['description']?.toString());
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFCDD2),
          backgroundImage: (portrait != null && portrait.isNotEmpty)
              ? NetworkImage(ApiService().imageUrl(portrait))
              : null,
          child: (portrait == null || portrait.isEmpty)
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(name.isNotEmpty ? name : (c['name'] ?? ''), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _openChat(c),
      ),
    );
  }

  void _openInteractive(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InteractivePlayPage(
          appId: item['id'].toString(),
          title: item['title']?.toString() ?? '互动剧',
          initialScene: item['scene']?.toString() ?? '',
          initialChoices: const [],
        ),
      ),
    ).then((_) => _loadData());
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
    final l10n = AppLocale.instance;
    final portrait = character['portrait'] as String?;
    final name = l10n.translateContent(character['name']?.toString());
    final description = l10n.translateContent(character['description']?.toString());

    return GestureDetector(
      onTap: onTap,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (portrait != null && portrait.isNotEmpty)
              Image.network(
                ApiService().imageUrl(portrait),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),
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
            Positioned(
              left: 24,
              right: 80,
              bottom: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name.isNotEmpty ? name : (character['name'] ?? ''),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
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
      child: const Center(child: Icon(Icons.person, size: 120, color: Colors.white38)),
    );
  }
}
