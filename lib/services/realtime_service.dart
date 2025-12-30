import 'dart:async';
import '../api/index.dart';
import '../models/pump_data.dart';

/// 实时数据服务
/// 功能: 定时获取后端实时数据，并通过回调通知界面更新
class RealtimeService {
  final ApiClient _apiClient = ApiClient();

  Timer? _pollTimer;
  bool _isPolling = false;

  // 数据更新回调
  void Function(RealtimeBatchResponse)? onDataUpdate;
  void Function(String)? onError;

  /// 轮询间隔 (秒) - 与后端同步
  int pollIntervalSeconds = 5;

  /// 获取批量实时数据 (6个水泵 + 1个压力表)
  Future<RealtimeBatchResponse> fetchRealtimeData() async {
    try {
      final response = await _apiClient.get(Api.realtimeBatch);

      if (response != null) {
        final data = RealtimeBatchResponse.fromJson(response);
        return data;
      }
    } catch (e) {
      print('[RealtimeService] 获取实时数据失败: $e');
      onError?.call(e.toString());
    }

    return RealtimeBatchResponse.empty();
  }

  /// 获取单个水泵实时数据
  Future<PumpData?> fetchPumpData(int pumpId) async {
    try {
      final response = await _apiClient.get(Api.realtimePump(pumpId));

      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          return PumpData.fromJson(data);
        }
      }
    } catch (e) {
      print('[RealtimeService] 获取水泵 $pumpId 数据失败: $e');
    }

    return null;
  }

  /// 获取压力表数据
  Future<PressureData?> fetchPressureData() async {
    try {
      final response = await _apiClient.get(Api.realtimePressure);

      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          return PressureData.fromJson(data);
        }
      }
    } catch (e) {
      print('[RealtimeService] 获取压力数据失败: $e');
    }

    return null;
  }

  /// 启动定时轮询
  void startPolling({int intervalSeconds = 5}) {
    if (_isPolling) return;

    pollIntervalSeconds = intervalSeconds;
    _isPolling = true;

    // 立即获取一次
    _poll();

    // 定时轮询
    _pollTimer = Timer.periodic(
      Duration(seconds: pollIntervalSeconds),
      (_) => _poll(),
    );

    print('[RealtimeService] 启动轮询，间隔: ${pollIntervalSeconds}s');
  }

  /// 停止轮询
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
    print('[RealtimeService] 停止轮询');
  }

  /// 执行一次轮询
  Future<void> _poll() async {
    final data = await fetchRealtimeData();
    onDataUpdate?.call(data);
  }

  /// 手动刷新一次
  Future<RealtimeBatchResponse> refresh() async {
    return await fetchRealtimeData();
  }

  /// 是否正在轮询
  bool get isPolling => _isPolling;

  void dispose() {
    stopPolling();
  }
}
