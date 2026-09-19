import 'package:flutter/material.dart';
import '../api_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = ApiService();
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _usage;
  List<dynamic> _myChars = [];
  List<dynamic> _myStories = [];
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
        _api.getMe(),
        _api.getUsage(),
        _api.getMyCharacters(),
        _api.getMyStories(),
      ]);
      setState(() {
        _user = results[0] as Map<String, dynamic>?;
        _usage = results[1] as Map<String, dynamic>?;
        _myChars = results[2] as List;
        _myStories = results[3] as List;
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF69B4)))
          : RefreshIndicator(
              color: const Color(0xFFFF69B4),
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildUsageCard(),
                  const SizedBox(height: 16),
                  _buildMyWorks(),
                  const SizedBox(height: 16),
                  _buildMenu(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final name = _user?['username'] ?? '未登录';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.pink.shade100, Colors.pink.shade50]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.pink.shade300,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${_myChars.length} 个角色 · ${_myStories.length} 个故事',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.pink),
            onPressed: () => _showEditProfile(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageCard() {
    final sec = _usage?['totalSeconds'] ?? 0;
    final hours = sec ~/ 3600;
    final mins = (sec % 3600) ~/ 60;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildUsageItem('$hours', '小时'),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildUsageItem('$mins', '分钟'),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildUsageItem('${_myChars.length}', '作品'),
        ],
      ),
    );
  }

  Widget _buildUsageItem(String num, String label) {
    return Column(
      children: [
        Text(num, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF69B4))),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMyWorks() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('我的作品', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_myChars.isEmpty && _myStories.isEmpty)
            const Text('还没有作品，去创作吧', style: TextStyle(color: Colors.grey)),
          ..._myChars.take(3).map((c) => ListTile(
                leading: CircleAvatar(backgroundColor: Colors.pink.shade100, child: Text(c['name']?[0] ?? '?')),
                title: Text(c['name'] ?? ''),
                subtitle: Text('${c['likeCount'] ?? 0} 赞 · ${c['commentCount'] ?? 0} 评论'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              )),
          if (_myChars.length > 3)
            Center(child: TextButton(onPressed: () {}, child: const Text('查看全部'))),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _menuItem(Icons.person_outline, '编辑资料', () => _showEditProfile()),
          _menuItem(Icons.lock_outline, '修改密码', () => _showChangePassword()),
          _menuItem(Icons.settings, '设置', () => _showSettings()),
          _menuItem(Icons.feedback_outlined, '意见反馈', () => _showFeedback()),
          _menuItem(Icons.info_outline, '关于月悟', () => _showAbout()),
          const Divider(height: 1),
          _menuItem(Icons.logout, '退出登录', () => _logout(), color: Colors.red),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.pink),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _user?['username'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑资料'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: '用户名')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, nameCtrl.text), child: const Text('保存')),
        ],
      ),
    );
  }

  void _showChangePassword() {
    final oldPw = TextEditingController();
    final newPw = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPw, obscureText: true, decoration: const InputDecoration(hintText: '旧密码')),
            const SizedBox(height: 10),
            TextField(controller: newPw, obscureText: true, decoration: const InputDecoration(hintText: '新密码')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('确认')),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.notifications), title: const Text('通知设置'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.privacy_tip), title: const Text('隐私设置'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.palette), title: const Text('外观设置'), onTap: () => Navigator.pop(ctx)),
            ListTile(leading: const Icon(Icons.cleaning_services), title: const Text('清除缓存'), onTap: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缓存已清除'))); }),
          ],
        ),
      ),
    );
  }

  void _showFeedback() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('意见反馈'),
        content: TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: '告诉我们你的想法...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.sendFeedback(ctrl.text);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('感谢反馈！')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: '月悟',
      applicationVersion: 'v2.0.0',
      applicationIcon: const Icon(Icons.favorite, color: Colors.pink, size: 48),
    );
  }

  void _logout() async {
    await _api.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
    }
  }
}
