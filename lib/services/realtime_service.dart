import 'dart:async';
import '../api/index.dart';
import '../models/pump_data.dart';
import 'websocket_service.dart';

/// 实时数据服务
/// 功能: 通过 WebSocket 接收后端实时数据推送，并通过回调通知界面更新
/// 重构说明: 从 HTTP 轮询改为 WebSocket 推送模式
class RealtimeService {
  // 1, WebSocket 服务单例
  final WebSocketService _wsService = WebSocketService();

  // 2, API 客户端 (仅用于 HTTP 降级模式)
  final ApiClient _apiClient = ApiClient();

  // 3, 是否已释放 (防止 dispose 后继续操作)
  bool _isDisposed = false;

  // 4, 是否已订阅
  bool _isSubscribed = false;

  // 5, 数据更新回调
  void Function(RealtimeBatchResponse)? onDataUpdate;

  // 6, 错误回调
  void Function(String)? onError;

  // 7, 连接状态回调
  void Function(WebSocketState)? onConnectionStateChanged;

  /// 1, 启动 WebSocket 订阅 (替代原 startPolling)
  void startPolling({int intervalSeconds = 5}) {
    // intervalSeconds 参数保留以保持 API 兼容，但 WebSocket 模式下无意义
    if (_isSubscribed || _isDisposed) return;
    _isSubscribed = true;

    // 1.1, 设置 WebSocket 回调
    _wsService.onRealtimeDataUpdate = (data) {
      if (!_isDisposed) {
        onDataUpdate?.call(data);
      }
    };

    _wsService.onError = (error) {
      if (!_isDisposed) {
        onError?.call(error);
      }
    };

    _wsService.onStateChanged = (state) {
      if (!_isDisposed) {
        onConnectionStateChanged?.call(state);
      }
    };

    // 1.2, 连接 WebSocket (如果尚未连接)
    if (_wsService.state != WebSocketState.connected) {
      _wsService.connect();
    } else {
      // 已连接，直接订阅
      _wsService.subscribeRealtime();
    }
  }

  /// 2, 停止订阅 (替代原 stopPolling)
  void stopPolling() {
    if (!_isSubscribed) return;
    _isSubscribed = false;

    // 取消订阅但不断开连接 (其他服务可能还在使用)
    _wsService.unsubscribeRealtime();
  }

  /// 3, 暂停订阅 (Tab 切出时调用)
  void pausePolling() {
    stopPolling();
  }

  /// 4, 恢复订阅 (Tab 切入时调用)
  void resumePolling() {
    if (_isDisposed) return;
    _isSubscribed = false; // 重置状态以便 startPolling 可以重新启动
    startPolling();
  }

  /// 5, 获取批量实时数据 (HTTP 降级模式 / 手动刷新)
  Future<RealtimeBatchResponse> fetchRealtimeData() async {
    try {
      final response = await _apiClient.get(Api.realtimeBatch);

      if (response != null) {
        return RealtimeBatchResponse.fromJson(response);
      }
    } catch (e) {
      onError?.call(e.toString());
    }

    return RealtimeBatchResponse.empty();
  }

  /// 6, 手动刷新一次 (通过 HTTP)
  Future<RealtimeBatchResponse> refresh() async {
    return await fetchRealtimeData();
  }

  /// 7, 是否正在接收数据
  bool get isPolling => _isSubscribed;

  /// 8, 当前连接状态
  WebSocketState get connectionState => _wsService.state;

  /// 9, 释放资源
  void dispose() {
    _isDisposed = true;
    stopPolling();
    onDataUpdate = null;
    onError = null;
    onConnectionStateChanged = null;
    // 注意: 不在这里 dispose WebSocket，因为它是单例，可能被其他服务使用
  }
}
