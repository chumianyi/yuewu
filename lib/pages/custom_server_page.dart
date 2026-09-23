import 'package:flutter/material.dart';

/// 自定义服务器配置页。
/// 输入 IP 与端口（默认 24512），协议支持 TCP / UDP，可选填 API Key。
class CustomServerPage extends StatefulWidget {
  const CustomServerPage({super.key});

  @override
  State<CustomServerPage> createState() => _CustomServerPageState();
}

class _CustomServerPageState extends State<CustomServerPage> {
  final _nameCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '24512');
  final _apiKeyCtrl = TextEditingController();
  String _protocol = 'tcp';
  bool _showKey = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final ip = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim());
    if (ip.isEmpty) {
      setState(() => _error = '请输入服务器 IP 或域名');
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      setState(() => _error = '端口无效（1-65535）');
      return;
    }
    Navigator.pop(context, {
      'name': _nameCtrl.text.trim(),
      'ip': ip,
      'port': port,
      'protocol': _protocol,
      'apiKey': _showKey ? _apiKeyCtrl.text.trim() : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFFB6C1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义服务器'),
        backgroundColor: const Color(0xFFFFF0F5),
        foregroundColor: const Color(0xFF4A4A4A),
      ),
      backgroundColor: const Color(0xFFFFF0F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE3E8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Color(0xFFE91E63)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '自定义服务器可能存在风险，请确认你信任该服务器的运营者。',
                      style: TextStyle(fontSize: 13, color: Color(0xFFB71C1C)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: '服务器名称（可选）',
                prefixIcon: Icon(Icons.label_outline, color: pink),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'IP 或域名',
                prefixIcon: Icon(Icons.dns_outlined, color: pink),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '端口（默认 24512）',
                prefixIcon: Icon(Icons.router, color: pink),
              ),
            ),
            const SizedBox(height: 16),
            // 协议选择：TCP / UDP
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert, color: pink, size: 20),
                  const SizedBox(width: 12),
                  const Text('协议', style: TextStyle(color: Color(0xFF4A4A4A))),
                  const Spacer(),
                  ChoiceChip(
                    label: const Text('TCP'),
                    selected: _protocol == 'tcp',
                    selectedColor: pink,
                    labelStyle: TextStyle(
                      color: _protocol == 'tcp' ? Colors.white : Colors.grey[700],
                    ),
                    onSelected: (_) => setState(() => _protocol = 'tcp'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('UDP'),
                    selected: _protocol == 'udp',
                    selectedColor: pink,
                    labelStyle: TextStyle(
                      color: _protocol == 'udp' ? Colors.white : Colors.grey[700],
                    ),
                    onSelected: (_) => setState(() => _protocol = 'udp'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: !_showKey,
              decoration: InputDecoration(
                hintText: 'API Key（可选，对方服务器要求时填写）',
                prefixIcon: const Icon(Icons.vpn_key_outlined, color: pink),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _showKey = !_showKey),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13)),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('连接', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
