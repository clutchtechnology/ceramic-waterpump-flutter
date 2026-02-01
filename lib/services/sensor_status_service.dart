// 设备状态位API服务
// ============================================================
// 功能:
//   - [SS-1] 获取 DB1/DB3 设备通信状态数据
//   - [SS-2] 支持 WebSocket 推送模式和 HTTP 降级模式
// ============================================================

import '../api/index.dart';
import '../models/sensor_status_model.dart';
import 'websocket_service.dart';

/// [SS-1] 设备状态服务 - 负责查询 DB1/DB3 状态位
/// 重构说明: 支持 WebSocket 推送模式
class SensorStatusService {
  final ApiClient _apiClient = ApiClient();
  final WebSocketService _wsService = WebSocketService();

  // 是否已订阅
  bool _isSubscribed = false;

  // 是否已释放
  bool _isDisposed = false;

  // 数据更新回调
  void Function(DeviceStatusResponse)? onDataUpdate;

  // 错误回调
  void Function(String)? onError;

  /// 1, 启动 WebSocket 订阅
  void startPolling() {
    if (_isSubscribed || _isDisposed) return;
    _isSubscribed = true;

    // 设置 WebSocket 回调
    _wsService.onDeviceStatusUpdate = (data) {
      if (!_isDisposed) {
        onDataUpdate?.call(data);
      }
    };

    // 连接 WebSocket (如果尚未连接)
    if (_wsService.state != WebSocketState.connected) {
      _wsService.connect();
    } else {
      _wsService.subscribeDeviceStatus();
    }
  }

  /// 2, 停止订阅
  void stopPolling() {
    if (!_isSubscribed) return;
    _isSubscribed = false;
    _wsService.unsubscribeDeviceStatus();
  }

  /// 3, 暂停订阅
  void pausePolling() {
    stopPolling();
  }

  /// 4, 恢复订阅
  void resumePolling() {
    if (_isDisposed) return;
    _isSubscribed = false;
    startPolling();
  }

  /// 获取所有设备状态数据 (HTTP 降级模式 / 手动刷新)
  Future<DeviceStatusResponse> getDeviceStatus() async {
    try {
      // 使用 ApiClient 统一处理超时和重试
      final response = await _apiClient.get(Api.deviceStatus);

      if (response != null) {
        return DeviceStatusResponse.fromJson(response);
      } else {
        return DeviceStatusResponse(
          success: false,
          error: '响应为空',
        );
      }
    } catch (e) {
      return DeviceStatusResponse(
        success: false,
        error: '网络错误: $e',
      );
    }
  }

  /// 是否正在接收数据
  bool get isPolling => _isSubscribed;

  /// 释放资源
  void dispose() {
    _isDisposed = true;
    stopPolling();
    onDataUpdate = null;
    onError = null;
  }
}
