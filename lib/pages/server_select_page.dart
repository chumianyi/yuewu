import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_service.dart';
import '../server_config.dart';
import 'custom_server_page.dart';

/// 首次打开应用时的服务器选择界面。
/// 默认提供「星悟主服」；支持自定义服务器（带风险提示）；支持跳转服务器文件仓库。
class ServerSelectPage extends StatefulWidget {
  const ServerSelectPage({super.key});

  @override
  State<ServerSelectPage> createState() => _ServerSelectPageState();
}

class _ServerSelectPageState extends State<ServerSelectPage> {
  final _pink = const Color(0xFFFFB6C1);
  bool _busy = false;

  /// 服务器文件仓库地址（安装过程说明）
  static const String serverRepoUrl = 'https://github.com/chumianyi/yuewu-server';

  Future<void> _useMainServer() async {
    setState(() => _busy = true);
    try {
      await ServerManager().useMainServer();
      // 连接后立即从服务器拉取 api.json（模型列表 / 正版校验）
      try {
        await ApiService().fetchApiConfig();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法连接星悟主服，请检查网络后重试：$e')),
          );
        }
        setState(() => _busy = false);
        return;
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _useCustomServer() async {
    // 风险提示：不推荐使用
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('不推荐使用'),
        content: const Text(
          '自定义服务器并非官方提供，可能存在数据泄露、服务不稳定等风险。\n请确认你信任该服务器的运营者后再继续。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认使用'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const CustomServerPage()),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ServerManager().useCustomServer(
        name: (result['name'] as String?) ?? '自定义服务器',
        ip: (result['ip'] as String?) ?? '',
        port: (result['port'] as num?)?.toInt() ?? 24512,
        protocol: (result['protocol'] as String?) ?? 'tcp',
        apiKey: result['apiKey'] as String?,
      );
      try {
        await ApiService().fetchApiConfig();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法连接该服务器，请检查 IP / 端口 / 协议后重试：$e')),
          );
        }
        setState(() => _busy = false);
        return;
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openServerRepo() async {
    final uri = Uri.parse(serverRepoUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开浏览器，请手动访问：github.com/chumianyi/yuewu-server')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开浏览器，请手动访问：github.com/chumianyi/yuewu-server')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFC0CB), Color(0xFFFFF0F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _pink.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.dns, size: 44, color: Color(0xFFFFB6C1)),
                ),
                const SizedBox(height: 20),
                const Text(
                  '选择服务器',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '首次使用请选择一个服务器连接',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 36),

                // 默认服务器：星悟主服
                _ServerCard(
                  icon: Icons.star,
                  title: '星悟主服',
                  subtitle: '官方主服务器 · 正版校验 · 稳定可靠',
                  color: _pink,
                  trailing: const Icon(Icons.chevron_right, color: Colors.white),
                  onTap: _busy ? null : _useMainServer,
                ),
                const SizedBox(height: 14),

                // 自定义服务器
                _ServerCard(
                  icon: Icons.dns_outlined,
                  title: '自定义服务器',
                  subtitle: '连接你自己或其他人的服务器',
                  color: const Color(0xFF90CAF9),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white),
                  onTap: _busy ? null : _useCustomServer,
                ),
                const SizedBox(height: 32),

                // 我想开服务器
                OutlinedButton.icon(
                  onPressed: _busy ? null : _openServerRepo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A4A4A),
                    side: BorderSide(color: _pink.withValues(alpha: 0.6)),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.code, color: Color(0xFFFFB6C1)),
                  label: const Text('我想开服务器'),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击查看服务器安装说明（GitHub 仓库）',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ServerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.18),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
