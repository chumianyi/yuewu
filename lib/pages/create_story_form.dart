import 'package:flutter/material.dart';
import '../api.dart';

class CreateStoryForm extends StatefulWidget {
  final String prefill;
  const CreateStoryForm({super.key, this.prefill = ''});

  @override
  State<CreateStoryForm> createState() => _CreateStoryFormState();
}

class _CreateStoryFormState extends State<CreateStoryForm> {
  final _name = TextEditingController();
  final _opening = TextEditingController();
  final _worldview = TextEditingController();
  bool _ends = false;
  bool _advanced = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefill.isNotEmpty) _worldview.text = widget.prefill;
  }

  Future<void> _save() async {
    if (_name.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写故事名称')));
      return;
    }
    setState(() => _saving = true);
    try {
      await Api.createStory({
        'name': _name.text,
        'description': _worldview.text,
        'greeting': _opening.text,
        'globalPrompt': _worldview.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('故事已保存')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    hintText: '请填写故事名称',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('参与角色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('+ 选择参与角色', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('故事开场', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('请选择', style: TextStyle(color: Colors.blue, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _opening,
                          decoration: const InputDecoration(
                            hintText: '请输入故事开场的内容',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('故事内容', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.music_note, size: 20), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.more_vert, size: 20), onPressed: () {}),
                    ]),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _worldview,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: '描述你想构建的世界观，如人物关系、主题背景、玩法规则等',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('故事是否会结束'),
                      Row(
                        children: [
                          Text(_ends ? '会结束' : '不会结束', style: TextStyle(color: Colors.grey[600])),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => setState(() => _advanced = !_advanced),
                  child: Row(
                    children: [
                      const Text('高级设定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Icon(_advanced ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
                if (_advanced)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('高级设定选项...', style: TextStyle(color: Colors.grey)),
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
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('一键绘图', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
