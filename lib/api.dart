import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://103.236.99.177:24512';

class Api {
  static String? _token;

  static Future<String?> get token async {
    if (_token != null) return _token;
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString('token');
    return _token;
  }

  static Future<void> setToken(String? t) async {
    _token = t;
    final sp = await SharedPreferences.getInstance();
    if (t == null) {
      await sp.remove('token');
      await sp.remove('username');
    } else {
      await sp.setString('token', t);
    }
  }

  static Future<Map<String, String>> _headers() async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final h = await _headers();
    final r = await http.post(Uri.parse('$baseUrl$path'), headers: h, body: jsonEncode(body));
    final d = jsonDecode(r.body);
    if (r.statusCode >= 400) throw d['error'] ?? '请求失败';
    return d;
  }

  static Future<dynamic> _get(String path) async {
    final h = await _headers();
    final r = await http.get(Uri.parse('$baseUrl$path'), headers: h);
    final d = jsonDecode(r.body);
    if (r.statusCode >= 400) throw d['error'] ?? '请求失败';
    return d;
  }

  static Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final h = await _headers();
    final r = await http.put(Uri.parse('$baseUrl$path'), headers: h, body: jsonEncode(body));
    final d = jsonDecode(r.body);
    if (r.statusCode >= 400) throw d['error'] ?? '请求失败';
    return d;
  }

  static Future<dynamic> _del(String path) async {
    final h = await _headers();
    final r = await http.delete(Uri.parse('$baseUrl$path'), headers: h);
    final d = jsonDecode(r.body);
    if (r.statusCode >= 400) throw d['error'] ?? '请求失败';
    return d;
  }

  static Future<Map<String, dynamic>> register(String u, String p) async {
    final r = await http.post(Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': u, 'password': p}));
    final d = jsonDecode(r.body);
    if (r.statusCode >= 400) throw d['error'] ?? '注册失败';
    await setToken(d['token']);
    final sp = await SharedPreferences.getInstance();
    await sp.setString('username', d['username']);
    return d;
  }

  static Future<Map<String, dynamic>> login(String u, String p) async {
    final r = await http.post(Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': u, 'password': p}));
    final d = jsonDecode(r.body);
    if (r.statusCode >= 400) throw d['error'] ?? '登录失败';
    await setToken(d['token']);
    final sp = await SharedPreferences.getInstance();
    await sp.setString('username', d['username']);
    return d;
  }

  static Future<void> logout() async => await setToken(null);

  static Future<dynamic> getCharacters({int page = 1, int limit = 20, String category = ''}) {
    return _get('/api/characters?page=$page&limit=$limit&category=$category');
  }

  static Future<dynamic> getCharacterDetail(String id) => _get('/api/characters/$id');

  static Future<dynamic> likeCharacter(String id) => _post('/api/characters/$id/like', {});

  static Future<dynamic> reportCharacter(String id, String reason) =>
      _post('/api/characters/$id/report', {'reason': reason});

  static Future<dynamic> commentCharacter(String id, String content) =>
      _post('/api/characters/$id/comment', {'content': content});

  static Future<dynamic> getCharacterComments(String id) => _get('/api/characters/$id/comments');

  static Future<dynamic> createCharacter(Map<String, dynamic> data) => _post('/api/characters', data);

  static Future<dynamic> generatePortrait(String prompt) => _post('/api/generate-portrait', {'prompt': prompt});

  static Future<dynamic> chat({required String model, required List<Map<String, String>> messages, String? characterId}) {
    final body = <String, dynamic>{'model': model, 'messages': messages};
    if (characterId != null) body['characterId'] = characterId;
    return _post('/api/chat', body);
  }

  static Future<dynamic> getPartner() => _get('/api/partner');
  static Future<dynamic> updatePartner(Map<String, dynamic> data) => _put('/api/partner', data);

  static Future<dynamic> getStories() => _get('/api/stories');
  static Future<dynamic> createStory(Map<String, dynamic> data) => _post('/api/stories', data);
  static Future<dynamic> updateStory(String id, Map<String, dynamic> data) => _put('/api/stories/$id', data);
  static Future<dynamic> deleteStory(String id) => _del('/api/stories/$id');

  static Future<dynamic> getUsage() => _get('/api/usage');
  static Future<dynamic> sendFeedback(String content) => _post('/api/feedback', {'content': content});
  static Future<dynamic> me() => _get('/api/me');

  static String portraitUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
