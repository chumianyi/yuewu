import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../api_service.dart';

class CodeAssistantPage extends StatefulWidget {
  const CodeAssistantPage({super.key});
  @override
  State<CodeAssistantPage> createState() => _CodeAssistantPageState();
}

class _CodeAssistantPageState extends State<CodeAssistantPage> {
  final _api = ApiService();
  final _promptCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _generating = false;
  List<dynamic> _myGames = [];
  List<dynamic> _pubGames = [];
  String? _previewUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final mine = await _api.codeMyList();
      final pub = await _api.codePublished();
      if (mounted) setState(() { _myGames = mine; _pubGames = pub; });
    } catch (_) {}
  }

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) return;
    setState(() => _generating = true);
    try {
      final res = await _api.codeGenerate(_promptCtrl.text.trim(), _nameCtrl.text.trim());
      final url = _api.baseUrl + (res['url'] ?? '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('生成成功！')));
        _promptCtrl.clear(); _nameCtrl.clear();
        _load();
        _openPreview(url);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _openPreview(String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _WebViewPage(url: url)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('代码小助手'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI一键生成HTML冒险剧', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '游戏名称（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '描述你的冒险剧（如：一个魔法森林冒险故事，有多个选择分支）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _generating ? null : _generate,
                child: _generating
                    ? const Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('生成中...'),
                      ])
                    : const Text('一键生成'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('我的游戏', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._myGames.map((g) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.sports_esports, color: Color(0xFFFFB6C1)),
                    title: Text(g['name'] ?? '未命名'),
                    subtitle: Text(g['published'] == true ? '已发布' : '草稿'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (g['published'] != true)
                        IconButton(icon: const Icon(Icons.public, color: Colors.green), onPressed: () async {
                          await _api.codePublish(g['id']);
                          _load();
                        }),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                        await _api.codeDelete(g['id']);
                        _load();
                      }),
                    ]),
                    onTap: () => _openPreview(_api.baseUrl + (g['path'] ?? '')),
                  ),
                )),
            const SizedBox(height: 16),
            const Text('已发布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ..._pubGames.map((g) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.public, color: Colors.blue),
                    title: Text(g['name'] ?? '未命名'),
                    subtitle: Text(g['authorName'] ?? ''),
                    onTap: () => _openPreview(_api.baseUrl + (g['path'] ?? '')),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _WebViewPage extends StatelessWidget {
  final String url;
  const _WebViewPage({required this.url});
  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()..loadRequest(Uri.parse(url));
    return Scaffold(
      appBar: AppBar(title: const Text('游戏预览')),
      body: WebViewWidget(controller: controller),
    );
  }
}
