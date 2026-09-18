import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username;
  Map<String, dynamic>? _usage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final u = await Api.getUsage();
      setState(() {
        _username = sp.getString('username') ?? '用户';
        _usage = u;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _fmtSec(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}小时${m}分';
    return '${m}分钟';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Column(children: [
                    CircleAvatar(
                      radius: 40,
                      child: Text(_username?[0] ?? '?', style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(height: 12),
                    Text(_username ?? '用户', style: Theme.of(context).textTheme.titleLarge),
                  ]),
                ),
                const SizedBox(height: 32),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('使用时长', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.timer_outlined, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('今日: ${_fmtSec(_usage?['todaySeconds'] ?? 0)}'),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.history, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('累计: ${_fmtSec(_usage?['totalSeconds'] ?? 0)}'),
                        ]),
                        if (_usage?['break_reminder'] == true)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('已达12小时，注意休息', style: TextStyle(color: Colors.orange)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('意见反馈'),
                  onTap: _showFeedback,
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('退出登录', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await Api.logout();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                    }
                  },
                ),
              ],
            ),
    );
  }

  void _showFeedback() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('意见反馈'),
        content: TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: '说说你的建议...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () async {
            try {
              await Api.sendFeedback(ctrl.text);
              if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('感谢反馈'))); }
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
          }, child: const Text('提交')),
        ],
      ),
    );
  }
}
