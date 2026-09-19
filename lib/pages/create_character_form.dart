import 'package:flutter/material.dart';
import '../api.dart';

class CreateCharacterForm extends StatefulWidget {
  final String prefill;
  const CreateCharacterForm({super.key, this.prefill = ''});

  @override
  State<CreateCharacterForm> createState() => _CreateCharacterFormState();
}

class _CreateCharacterFormState extends State<CreateCharacterForm> {
  final _name = TextEditingController();
  final _setting = TextEditingController();
  final _greeting = TextEditingController();
  final _bio = TextEditingController();
  String? _portrait;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefill.isNotEmpty) _setting.text = widget.prefill;
  }

  void _showGenerateDialog() {
    final promptCtrl = TextEditingController(text: _setting.text.isNotEmpty ? _setting.text : _name.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('描述你的角色形象'),
        content: TextField(
          controller: promptCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: '描述外貌、服装、风格...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _generatePortrait(promptCtrl.text);
            },
            child: const Text('生成'),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePortrait(String prompt) async {
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请描述形象')));
      return;
    }
    setState(() => _publishing = true);
    try {
      final r = await Api.generatePortrait('anime portrait, $prompt');
      setState(() => _portrait = r['imageUrl'] ?? r['url']);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _publish() async {
    if (_name.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写角色名')));
      return;
    }
    setState(() => _publishing = true);
    try {
      await Api.createCharacter({
        'name': _name.text,
        'description': _bio.text,
        'greeting': _greeting.text,
        'systemPrompt': _setting.text,
        'portrait': _portrait ?? '',
        'category': '创作',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('发布成功')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GestureDetector(
                  onTap: _showGenerateDialog,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.pink.shade200),
                    ),
                    child: _portrait != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(Api.portraitUrl(_portrait), fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('创建形象', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('角色名', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    hintText: '请填写角色名称',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('角色设定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _setting,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: '角色的性格、身份、说话风格、跟用户的关系等 请用"用户"来称呼与角色对话的人',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('开场白', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _greeting,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '作为角色说的第一句话。可使用（）描述动作或场景',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('角色简介（选填）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _bio,
                  maxLines: 2,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF69B4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: _publishing ? null : _publish,
                child: _publishing
                    ? const CircularProgressIndicator()
                    : const Text('发布', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
