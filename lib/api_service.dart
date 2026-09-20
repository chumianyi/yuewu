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

  Future<Map<String, dynamic>> updateCharacter(
      String id, Map<String, dynamic> data) async {
    return await _send('PUT', '/api/characters/$id', data) as Map<String, dynamic>;
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

  /// 删除对话历史。before 为某条消息内容时，保留该条及之前；不传则全部清空。
  Future<Map<String, dynamic>> deleteChatHistory(
      String characterId, String? storyId, String? before) async {
    var path = '/api/chat/history/$characterId?';
    if (storyId != null) path += 'storyId=$storyId&';
    if (before != null) path += 'before=${Uri.encodeComponent(before)}';
    return await _send('DELETE', path) as Map<String, dynamic>;
  }

  // ── Portrait / Partner / Usage ───────────────────────

  /// 生成立绘 → {imageUrl: "/static/portraits/xxx.png"}
  /// model: "glm"（默认免费）或 "kolors"（高质量）
  Future<Map<String, dynamic>> generatePortrait(String prompt,
      {String model = 'glm'}) async {
    final res = await _send('POST', '/api/generate-portrait',
        {'prompt': prompt, 'model': model}) as Map<String, dynamic>;
    return res;
  }

  /// 读取用户选择的图片模型（默认 glm）
  Future<String> getImageModel() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString('image_model') ?? 'glm';
  }

  /// 记住用户选择的图片模型
  Future<void> setImageModel(String model) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString('image_model', model);
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

  // ── Privacy / Account Deletion / Random / Search / Home ──

  /// 获取隐私政策
  Future<Map<String, dynamic>> getPrivacyPolicy() async {
    return await _send('GET', '/api/privacy') as Map<String, dynamic>;
  }

  /// 注销当前账号（软删除）
  Future<Map<String, dynamic>> deleteAccount() async {
    final res = await _send('DELETE', '/api/auth/account') as Map<String, dynamic>;
    await _saveToken(null);
    return res;
  }

  /// 随机角色列表
  Future<List<dynamic>> getRandomCharacters(int count) async {
    final res = await _send('GET', '/api/characters/random?count=$count');
    if (res is Map) return res['list'] ?? [];
    return res is List ? res : [];
  }

  /// 全站搜索（角色 + 故事）
  Future<Map<String, dynamic>> search(String q) async {
    final enc = Uri.encodeQueryComponent(q);
    return await _send('GET', '/api/search?q=$enc') as Map<String, dynamic>;
  }

  /// 主页混合列表（角色 + 故事）
  Future<Map<String, dynamic>> getHome({int page = 1, int pageSize = 20}) async {
    return await _send('GET', '/api/home?page=$page&pageSize=$pageSize')
        as Map<String, dynamic>;
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

  // ── Interactive Drama ─────────────────────────────────

  Future<Map<String, dynamic>> interactiveCreate(String prompt) async {
    return await _send('POST', '/api/interactive/create',
        {'prompt': prompt}) as Map<String, dynamic>;
  }

  Future<List<dynamic>> interactiveList() async {
    final res = await _send('GET', '/api/interactive/list');
    if (res is Map) return res['list'] ?? [];
    return res is List ? res : [];
  }

  Future<Map<String, dynamic>> interactiveGet(String appId) async {
    return await _send('GET', '/api/interactive/$appId') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> interactiveChoice(String appId, String choice) async {
    return await _send('POST', '/api/interactive/$appId/choice',
        {'choice': choice}) as Map<String, dynamic>;
  }

  // ── Video ─────────────────────────────────────────────

  Future<Map<String, dynamic>> videoCreate(String name, String description) async {
    return await _send('POST', '/api/video/create',
        {'name': name, 'description': description}) as Map<String, dynamic>;
  }

  Future<List<dynamic>> videoList() async {
    final res = await _send('GET', '/api/video/list');
    if (res is Map) return res['list'] ?? [];
    return res is List ? res : [];
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
