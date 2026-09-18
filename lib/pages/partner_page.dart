import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api.dart';
import 'chat_page.dart';

class PartnerPage extends StatefulWidget {
  const PartnerPage({super.key});

  @override
  State<PartnerPage> createState() => _PartnerPageState();
}

class _PartnerPageState extends State<PartnerPage> {
  dynamic _partner;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await Api.getPartner();
      setState(() { _partner = p; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的伙伴'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _partner == null
              ? const Center(child: Text('暂无伙伴'))
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: (_partner['portrait'] != null && _partner['portrait'].isNotEmpty)
                            ? CachedNetworkImageProvider(Api.portraitUrl(_partner['portrait']))
                            : null,
                        child: (_partner['portrait'] == null || _partner['portrait'].isEmpty)
                            ? Text(_partner['name']?[0] ?? '悟', style: const TextStyle(fontSize: 48))
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Text(_partner['name'] ?? '悟悟', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(_partner['description'] ?? '', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text('和TA聊天'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(
                          title: _partner['name'] ?? '悟悟',
                          characterName: _partner['name'] ?? '',
                          portrait: _partner['portrait'],
                          greeting: _partner['greeting'],
                        ))),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('编辑伙伴'),
                        onPressed: _editPartner,
                      ),
                    ],
                  ),
                ),
    );
  }

  void _editPartner() {
    final nameCtrl = TextEditingController(text: _partner['name']);
    final descCtrl = TextEditingController(text: _partner['description']);
    final greetCtrl = TextEditingController(text: _partner['greeting']);
    final sysCtrl = TextEditingController(text: _partner['systemPrompt']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑伙伴'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名字')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述')),
            TextField(controller: greetCtrl, decoration: const InputDecoration(labelText: '开场白')),
            TextField(controller: sysCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '系统提示词')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () async {
            try {
              await Api.updatePartner({
                'name': nameCtrl.text, 'description': descCtrl.text,
                'greeting': greetCtrl.text, 'systemPrompt': sysCtrl.text,
              });
              if (mounted) { Navigator.pop(ctx); _load(); }
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
          }, child: const Text('保存')),
        ],
      ),
    );
  }
}
