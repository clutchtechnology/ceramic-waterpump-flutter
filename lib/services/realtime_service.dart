import 'dart:async';
import '../api/index.dart';
import '../models/pump_data.dart';

/// 实时数据服务
/// 功能: 定时获取后端实时数据，并通过回调通知界面更新
class RealtimeService {
  // 1, API 客户端单例
  final ApiClient _apiClient = ApiClient();

  // 2, 轮询定时器
  Timer? _pollTimer;

  // 3, 轮询状态标记
  bool _isPolling = false;

  // 4, 是否已释放 (防止 dispose 后继续轮询)
  bool _isDisposed = false;

  // 5, 数据更新回调
  void Function(RealtimeBatchResponse)? onDataUpdate;

  // 6, 错误回调
  void Function(String)? onError;

  /// 7, 轮询间隔 (秒) - 与后端同步，默认 5 秒
  int pollIntervalSeconds = 5;

  /// 1, 获取批量实时数据 (6 个水泵 + 1 个压力表)
  Future<RealtimeBatchResponse> fetchRealtimeData() async {
    try {
      final response = await _apiClient.get(Api.realtimeBatch);

      if (response != null) {
        return RealtimeBatchResponse.fromJson(response);
      }
    } catch (e) {
      // 6, 通知错误回调
      onError?.call(e.toString());
    }

    return RealtimeBatchResponse.empty();
  }

  /// 2, 启动定时轮询
  void startPolling({int intervalSeconds = 5}) {
    // 3, 防止重复启动
    if (_isPolling || _isDisposed) return;

    pollIntervalSeconds = intervalSeconds;
    _isPolling = true;

    // 2.1, 立即获取一次
    _poll();

    // 2.2, 定时轮询
    _pollTimer = Timer.periodic(
      Duration(seconds: pollIntervalSeconds),
      (_) {
        // 3, 检查轮询状态和释放状态
        if (!_isPolling || _isDisposed) {
          _pollTimer?.cancel();
          return;
        }
        _poll();
      },
    );
  }

  /// 2, 停止轮询
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  /// 2, 执行一次轮询 (带异常保护)
  Future<void> _poll() async {
    // 3, 4, 防止并发轮询和释放后轮询
    if (!_isPolling || _isDisposed) return;

    try {
      final data = await fetchRealtimeData();
      // 5, 通知数据更新
      if (!_isDisposed) {
        onDataUpdate?.call(data);
      }
    } catch (e) {
      // 6, 捕获所有异常，防止 Timer 回调崩溃导致 UI 卡死
      if (!_isDisposed) {
        onError?.call(e.toString());
      }
    }
  }

  /// 手动刷新一次
  Future<RealtimeBatchResponse> refresh() async {
    return await fetchRealtimeData();
  }

  /// 3, 是否正在轮询
  bool get isPolling => _isPolling;

  /// 释放资源
  void dispose() {
    _isDisposed = true; // 4, 标记已释放
    stopPolling();
    onDataUpdate = null; // 5, 清空回调防止泄漏
    onError = null; // 6, 清空回调防止泄漏
  }
}
