// 设备状态位API服务
// ============================================================
// 功能:
//   - [SS-1] 获取 DB1/DB3 设备通信状态数据
//   - [SS-2] 后端已解析，前端直接使用
// ============================================================

import '../api/index.dart';
import '../models/sensor_status_model.dart';

/// [SS-1] 设备状态服务 - 负责查询 DB1/DB3 状态位
class SensorStatusService {
  final ApiClient _apiClient = ApiClient();

  /// 获取所有设备状态数据 (使用统一的ApiClient)
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
}
