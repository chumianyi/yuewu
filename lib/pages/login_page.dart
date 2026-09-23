import 'package:flutter/material.dart';
import '../api_service.dart';
import '../server_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ApiService _api = ApiService();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pink = const Color(0xFFFFB6C1);

  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final u = _usernameCtrl.text.trim();
    final p = _passwordCtrl.text;
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = '请输入账号和密码');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        await _api.login(u, p);
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
        }
      } else {
        final res = await _api.register(u, p);
        if (mounted) {
          if (res['token'] != null) {
            Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('注册成功，请登录')),
            );
            setState(() => _isLogin = true);
          }
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 当前服务器信息条：服务器名称 + 正版校验状态
  Widget _buildServerBanner() {
    final mgr = ServerManager();
    final official = mgr.officialValidation;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pink.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.dns, size: 20, color: Color(0xFFFFB6C1)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mgr.serverName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: official ? const Color(0xFFFFE3E8) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              official ? '正版校验' : '免校验',
              style: TextStyle(
                fontSize: 11,
                color: official ? const Color(0xFFC2185B) : const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80),
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
                  child: const Icon(Icons.auto_awesome, size: 44, color: Color(0xFFFFB6C1)),
                ),
                const SizedBox(height: 24),
                const Text(
                  '月悟',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? '登录你的 AI 伙伴' : '创建新账号',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                _buildServerBanner(),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '账号',
                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFFFFB6C1)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: '密码',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFFB6C1)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13)),
                ],
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text(_isLogin ? '登录' : '注册', style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? '还没有账号？' : '已经有账号？',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _isLogin = !_isLogin;
                                _error = null;
                              }),
                      child: Text(
                        _isLogin ? '立即注册' : '直接登录',
                        style: const TextStyle(color: Color(0xFFFFB6C1), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
