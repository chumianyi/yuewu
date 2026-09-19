import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _api = ApiService();
  final _pink = const Color(0xFFFFB6C1);

  bool _loading = true;
  bool _loggedIn = false;
  Map<String, dynamic>? _me;
  Map<String, dynamic>? _usage;
  List<dynamic> _myChars = [];
  List<dynamic> _myStories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logged = _api.isLoggedIn;
    if (!logged) {
      if (mounted) setState(() {
        _loggedIn = false;
        _loading = false;
      });
      return;
    }
    try {
      final results = await Future.wait([
        _api.getMe(),
        _api.getUsage(),
        _api.getMyCharacters(),
        _api.getMyStories(),
      ]);
      if (mounted) {
        setState(() {
          _loggedIn = true;
          _me = results[0] as Map<String, dynamic>;
          _usage = results[1] as Map<String, dynamic>;
          _myChars = results[2] as List;
          _myStories = results[3] as List;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtSeconds(dynamic s) {
    final sec = (s is int) ? s : int.tryParse('$s') ?? 0;
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '${h}小时${m}分';
    if (m > 0) return '${m}分钟';
    return '$sec秒';
  }

  String _avatarUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.startsWith('http') ? path : '${_api.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的')),
        body: Center(child: CircularProgressIndicator(color: _pink)),
      );
    }
    if (!_loggedIn) return _buildLoggedOut();
    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: true),
      body: RefreshIndicator(
        color: _pink,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildHeader(),
            _buildUsageCard(),
            _buildMyWorks(),
            _buildMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOut() {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline, size: 48, color: _pink),
            ),
            const SizedBox(height: 20),
            const Text('登录后同步你的作品与数据', style: TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
                _load();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('立即登录'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _me?['username'] ?? _me?['name'] ?? '用户';
    final avatar = _me?['avatar'] ?? _me?['avatarUrl'];
    final url = _avatarUrl(avatar?.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: _pink.withValues(alpha: 0.2),
            backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
            child: url.isEmpty
                ? Text(name.isNotEmpty ? name[0] : '?',
                    style: TextStyle(fontSize: 32, color: _pink, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUsageCard() {
    final today = _usage?['todaySeconds'] ?? _usage?['today_seconds'] ?? 0;
    final total = _usage?['totalSeconds'] ?? _usage?['total_seconds'] ?? 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: _pink, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('使用时长', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('今日 ${_fmtSeconds(today)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text('累计 ${_fmtSeconds(total)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 16, 12),
          child: Text('我的作品', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        if (_myChars.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('还没有发布过角色', style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _myChars.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _buildCharacterChip(_myChars[i]),
            ),
          ),
        const SizedBox(height: 8),
        if (_myStories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text('还没有发布过故事', style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          ..._myStories.take(5).map((s) => _buildStoryTile(s)),
      ],
    );
  }

  Widget _buildCharacterChip(Map<String, dynamic> c) {
    final name = c['name'] ?? '角色';
    final likes = c['likes'] ?? c['likesCount'] ?? c['likes_count'] ?? 0;
    final portrait = c['portrait']?.toString();
    final url = _avatarUrl(portrait);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/character_detail',
        arguments: {'characterId': c['id']},
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: _pink.withValues(alpha: 0.2),
            backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
            child: url.isEmpty ? Text(name[0], style: const TextStyle(color: Colors.white)) : null,
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, size: 12, color: _pink),
              const SizedBox(width: 2),
              Text('$likes', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoryTile(Map<String, dynamic> s) {
    final title = s['title'] ?? s['name'] ?? '未命名故事';
    final updated = s['updatedAt'] ?? s['createdAt'] ?? '';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _pink.withValues(alpha: 0.2),
        child: const Icon(Icons.menu_book, color: Color(0xFFFFB6C1)),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('$updated'.split('T').first, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () => Navigator.pushNamed(
        context,
        '/story_detail',
        arguments: {
          'storyId': s['id'],
          'characterId': s['characterId'] ?? s['character_id'],
        },
      ),
    );
  }

  Widget _buildMenu() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.settings_outlined, color: Color(0xFFFFB6C1)),
          title: const Text('设置'),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const _SettingsPage()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.feedback_outlined, color: Color(0xFFFFB6C1)),
          title: const Text('意见反馈'),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: _showFeedback,
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: Color(0xFFFFB6C1)),
          title: const Text('关于月悟'),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: _showAbout,
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
          title: const Text('退出登录', style: TextStyle(color: Color(0xFFD32F2F))),
          onTap: _confirmLogout,
        ),
      ],
    );
  }

  void _showFeedback() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('意见反馈', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(hintText: '说说你遇到的问题或建议…'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = ctrl.text.trim();
                    if (text.isEmpty) return;
                    try {
                      await _api.sendFeedback(text);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('感谢你的反馈')),
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
                  child: const Text('提交'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: '月悟',
      applicationVersion: 'v1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
      children: const [
        SizedBox(height: 12),
        Text('月悟 —— 你的专属 AI 伙伴，陪你聊天、创作与陪伴。'),
      ],
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await _api.logout();
              if (mounted) {
                Navigator.pop(ctx);
                _load();
              }
            },
            child: const Text('退出', style: TextStyle(color: Color(0xFFD32F2F))),
          ),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage();

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  final _pink = const Color(0xFFFFB6C1);
  bool _push = true;
  bool _vibrate = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _push = sp.getBool('push_notify') ?? true;
        _vibrate = sp.getBool('vibrate') ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.notifications_outlined, color: _pink),
            title: const Text('消息通知'),
            subtitle: const Text('接收新消息与新点赞提醒'),
            value: _push,
            activeThumbColor: _pink,
            onChanged: (v) async {
              setState(() => _push = v);
              (await SharedPreferences.getInstance()).setBool('push_notify', v);
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.vibration, color: _pink),
            title: const Text('触感振动'),
            subtitle: const Text('聊天发送时轻微振动'),
            value: _vibrate,
            activeThumbColor: _pink,
            onChanged: (v) async {
              setState(() => _vibrate = v);
              (await SharedPreferences.getInstance()).setBool('vibrate', v);
            },
          ),
          ListTile(
            leading: Icon(Icons.cleaning_services_outlined, color: _pink),
            title: const Text('清除图片缓存'),
            subtitle: const Text('清理已加载的角色立绘缓存'),
            onTap: () async {
              imageCache.clear();
              imageCache.clearLiveImages();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('缓存已清理')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
