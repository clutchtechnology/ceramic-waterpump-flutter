/// 网络请求统一入口
/// 用于处理全局的网络请求配置、拦截器、基础请求方法等

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'api.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String _baseUrl = Api.baseUrl;

  // HTTP Client 管理 (支持重建)
  static http.Client? _httpClient;
  static http.Client get _client {
    _httpClient ??= http.Client();
    return _httpClient!;
  }

  // 请求超时配置
  static const Duration _timeout = Duration(seconds: 5);

  // 连续失败计数（用于日志记录和重建判断）
  int _consecutiveFailures = 0;

  /// 重建 HTTP Client (解决连接池过期问题)
  static void _recreateClient() {
    _httpClient?.close();
    _httpClient = http.Client();
  }

  /// 检查是否为需要重建客户端的连接错误
  static bool _isConnectionError(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    return errorStr.contains('connection closed') ||
        errorStr.contains('connection attempt cancelled') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection reset') ||
        errorStr.contains('socketexception');
  }

  /// 获取当前基础 URL
  String get baseUrl => _baseUrl;

  /// 设置基础 URL (便于动态配置)
  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// GET 请求 (带自动重试)
  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);

    // 尝试最多2次 (首次 + 1次重试)
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client.get(uri).timeout(_timeout);
        _consecutiveFailures = 0; // 成功后重置失败计数
        return _processResponse(response, uri.toString());
      } on TimeoutException {
        if (attempt == 0) continue; // 首次超时直接重试
        _handleError('GET', uri.toString(),
            'Request timeout after ${_timeout.inSeconds}s');
        rethrow;
      } on http.ClientException catch (e) {
        // 连接错误，重建客户端后重试
        if (attempt == 0 && _isConnectionError(e)) {
          _recreateClient();
          continue;
        }
        _handleError('GET', uri.toString(), 'Client error: $e');
        rethrow;
      } catch (e) {
        // 其他错误（包括SocketException）也尝试重试
        if (attempt == 0 && _isConnectionError(e)) {
          _recreateClient();
          continue;
        }
        if (attempt == 0) continue; // 非连接错误也重试一次
        _handleError('GET', uri.toString(), e.toString());
        rethrow;
      }
    }
    throw Exception('请求失败');
  }

  /// POST 请求 (带自动重试)
  Future<dynamic> post(String path,
      {Map<String, String>? params, dynamic body}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);

    // 尝试最多2次 (首次 + 1次重试)
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client.post(
          uri,
          body: jsonEncode(body),
          headers: {'Content-Type': 'application/json'},
        ).timeout(_timeout);
        _consecutiveFailures = 0;
        return _processResponse(response, uri.toString());
      } on TimeoutException {
        if (attempt == 0) continue;
        _handleError('POST', uri.toString(),
            'Request timeout after ${_timeout.inSeconds}s');
        rethrow;
      } on http.ClientException catch (e) {
        if (attempt == 0 && _isConnectionError(e)) {
          _recreateClient();
          continue;
        }
        _handleError('POST', uri.toString(), 'Client error: $e');
        rethrow;
      } catch (e) {
        if (attempt == 0 && _isConnectionError(e)) {
          _recreateClient();
          continue;
        }
        if (attempt == 0) continue;
        _handleError('POST', uri.toString(), e.toString());
        rethrow;
      }
    }
    throw Exception('请求失败');
  }

  /// 处理响应
  dynamic _processResponse(http.Response response, String url) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 安全的 JSON 解析
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print('[API] JSON 解析失败: $url');
        return {'success': false, 'error': 'JSON 解析失败', 'data': null};
      }
    } else {
      _handleError('RESPONSE', url, 'HTTP ${response.statusCode}');
      throw Exception('网络请求错误: ${response.statusCode}');
    }
  }

  /// 处理错误
  void _handleError(String method, String url, String error) {
    _consecutiveFailures++;

    // 简化日志输出
    if (_consecutiveFailures <= 3 || _consecutiveFailures % 10 == 0) {
      print('[API] $method 失败 ($_consecutiveFailures): $error');
    }
  }

  /// 关闭 HTTP Client（应用退出时调用）
  static void dispose() {
    _httpClient?.close();
    _httpClient = null;
  }
}
