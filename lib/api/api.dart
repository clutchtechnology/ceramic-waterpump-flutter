/// 后端 API 地址统一管理
/// 水泵房监控系统 - 后端端口: 8081

class Api {
  // 基础地址 (后端服务地址)
  static const String baseUrl = 'http://localhost:8081';

  // ==================== 健康检查 ====================
  /// 基础健康检查
  static const String health = '/health';

  /// 水泵服务健康检查 (返回详细状态)
  static const String waterpumpHealth = '/api/waterpump/health';

  /// 系统状态 (PLC、DB连接状态)
  static const String status = '/api/waterpump/status';

  // ==================== 实时数据 ====================
  /// 批量获取所有水泵 + 压力表实时数据
  static const String realtimeBatch = '/api/waterpump/realtime/batch';

  /// 单个水泵实时数据
  static String realtimePump(int pumpId) => '/api/waterpump/realtime/$pumpId';

  /// 压力表实时数据
  static const String realtimePressure = '/api/waterpump/realtime/pressure';

  // ==================== 历史数据 ====================
  /// 历史数据查询
  /// 参数: pump_id, parameter, interval, start, end
  static const String history = '/api/waterpump/history';

  /// 统计数据
  static const String statistics = '/api/waterpump/statistics';

  // ==================== 阈值配置 ====================
  /// 获取/设置阈值配置
  static const String thresholds = '/api/waterpump/config/thresholds';

  // ==================== 报警日志 ====================
  /// 查询报警日志
  static const String alarms = '/api/waterpump/alarms';

  /// 报警统计
  static const String alarmsCount = '/api/waterpump/alarms/count';
}
