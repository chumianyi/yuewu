import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateCharacterPage extends StatefulWidget {
  const CreateCharacterPage({super.key});

  @override
  State<CreateCharacterPage> createState() => _CreateCharacterPageState();
}

class _CreateCharacterPageState extends State<CreateCharacterPage> {
  final String _baseUrl = 'http://103.236.99.177:24512';

  final Color primaryPink = const Color(0xFFFFB6C1);
  final Color bgPink = const Color(0xFFFFF0F5);
  final Color accentPink = const Color(0xFFFF69B4);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _settingController = TextEditingController();
  final TextEditingController _openingController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _portraitImageUrl;
  bool _isGenerating = false;
  bool _isPublishing = false;

  Future<void> _showGeneratePortraitDialog() async {
    final promptController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          '创建形象',
          style: TextStyle(color: accentPink, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: promptController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '描述你想要的角色形象...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentPink),
            onPressed: () => Navigator.pop(context, promptController.text),
            child: const Text('生成', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _generatePortrait(result);
    }
  }

  Future<void> _generatePortrait(String prompt) async {
    setState(() => _isGenerating = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate-portrait'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imagePath = data['imageUrl'] as String;
        setState(() {
          _portraitImageUrl = '$_baseUrl$imagePath';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('形象生成成功！')),
          );
        }
      } else {
        throw Exception('生成失败: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _publishCharacter() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入角色名')),
      );
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/characters'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'setting': _settingController.text,
          'opening': _openingController.text,
          'bio': _bioController.text,
          'portrait': _portraitImageUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('角色发布成功！')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('发布失败: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    } finally {
      setState(() => _isPublishing = false);
    }
  }

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
          '创建角色',
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
            _buildPortraitSection(),
            const SizedBox(height: 24),
            _buildLabel('角色名'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: '给你的角色起个名字',
            ),
            const SizedBox(height: 20),
            _buildLabel('角色设定（系统提示词）'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _settingController,
              hint: '描述角色的性格、背景、说话方式...',
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            _buildLabel('开场白'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _openingController,
              hint: '角色第一次会对你说什么？',
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            _buildLabel('角色简介（选填）'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _bioController,
              hint: '简单介绍一下这个角色',
              maxLines: 3,
            ),
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
                onPressed: _isPublishing ? null : _publishCharacter,
                child: _isPublishing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '发布',
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

  Widget _buildPortraitSection() {
    return Center(
      child: GestureDetector(
        onTap: _showGeneratePortraitDialog,
        child: Container(
          width: 140,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryPink, width: 2),
          ),
          child: _isGenerating
              ? const Center(child: CircularProgressIndicator())
              : _portraitImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _portraitImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('加载失败',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 40, color: accentPink),
                        const SizedBox(height: 8),
                        Text(
                          '+ 创建形象',
                          style: TextStyle(
                            color: accentPink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
}
