import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 服务器配置模型。
/// [isDefault] 为 true 表示内置的「星悟主服」；
/// 自定义服务器由用户在首次选择界面中配置。
class ServerConfig {
  final String name;
  final String ip;
  final int port;
  final String protocol; // 'tcp' | 'udp'
  final String? apiKey; // 可选：对方服务器要求的 API Key
  final bool isDefault;

  const ServerConfig({
    required this.name,
    required this.ip,
    required this.port,
    this.protocol = 'tcp',
    this.apiKey,
    this.isDefault = false,
  });

  /// 星悟主服（内置）：真实地址以混淆密文形式保存在客户端代码中，
  /// 运行期解密，仓库与安装包内不出现明文 IP/端口。
  static const String _defaultHostCipher =
      'SEVWWUdsRUVAZhwBBQNDR1FCRG0='; // XOR(Base64) 混淆
  static const String _obfuscationKey = 'yuewu_sky_2024';

  static String _deobfuscate(String cipher) {
    final keyBytes = utf8.encode(_obfuscationKey);
    final data = base64.decode(cipher);
    final out = List<int>.generate(data.length, (i) => data[i] ^ keyBytes[i % keyBytes.length]);
    return utf8.decode(out);
  }

  static String get defaultHost => _deobfuscate(_defaultHostCipher);

  static const ServerConfig defaultServer = ServerConfig(
    name: '星悟主服',
    ip: '', // 解密后填充
    port: 24512,
    protocol: 'tcp',
    isDefault: true,
  );

  /// 星悟主服实例（真实地址解密）
  factory ServerConfig.mainServer() {
    final host = _deobfuscate(_defaultHostCipher);
    final sep = host.lastIndexOf(':');
    return ServerConfig(
      name: '星悟主服',
      ip: host.substring(0, sep),
      port: int.parse(host.substring(sep + 1)),
      protocol: 'tcp',
      isDefault: true,
    );
  }

  /// TCP 模式下的 HTTP 基地址
  String get baseUrl => 'http://$ip:$port';

  bool get isUdp => protocol == 'udp';

  Map<String, dynamic> toJson() => {
        'name': name,
        'ip': ip,
        'port': port,
        'protocol': protocol,
        if (apiKey != null) 'apiKey': apiKey,
        'isDefault': isDefault,
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        name: json['name'] ?? '自定义服务器',
        ip: json['ip'] ?? '',
        port: (json['port'] as num?)?.toInt() ?? 24512,
        protocol: json['protocol'] ?? 'tcp',
        apiKey: json['apiKey'] as String?,
        isDefault: json['isDefault'] == true,
      );
}

/// 服务器选择 / api.json 配置管理器（全局单例）。
class ServerManager {
  ServerManager._internal();
  static final ServerManager _instance = ServerManager._internal();
  factory ServerManager() => _instance;

  static const String kConfigured = 'server_configured';
  static const String kConfig = 'server_config';
  static const String kApiJsonCache = 'api_json_cache';

  SharedPreferences? _prefs;
  ServerConfig? _current;
  Map<String, dynamic>? _apiConfig; // 最近一次从服务器拉取的 api.json

  /// 是否已选择过服务器（首次选择完成后为 true）
  bool get isConfigured => _current != null;

  ServerConfig get current {
    final c = _current;
    if (c != null) return c;
    // 未配置时兜底返回内置主服（正常流程不会走到）
    return ServerConfig.mainServer();
  }

  ServerConfig? get currentOrNull => _current;

  /// api.json 内容（模型列表等），每次启动从服务器拉取。
  Map<String, dynamic>? get apiConfig => _apiConfig;

  /// 服务器提供的模型列表（[{id, name, ...}, ...]）
  List<Map<String, dynamic>> get models {
    final list = _apiConfig?['models'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return const [];
  }

  List<String> get modelIds => models
      .map((m) => (m['id'] ?? m['name'] ?? '').toString())
      .where((s) => s.isNotEmpty)
      .toList();

  /// 服务器是否开启正版校验（星悟主服默认开启）
  bool get officialValidation {
    final v = _apiConfig?['official_validation'];
    if (v is bool) return v;
    return _current?.isDefault ?? true;
  }

  String get serverName => _current?.name ?? '星悟主服';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(kConfig);
    if (raw != null) {
      try {
        _current = ServerConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (_current!.isDefault && _current!.ip.isEmpty) {
          _current = ServerConfig.mainServer();
        }
      } catch (_) {
        _current = null;
      }
    }
    // 读取上次缓存（离线兜底用）
    final cached = _prefs!.getString(kApiJsonCache);
    if (cached != null) {
      try {
        _apiConfig = jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {}
    }
  }

  /// 使用内置星悟主服
  Future<void> useMainServer() async {
    _current = ServerConfig.mainServer();
    _apiConfig = null;
    await _save();
  }

  /// 使用自定义服务器
  Future<void> useCustomServer({
    required String name,
    required String ip,
    required int port,
    String protocol = 'tcp',
    String? apiKey,
  }) async {
    _current = ServerConfig(
      name: name.trim().isEmpty ? '自定义服务器' : name.trim(),
      ip: ip.trim(),
      port: port,
      protocol: protocol,
      apiKey: apiKey?.trim().isEmpty ?? true ? null : apiKey!.trim(),
      isDefault: false,
    );
    _apiConfig = null;
    await _save();
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_current == null) {
      await _prefs!.remove(kConfig);
      await _prefs!.setBool(kConfigured, false);
    } else {
      await _prefs!.setString(kConfig, jsonEncode(_current!.toJson()));
      await _prefs!.setBool(kConfigured, true);
    }
  }

  /// 缓存 api.json（离线兜底）
  Future<void> cacheApiConfig(Map<String, dynamic> config) async {
    _prefs ??= await SharedPreferences.getInstance();
    _apiConfig = config;
    await _prefs!.setString(kApiJsonCache, jsonEncode(config));
  }
}
