import '../api/index.dart';
import '../models/pump_data.dart';

/// 健康状态检查服务
class HealthService {
  final ApiClient _apiClient = ApiClient();

  /// 检查后端服务健康状态
  /// 返回: 服务状态、PLC连接、数据库连接
  Future<HealthStatus> checkHealth() async {
    try {
      // 调用 /health 端点
      final response = await _apiClient.get(Api.health);

      if (response != null) {
        return HealthStatus(
          serverHealthy: true,
          plcHealthy: response['plc_connected'] ?? false,
          dbHealthy: response['db_connected'] ?? false,
        );
      }
    } catch (e) {
      // 服务不可达
      print('[HealthService] 健康检查失败: $e');
    }

    return HealthStatus(
      serverHealthy: false,
      plcHealthy: false,
      dbHealthy: false,
    );
  }

  /// 获取详细系统状态
  Future<StatusResponse?> getSystemStatus() async {
    try {
      final response = await _apiClient.get(Api.status);
      if (response != null) {
        return StatusResponse.fromJson(response);
      }
    } catch (e) {
      print('[HealthService] 获取系统状态失败: $e');
    }
    return null;
  }

  void dispose() {
    // ApiClient 是单例，不在这里关闭
  }
}

/// 健康状态模型
class HealthStatus {
  final bool serverHealthy;
  final bool plcHealthy;
  final bool dbHealthy;

  HealthStatus({
    required this.serverHealthy,
    required this.plcHealthy,
    required this.dbHealthy,
  });

  bool get allHealthy => serverHealthy && plcHealthy && dbHealthy;
}
