import 'package:flutter/material.dart';
import '../api.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  dynamic _partner;
  List<dynamic> _chars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([Api.getPartner(), Api.getCharacters(limit: 10)]);
      setState(() {
        _partner = results[0];
        _chars = results[1]['list'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('消息'), centerTitle: true),
      body: ListView(
        children: [
          if (_partner != null)
            ListTile(
              leading: CircleAvatar(
                child: Text(_partner['name']?[0] ?? '悟'),
              ),
              title: Text(_partner['name'] ?? '悟悟'),
              subtitle: Text(_partner['greeting'] ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(
                title: _partner['name'] ?? '悟悟',
                characterName: _partner['name'] ?? '',
                portrait: _partner['portrait'],
                greeting: _partner['greeting'],
              ))),
            ),
          const Divider(),
          ..._chars.map((c) => ListTile(
            leading: CircleAvatar(child: Text(c['name']?[0] ?? '?')),
            title: Text(c['name'] ?? ''),
            subtitle: Text(c['description'] ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(
              title: c['name'] ?? '',
              characterName: c['name'] ?? '',
              portrait: c['portrait'],
              characterId: c['id'],
              greeting: c['greeting'],
            ))),
          )),
        ],
      ),
    );
  }
}
