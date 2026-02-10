// 后端 API 地址统一管理 - 水泵房监控系统
// ============================================================
// 后端端口: 8081 | 协议: HTTP REST API
// ============================================================

class Api {
  // ============================================================
  // 1, 基础地址 (后端 FastAPI 服务)
  // ============================================================
  static const String baseUrl = 'http://localhost:8081';

  // ============================================================
  // 健康检查接口
  // ============================================================

  /// 2, 基础健康检查 (仅检查服务存活)
  static const String health = '/health';

  /// 3, 水泵服务健康检查 (返回 PLC/DB 连接状态)
  static const String waterpumpHealth = '/api/waterpump/health';

  /// 4, 系统状态 (PLC 连接、DB 连接、轮询状态)
  static const String status = '/api/waterpump/status';

  // ============================================================
  // 实时数据接口 (5s 轮询)
  // ============================================================

  /// 5, 批量获取所有水泵 + 压力表实时数据
  static const String realtimeBatch = '/api/waterpump/realtime/batch';

  /// 6, 单个水泵实时数据 (pumpId: 1-6)
  static String realtimePump(int pumpId) => '/api/waterpump/realtime/$pumpId';

  /// 7, 压力表实时数据
  static const String realtimePressure = '/api/waterpump/realtime/pressure';

  // ============================================================
  // 历史数据接口 (InfluxDB 查询)
  // ============================================================

  /// 8, 统一历史数据查询接口
  /// 参数: parameter(power/energy/current/voltage/pressure/vibration_velocity/vibration_displacement/vibration_frequency)
  ///       pump_id(1-6, 压力查询时不需要), interval(5s/1m/5m/1h, 可选), start, end (ISO 8601)
  /// 示例: /api/waterpump/history?parameter=power&pump_id=1&start=2024-01-01T00:00:00Z&end=2024-01-02T00:00:00Z
  static const String history = '/api/waterpump/history';

  /// 9, 统计数据 (日/周/月汇总)
  static const String statistics = '/api/waterpump/statistics';

  // ============================================================
  // 阈值配置接口
  // ============================================================

  /// 10, 获取所有阈值配置
  static const String thresholds = '/api/thresholds';

  /// 11, 更新阈值配置
  static const String thresholdsUpdate = '/api/thresholds';

  /// 12, 重置阈值为默认值
  static const String thresholdsReset = '/api/thresholds/reset';

  // ============================================================
  // 报警日志接口
  // ============================================================

  /// 13, 查询最近报警记录 (新API)
  static const String alarmsRecent = '/api/thresholds/alarms/recent';

  /// 14, 查询报警日志 (旧API，兼容)
  static const String alarms = '/api/waterpump/alarms';

  /// 15, 报警统计 (各类型报警数量)
  static const String alarmsCount = '/api/waterpump/alarms/count';

  // ============================================================
  // 设备状态位接口 (DB3 通信状态)
  // ============================================================

  /// 13, 获取设备通信状态 (6 泵 + 1 压力表的在线/离线状态)
  static const String deviceStatus = '/api/waterpump/status/devices';

  // ============================================================
  // WebSocket 接口 (实时数据推送)
  // ============================================================

  /// 14, WebSocket 基础地址
  static String get wsBaseUrl => baseUrl
      .replaceFirst('http://', 'ws://')
      .replaceFirst('https://', 'wss://');

  /// 15, WebSocket 实时数据端点
  static String get wsUrl => '$wsBaseUrl/ws/realtime';
}
