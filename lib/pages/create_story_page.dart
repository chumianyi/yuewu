import 'package:flutter/material.dart';

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final Color primaryPink = const Color(0xFFFFB6C1);
  final Color bgPink = const Color(0xFFFFF0F5);
  final Color accentPink = const Color(0xFFFF69B4);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _openingContentController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String? _selectedCharacter;
  bool _storyWillEnd = false;
  bool _showAdvanced = false;
  final List<String> _selectedCharacters = [];

  final List<String> _availableCharacters = const [
    '苏小雨',
    '陆景深',
    '林晚星',
    '顾言泽',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,
      appBar: AppBar(
        backgroundColor: bgPink,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accentPink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '创建故事',
          style: TextStyle(
            color: accentPink,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('故事名称'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: '给故事起个好听的名字',
            ),
            const SizedBox(height: 20),
            _buildLabel('参与角色'),
            const SizedBox(height: 8),
            _buildCharacterSelector(),
            const SizedBox(height: 20),
            _buildLabel('故事开场'),
            const SizedBox(height: 8),
            _buildCharacterDropdown(),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _openingContentController,
              hint: '开场对话或场景描述...',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _buildLabel('故事内容'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _contentController,
              hint: '描述故事的世界观、主线剧情、你的角色...',
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            _buildLabel('故事是否会结束'),
            const SizedBox(height: 8),
            _buildStoryEndToggle(),
            const SizedBox(height: 16),
            _buildAdvancedSection(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('一键绘图功能开发中...')),
                  );
                },
                child: const Text(
                  '一键绘图',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCharacterSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedCharacters.map((c) {
            return Chip(
              label: Text(c),
              backgroundColor: primaryPink.withOpacity(0.3),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _selectedCharacters.remove(c));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showCharacterPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: primaryPink),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add, size: 18, color: accentPink),
                const SizedBox(width: 6),
                Text(
                  '选择参与角色',
                  style: TextStyle(color: accentPink, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCharacterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择角色',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentPink,
              ),
            ),
            const SizedBox(height: 16),
            ..._availableCharacters.map((c) {
              final selected = _selectedCharacters.contains(c);
              return ListTile(
                title: Text(c),
                trailing: selected
                    ? Icon(Icons.check_circle, color: accentPink)
                    : const Icon(Icons.circle_outlined),
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedCharacters.remove(c);
                    } else {
                      _selectedCharacters.add(c);
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCharacter,
          hint: Text(
            '选择开场角色',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          isExpanded: true,
          items: _availableCharacters.map((c) {
            return DropdownMenuItem(value: c, child: Text(c));
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedCharacter = val);
          },
        ),
      ),
    );
  }

  Widget _buildStoryEndToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '这个故事会有结局',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
          Switch(
            value: _storyWillEnd,
            activeColor: accentPink,
            onChanged: (val) {
              setState(() => _storyWillEnd = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          '高级设定',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        initiallyExpanded: _showAdvanced,
        onExpansionChanged: (val) {
          setState(() => _showAdvanced = val);
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: TextEditingController(),
                  hint: '世界观补充设定（选填）',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: TextEditingController(),
                  hint: '隐藏剧情线（选填）',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: TextEditingController(),
                  hint: '特殊规则/系统设定（选填）',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
