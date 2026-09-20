import 'package:flutter/material.dart';
import '../api_service.dart';
import '../l10n.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final _api = ApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.getPrivacyPolicy();
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocale.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('隐私政策')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF69B4)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: Text(l10n.t('重试'))),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _data?['title'] ?? '隐私政策',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '更新时间：${_data?['updatedAt'] ?? ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      if (_data?['intro'] != null)
                        Text(
                          _data!['intro'],
                          style: const TextStyle(fontSize: 14, height: 1.7, color: Colors.black87),
                        ),
                      const SizedBox(height: 20),
                      ...((_data?['sections'] as List? ?? []).map((s) {
                        final m = s as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['heading'] ?? '',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                              ),
                              const SizedBox(height: 8),
                              ...((m['items'] as List? ?? []).map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('·  ', style: TextStyle(color: Color(0xFFE91E63))),
                                        Expanded(
                                          child: Text(
                                            item.toString(),
                                            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))),
                            ],
                          ),
                        );
                      })),
                    ],
                  ),
                ),
    );
  }
}
