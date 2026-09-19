import 'package:flutter/material.dart';
import '../api_service.dart';

const Color _kPrimary = Color(0xFFFFB6C1);
const Color _kBg = Color(0xFFFFF0F5);
const Color _kCard = Colors.white;

/// AI帮写弹窗
/// 用户输入需求描述 → 调chat API → 返回AI生成的内容
/// 调用方通过 showDialog<String> 拿到结果后自动填入对应输入框
class AiAssistDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String systemPrompt;

  const AiAssistDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.systemPrompt,
  });

  @override
  State<AiAssistDialog> createState() => _AiAssistDialogState();
}

class _AiAssistDialogState extends State<AiAssistDialog> {
  final _inputCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _generate() async {
    final userInput = _inputCtrl.text.trim();
    if (userInput.isEmpty) {
      setState(() => _error = '请先描述你的需求');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().chat(
        'default',
        [
          {'role': 'system', 'content': widget.systemPrompt},
          {'role': 'user', 'content': userInput},
        ],
        null,
        null,
      );
      String result = '';
      if (res is Map) {
        result = (res['content'] ??
                res['reply'] ??
                res['message'] ??
                res['text'] ??
                '')
            .toString();
      }
      if (result.isEmpty) {
        setState(() => _error = 'AI未返回内容，请重试');
        return;
      }
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      setState(() => _error = '生成失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: _kPrimary, size: 22),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 输入框
            TextField(
              controller: _inputCtrl,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hint,
                filled: true,
                fillColor: const Color(0xFFFFF5F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kPrimary, width: 2),
                ),
              ),
            ),
            // 错误提示
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            // 按钮行
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('取消',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _loading ? null : _generate,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('让AI写'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
