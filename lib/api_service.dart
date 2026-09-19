import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 从创建/详情页返回时通知主页重新加载最新列表。
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final String baseUrl = "http://103.236.99.177:24512";
  String? _token;
  SharedPreferences? _prefs;

  /// Global navigator key used to redirect to login when token expires.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    if (_token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  /// Build a full image URL from a backend-provided path.
  /// Backend returns e.g. "/static/portraits/xxx.png" → baseUrl + path.
  String imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$baseUrl/$path';
  }

  void _redirectToLogin() {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Navigator.of(ctx).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  Future<dynamic> _send(String method, String path,
      [Map<String, dynamic>? data]) async {
    final uri = Uri.parse('$baseUrl$path');
    // 关键：body 必须是 jsonEncode(data) 得到的字符串，Content-Type 为 application/json，
    // 不能把 Map 直接 toString()。使用 package:http 保证编码正确。
    final body = data == null ? null : jsonEncode(data);
    http.Response resp;
    switch (method) {
      case 'POST':
        resp = await http.post(uri, headers: _headers, body: body);
        break;
      case 'PUT':
        resp = await http.put(uri, headers: _headers, body: body);
        break;
      case 'DELETE':
        resp = await http.delete(uri, headers: _headers);
        break;
      default:
        resp = await http.get(uri, headers: _headers);
    }
    final status = resp.statusCode;
    final rbody = resp.body;
    if (status == 401) {
      await _saveToken(null);
      _redirectToLogin();
      throw ApiException(401, rbody);
    }
    if (status >= 400) {
      throw ApiException(status, rbody);
    }
    if (rbody.isEmpty) return {};
    return jsonDecode(rbody);
  }

  // ── Auth ──────────────────────────────────────────────

  Future<Map<String, dynamic>> register(String username, String password) async {
    final res = await _send('POST', '/api/auth/register', {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    if (res['token'] != null) {
      await _saveToken(res['token'].toString());
    }
    return res;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _send('POST', '/api/auth/login', {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    if (res['token'] != null) {
      await _saveToken(res['token'].toString());
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
    return await _send('GET', '/api/auth/me') as Map<String, dynamic>;
  }

  // ── Characters ────────────────────────────────────────

  Future<Map<String, dynamic>> getCharacters(int page, int pageSize) async {
    return await _send('GET', '/api/characters?page=$page&pageSize=$pageSize')
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCharacterDetail(String id) async {
    return await _send('GET', '/api/characters/$id') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createCharacter(Map<String, dynamic> data) async {
    return await _send('POST', '/api/characters', data) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> likeCharacter(String id) async {
    return await _send('POST', '/api/characters/$id/like') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reportCharacter(String id, String reason) async {
    return await _send('POST', '/api/characters/$id/report',
        {'reason': reason}) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> commentCharacter(String id, String content) async {
    return await _send('POST', '/api/characters/$id/comment',
        {'content': content}) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCharacterComments(String id) async {
    final res = await _send('GET', '/api/characters/$id/comments');
    if (res is List) return res;
    if (res is Map) return res['list'] ?? res['data'] ?? res['comments'] ?? [];
    return [];
  }

  Future<List<dynamic>> getMyCharacters() async {
    final res = await _send('GET', '/api/my/characters');
    if (res is List) return res;
    if (res is Map) return res['list'] ?? res['data'] ?? res['characters'] ?? [];
    return [];
  }

  Future<List<dynamic>> getMyStories() async {
    final res = await _send('GET', '/api/my/stories');
    if (res is List) return res;
    if (res is Map) return res['list'] ?? res['data'] ?? res['stories'] ?? [];
    return [];
  }

  Future<Map<String, dynamic>> createStory(Map<String, dynamic> data) async {
    return await _send('POST', '/api/stories', data) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStoryDetail(String id) async {
    return await _send('GET', '/api/stories/$id') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateStory(String id, Map<String, dynamic> data) async {
    return await _send('PUT', '/api/stories/$id', data) as Map<String, dynamic>;
  }

  // ── Chat ──────────────────────────────────────────────

  /// 非流式对话 → {reply, totalSeconds, break_reminder}
  Future<Map<String, dynamic>> chat(
    String model,
    List<Map<String, String>> messages,
    String? characterId,
    String? storyId,
  ) async {
    return await _send('POST', '/api/chat', {
      'model': model,
      'messages': messages,
      if (characterId != null) 'characterId': characterId,
      if (storyId != null) 'storyId': storyId,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveChat(
    String characterId,
    String? storyId,
    List<Map<String, String>> messages,
    String model,
  ) async {
    return await _send('POST', '/api/chat/save', {
      'characterId': characterId,
      if (storyId != null) 'storyId': storyId,
      'messages': messages,
      'model': model,
    }) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getChatHistory(String characterId, String? storyId) async {
    final qs = storyId != null ? '&storyId=$storyId' : '';
    final res = await _send('GET', '/api/chat/history?characterId=$characterId$qs');
    if (res is List) return res;
    if (res is Map) return res['messages'] ?? res['list'] ?? res['data'] ?? [];
    return [];
  }

  // ── Portrait / Partner / Usage ───────────────────────

  /// 生成立绘 → {imageUrl: "/static/portraits/xxx.png"}
  Future<Map<String, dynamic>> generatePortrait(String prompt) async {
    final res = await _send('POST', '/api/generate-portrait',
        {'prompt': prompt}) as Map<String, dynamic>;
    return res;
  }

  Future<Map<String, dynamic>> getPartner() async {
    return await _send('GET', '/api/partner') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePartner(String characterId) async {
    return await _send('PUT', '/api/partner',
        {'characterId': characterId}) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUsage() async {
    return await _send('GET', '/api/usage') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendFeedback(String content) async {
    return await _send('POST', '/api/feedback',
        {'content': content}) as Map<String, dynamic>;
  }

  // ── TTS ──────────────────────────────────────────────

  Future<Map<String, dynamic>> tts(String text, String voice) async {
    return await _send('POST', '/api/tts',
        {'text': text, 'voice': voice}) as Map<String, dynamic>;
  }

  // ── Story ─────────────────────────────────────────────

  Future<Map<String, dynamic>> storyChoice(String storyId, String choice) async {
    return await _send('POST', '/api/story/choice', {
      'storyId': storyId,
      'choice': choice,
    }) as Map<String, dynamic>;
  }

  // kept for logout compat
  Future<dynamic> _post(String path, [Map<String, dynamic>? data]) {
    return _send('POST', path, data);
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
      return json['message'] ?? json['detail'] ?? '请求失败 ($statusCode)';
    } catch (_) {
      if (statusCode == 401) return '登录已过期，请重新登录';
      return '请求失败 ($statusCode)';
    }
  }
}
