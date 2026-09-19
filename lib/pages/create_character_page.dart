import 'package:flutter/material.dart';
import '../api_service.dart';

const Color _kPrimary = Color(0xFFFFB6C1);
const Color _kBg = Color(0xFFFFF0F5);
const Color _kCard = Colors.white;

class CreateCharacterPage extends StatefulWidget {
  final String prefill;
  const CreateCharacterPage({super.key, this.prefill = ''});

  @override
  State<CreateCharacterPage> createState() => _CreateCharacterPageState();
}

class _CreateCharacterPageState extends State<CreateCharacterPage> {
  final _nameCtrl = TextEditingController();
  final _settingCtrl = TextEditingController();
  final _greetingCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _portraitPath;
  bool _generatingPortrait = false;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefill.isNotEmpty) _settingCtrl.text = widget.prefill;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _settingCtrl.dispose();
    _greetingCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _showPortraitDialog() async {
    final descCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('创建形象',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: descCtrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '描述你想要的角色形象，如：银色长发，红色眼眸，穿黑色哥特裙',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.pop(context, descCtrl.text.trim()),
            child: const Text('生成'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    await _generatePortrait(result);
  }

  Future<void> _generatePortrait(String prompt) async {
    setState(() => _generatingPortrait = true);
    try {
      final r = await ApiService().generatePortrait(prompt);
      final path = (r['url'] ?? r['path'] ?? r['image'] ?? '').toString();
      setState(() => _portraitPath = path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPortrait = false);
    }
  }

  Future<void> _publish() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写角色名')),
      );
      return;
    }
    setState(() => _publishing = true);
    try {
      await ApiService().createCharacter({
        'name': _nameCtrl.text.trim(),
        'description': _bioCtrl.text.trim(),
        'greeting': _greetingCtrl.text.trim(),
        'systemPrompt': _settingCtrl.text.trim(),
        'portrait': _portraitPath ?? '',
        'category': '创作',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发布成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('创建角色',
            style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // + 创建形象
                GestureDetector(
                  onTap: _generatingPortrait ? null : _showPortraitDialog,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _generatingPortrait
                        ? const Center(
                            child: CircularProgressIndicator(color: _kPrimary))
                        : _portraitPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  ApiService().baseUrl + _portraitPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Colors.grey, size: 48),
                                  ),
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      size: 40, color: _kPrimary),
                                  SizedBox(height: 8),
                                  Text('+ 创建形象',
                                      style: TextStyle(
                                          color: _kPrimary, fontSize: 16)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 24),
                // 角色名
                const Text('角色名',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: '请填写角色名称',
                    filled: true,
                    fillColor: _kCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 角色设定
                const Text('角色设定',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _settingCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText:
                        '角色的性格、身份、说话风格、跟用户的关系等\n请用"用户"来称呼与角色对话的人',
                    filled: true,
                    fillColor: _kCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 开场白
                const Text('开场白',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _greetingCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '作为角色说的第一句话。可使用（）描述动作或场景',
                    filled: true,
                    fillColor: _kCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 角色简介
                const Text('角色简介（选填）',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '一句话介绍这个角色',
                    filled: true,
                    fillColor: _kCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 黄色发布按钮
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: _publishing ? null : _publish,
                child: _publishing
                    ? const CircularProgressIndicator()
                    : const Text('发布',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
