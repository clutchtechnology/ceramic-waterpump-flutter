// 网络请求统一入口 - 水泵监控系统 HTTP Client
// ============================================================
// 功能: 统一管理 HTTP 请求，支持自动重试和连接池管理
// ============================================================

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'api.dart';

// ============================================================
// 1, HTTP 请求方法枚举 (用于统一请求处理)
// ============================================================
enum _HttpMethod { get, post }

class ApiClient {
  // ============================================================
  // 2, 单例模式 (全局唯一 HTTP 客户端管理器)
  // ============================================================
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // 3, 后端服务地址 (可动态配置)
  String _baseUrl = Api.baseUrl;

  // 4, HTTP Client 实例 (支持重建以解决连接池问题)
  http.Client _httpClient = http.Client();

  // 5, 请求超时时间 (工控环境网络通常稳定，5秒足够)
  static const Duration _timeout = Duration(seconds: 5);

  // 6, 最大重试次数
  static const int _maxRetries = 2;

  // 7, 连续失败计数 (用于日志频率控制)
  int _failureCount = 0;

  /// 获取当前基础 URL
  String get baseUrl => _baseUrl;

  /// 3, 设置基础 URL (支持动态切换后端地址)
  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  // ============================================================
  // 公共 API 方法
  // ============================================================

  /// GET 请求
  Future<dynamic> get(String path, {Map<String, String>? params}) {
    // 8, 调用统一请求方法
    return _request(_HttpMethod.get, path, params: params);
  }

  /// POST 请求
  Future<dynamic> post(String path,
      {Map<String, String>? params, dynamic body}) {
    // 8, 调用统一请求方法
    return _request(_HttpMethod.post, path, params: params, body: body);
  }

  // ============================================================
  // 核心请求逻辑 (奥卡姆剃刀: 合并 GET/POST 重复代码)
  // ============================================================

  /// 8, 统一请求方法 (支持自动重试)
  Future<dynamic> _request(
    _HttpMethod method,
    String path, {
    Map<String, String>? params,
    dynamic body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);
    final methodName = method == _HttpMethod.get ? 'GET' : 'POST';

    // 6, 重试循环 (最多 _maxRetries 次)
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        // 9, 执行 HTTP 请求
        final response = await _executeRequest(method, uri, body);

        // 7, 请求成功，重置失败计数
        _failureCount = 0;

        // 10, 处理响应
        return _processResponse(response, uri.toString());
      } catch (e) {
        // 11, 判断是否需要重建客户端
        final needRecreate = _isConnectionError(e);

        // 最后一次重试失败
        if (attempt == _maxRetries - 1) {
          _logError(methodName, uri.toString(), e.toString());
          rethrow;
        }

        // 4, 连接错误时重建 HTTP Client
        if (needRecreate) {
          _recreateClient();
        }
        // 非最后一次，继续重试
      }
    }
    throw Exception('请求失败: $path');
  }

  /// 9, 执行单次 HTTP 请求
  Future<http.Response> _executeRequest(
    _HttpMethod method,
    Uri uri,
    dynamic body,
  ) async {
    // 5, 所有请求必须设置超时
    switch (method) {
      case _HttpMethod.get:
        return _httpClient.get(uri).timeout(_timeout);
      case _HttpMethod.post:
        return _httpClient.post(
          uri,
          body: body != null ? jsonEncode(body) : null,
          headers: {'Content-Type': 'application/json'},
        ).timeout(_timeout);
    }
  }

  /// 10, 处理 HTTP 响应
  dynamic _processResponse(http.Response response, String url) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        // JSON 解析失败，返回错误结构而非 null
        _logError('JSON', url, '解析失败');
        return {'success': false, 'error': 'JSON 解析失败', 'data': null};
      }
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  // ============================================================
  // 错误处理与客户端管理
  // ============================================================

  /// 11, 检查是否为连接类错误 (需要重建客户端)
  bool _isConnectionError(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    return errorStr.contains('connection closed') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection reset') ||
        errorStr.contains('socketexception');
  }

  /// 4, 重建 HTTP Client (解决连接池过期/卡死问题)
  void _recreateClient() {
    _httpClient.close();
    _httpClient = http.Client();
  }

  /// 7, 日志输出 (频率控制: 前3次 + 每10次)
  void _logError(String method, String url, String error) {
    _failureCount++;
    if (_failureCount <= 3 || _failureCount % 10 == 0) {
      // ignore: avoid_print
      print('[API] $method 失败 ($_failureCount): $error');
    }
  }

  /// 2, 释放资源 (应用退出时调用)
  static void dispose() {
    _instance._httpClient.close();
  }
}
