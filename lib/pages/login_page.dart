import 'package:flutter/material.dart';
import '../api.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await Api.login(_userCtrl.text.trim(), _passCtrl.text);
      } else {
        await Api.register(_userCtrl.text.trim(), _passCtrl.text);
      }
      if (mounted) widget.onLogin();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.auto_awesome, size: 72, color: Color(0xFF6750A4)),
              const SizedBox(height: 16),
              Text('月悟', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_isLogin ? '登录你的AI伙伴' : '创建账号', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 48),
              TextField(
                controller: _userCtrl,
                decoration: const InputDecoration(
                  labelText: '账号',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
                ),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isLogin ? '登录' : '注册'),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? '没有账号？注册' : '已有账号？登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
