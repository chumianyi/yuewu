import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final String baseUrl = "http://103.236.99.177:24512";
  String? _token;
  SharedPreferences? _prefs;

  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _token = _prefs!.getString('auth_token');
  }

  Future<void> _saveToken(String? token) async {
    _token = token;
    if (token == null) {
      await _prefs?.remove('auth_token');
    } else {
      await _prefs?.setString('auth_token', token);
    }
  }

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, body);
      }
      return jsonDecode(body);
    } finally {
      client.close();
    }
  }

  Future<dynamic> _post(String path, [Map<String, dynamic>? data]) async {
    final uri = Uri.parse('$baseUrl$path');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      if (data != null) {
        request.write(jsonEncode(data));
      }
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, body);
      }
      return jsonDecode(body);
    } finally {
      client.close();
    }
  }

  Future<dynamic> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final client = HttpClient();
    try {
      final request = await client.deleteUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, body);
      }
      return jsonDecode(body);
    } finally {
      client.close();
    }
  }

  // ── Auth ──────────────────────────────────────────────

  Future<Map<String, dynamic>> register(String username, String password) async {
    final res = await _post('/api/auth/register', {
      'username': username,
      'password': password,
    });
    return res;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _post('/api/auth/login', {
      'username': username,
      'password': password,
    });
    if (res['token'] != null) {
      await _saveToken(res['token']);
    }
    return res;
  }

  Future<void> logout() async {
    try {
      await _post('/api/auth/logout');
    } catch (_) {}
    await _saveToken(null);
  }

  Future<Map<String, dynamic>> getMe() async {
    return await _get('/api/auth/me');
  }

  // ── Characters ────────────────────────────────────────

  Future<Map<String, dynamic>> getCharacters(int page, int pageSize) async {
    return await _get('/api/characters?page=$page&pageSize=$pageSize');
  }

  Future<Map<String, dynamic>> getCharacterDetail(int id) async {
    return await _get('/api/characters/$id');
  }

  Future<Map<String, dynamic>> createCharacter(Map<String, dynamic> data) async {
    return await _post('/api/characters', data);
  }

  Future<Map<String, dynamic>> likeCharacter(int id) async {
    return await _post('/api/characters/$id/like');
  }

  Future<Map<String, dynamic>> reportCharacter(int id, String reason) async {
    return await _post('/api/characters/$id/report', {'reason': reason});
  }

  Future<Map<String, dynamic>> commentCharacter(int id, String content) async {
    return await _post('/api/characters/$id/comments', {'content': content});
  }

  Future<List<dynamic>> getCharacterComments(int id) async {
    final res = await _get('/api/characters/$id/comments');
    if (res is List) return res;
    return res['data'] ?? res['comments'] ?? [];
  }

  Future<List<dynamic>> getMyCharacters() async {
    final res = await _get('/api/characters/my');
    if (res is List) return res;
    return res['data'] ?? res['characters'] ?? [];
  }

  Future<List<dynamic>> getMyStories() async {
    final res = await _get('/api/stories/my');
    if (res is List) return res;
    return res['data'] ?? res['stories'] ?? [];
  }

  Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) async {
    final res = await _post('/api/stories', data);
    return res as Map<String, dynamic>;
  }

  // ── Chat ──────────────────────────────────────────────

  /// 非流式对话，model 支持 "extreme"（极致模式）
  Future<Map<String, dynamic>> chat(
    String model,
    List<Map<String, String>> messages,
    int? characterId,
    int? storyId,
  ) async {
    return await _post('/api/chat', {
      'model': model,
      'messages': messages,
      if (characterId != null) 'characterId': characterId,
      if (storyId != null) 'storyId': storyId,
    });
  }

  /// SSE 流式对话，逐字返回内容片段
  Stream<String> chatStream(
    String model,
    List<Map<String, String>> messages,
    int? characterId,
    int? storyId,
  ) async* {
    final uri = Uri.parse('$baseUrl/api/chat/stream');
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      request.headers.set('Accept', 'text/event-stream');
      request.write(jsonEncode({
        'model': model,
        'messages': messages,
        if (characterId != null) 'characterId': characterId,
        if (storyId != null) 'storyId': storyId,
      }));
      final response = await request.close();
      if (response.statusCode >= 400) {
        final body = await response.transform(utf8.decoder).join();
        throw ApiException(response.statusCode, body);
      }
      final lines = response.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          final payload = line.substring(6).trim();
          if (payload == '[DONE]') break;
          try {
            final json = jsonDecode(payload);
            final delta = json['content'] ?? json['delta'] ?? json['text'];
            if (delta != null && delta.toString().isNotEmpty) {
              yield delta.toString();
            }
          } catch (_) {
            // 跳过非 JSON 行
          }
        }
      }
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> saveChat(
    int characterId,
    int? storyId,
    List<Map<String, String>> messages,
    String model,
  ) async {
    return await _post('/api/chat/save', {
      'characterId': characterId,
      if (storyId != null) 'storyId': storyId,
      'messages': messages,
      'model': model,
    });
  }

  Future<List<dynamic>> getChatHistory(int characterId, int? storyId) async {
    final qs = storyId != null ? '&storyId=$storyId' : '';
    final res = await _get('/api/chat/history?characterId=$characterId$qs');
    if (res is List) return res;
    return res['data'] ?? res['messages'] ?? [];
  }

  // ── Portrait / Partner / Usage ───────────────────────

  Future<Map<String, dynamic>> generatePortrait(String prompt) async {
    return await _post('/api/portrait/generate', {'prompt': prompt});
  }

  Future<Map<String, dynamic>> getPartner() async {
    return await _get('/api/partner');
  }

  Future<Map<String, dynamic>> updatePartner(int characterId) async {
    return await _post('/api/partner', {'characterId': characterId});
  }

  Future<Map<String, dynamic>> getUsage() async {
    return await _get('/api/usage');
  }

  Future<Map<String, dynamic>> sendFeedback(String content) async {
    return await _post('/api/feedback', {'content': content});
  }

  // ── TTS / ASR ────────────────────────────────────────

  /// 文字转语音，返回音频 URL
  Future<Map<String, dynamic>> tts(String text, String voice) async {
    return await _post('/api/tts', {'text': text, 'voice': voice});
  }

  /// 语音识别，上传音频文件，返回识别文字
  Future<Map<String, dynamic>> asr(File audioFile) async {
    final uri = Uri.parse('$baseUrl/api/asr');
    final request = await HttpClient().postUrl(uri);
    // 不设 Content-Type，让 HttpClient 自动处理 multipart
    request.headers.set('Accept', 'application/json');
    if (_token != null) {
      request.headers.set('Authorization', 'Bearer $_token');
    }
    final boundary = '----YueWuBoundary${DateTime.now().millisecondsSinceEpoch}';
    request.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');

    final length = await audioFile.length();
    final bytes = await audioFile.readAsBytes();
    request
      ..write('--$boundary\r\n')
      ..write('Content-Disposition: form-data; name="audio"; filename="audio.m4a"\r\n')
      ..write('Content-Type: audio/m4a\r\n\r\n')
      ..add(bytes)
      ..write('\r\n--$boundary--\r\n');

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, body);
    }
    return jsonDecode(body);
  }

  // ── Story ─────────────────────────────────────────────

  Future<Map<String, dynamic>> storyChoice(int storyId, String choice) async {
    return await _post('/api/stories/$storyId/choice', {'choice': choice});
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() {
    try {
      final json = jsonDecode(body);
      return json['message'] ?? '请求失败 ($statusCode)';
    } catch (_) {
      return '请求失败 ($statusCode)';
    }
  }
}
