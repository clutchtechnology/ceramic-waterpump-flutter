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

  /// 8, 历史数据查询
  /// 参数: pump_id(1-6), parameter(voltage/current/power/pressure),
  ///       interval(5s/1m/5m/1h), start, end (ISO 8601)
  static const String history = '/api/waterpump/history';

  /// 9, 统计数据 (日/周/月汇总)
  static const String statistics = '/api/waterpump/statistics';

  // ============================================================
  // 阈值配置接口
  // ============================================================

  /// 10, 获取/设置阈值配置 (压力、振动报警阈值)
  static const String thresholds = '/api/waterpump/config/thresholds';

  // ============================================================
  // 报警日志接口
  // ============================================================

  /// 11, 查询报警日志 (支持分页和时间范围)
  static const String alarms = '/api/waterpump/alarms';

  /// 12, 报警统计 (各类型报警数量)
  static const String alarmsCount = '/api/waterpump/alarms/count';

  // ============================================================
  // 设备状态位接口 (DB3 通信状态)
  // ============================================================

  /// 13, 获取设备通信状态 (6 泵 + 1 压力表的在线/离线状态)
  static const String deviceStatus = '/api/waterpump/status/devices';
}
