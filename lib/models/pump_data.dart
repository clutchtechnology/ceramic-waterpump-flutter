// 水泵数据模型 - 水泵房监控系统
// ============================================================
// 功能: 解析后端 API 返回的 JSON 数据，提供类型安全访问
// ============================================================

// ============================================================
// 1, 单个水泵实时数据 (对应 DB8 数据块)
// ============================================================
class PumpData {
  // 2, 水泵编号 (1-6)
  final int id;

  // 3, 电压值 (V) - 三相电压均值
  final double voltage;

  // 4, 电流值 (A) - 三相电流均值
  final double current;

  // 5, 功率值 (kW) - 有功功率
  final double power;

  // 6, 运行状态 (normal/warning/alarm/offline)
  final String status;

  // 7, 当前报警列表
  final List<String> alarms;

  PumpData({
    required this.id,
    required this.voltage,
    required this.current,
    required this.power,
    required this.status,
    required this.alarms,
  });

  factory PumpData.fromJson(Map<String, dynamic> json) {
    return PumpData(
      // 2, 解析水泵编号
      id: json['id'] as int? ?? 0,
      // 3, 解析电压 (num -> double 安全转换)
      voltage: (json['voltage'] as num?)?.toDouble() ?? 0.0,
      // 4, 解析电流
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      // 5, 解析功率
      power: (json['power'] as num?)?.toDouble() ?? 0.0,
      // 6, 解析状态
      status: json['status'] as String? ?? 'unknown',
      // 7, 解析报警列表
      alarms: (json['alarms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  // 4, 是否运行中 (电流 > 0.1A 表示电机启动)
  bool get isRunning => current > 0.1;

  // 6, 是否有报警
  bool get hasAlarm => status == 'alarm' || alarms.isNotEmpty;

  // 6, 是否有警告
  bool get hasWarning => status == 'warning';

  /// 创建离线状态空数据
  factory PumpData.empty(int id) {
    return PumpData(
      id: id,
      voltage: 0.0,
      current: 0.0,
      power: 0.0,
      status: 'offline',
      alarms: [],
    );
  }
}

// ============================================================
// 8, 压力表数据 (对应 DB8 压力传感器)
// ============================================================
class PressureData {
  // 9, 压力值 (MPa)
  final double value;

  // 10, 状态 (normal/warning/alarm/offline)
  final String status;

  PressureData({
    required this.value,
    required this.status,
  });

  factory PressureData.fromJson(Map<String, dynamic> json) {
    return PressureData(
      // 9, 解析压力值
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      // 10, 解析状态
      status: json['status'] as String? ?? 'unknown',
    );
  }

  /// 创建离线状态空数据
  factory PressureData.empty() {
    return PressureData(value: 0.0, status: 'offline');
  }
}

// ============================================================
// 11, 批量实时数据响应 (聚合 6 泵 + 1 压力表)
// ============================================================
class RealtimeBatchResponse {
  // 12, 请求是否成功
  final bool success;

  // 13, 数据时间戳 (ISO 8601)
  final String timestamp;

  // 14, 数据来源 (mock/plc)
  final String source;

  // 15, 6 个水泵数据列表
  final List<PumpData> pumps;

  // 16, 压力表数据
  final PressureData pressure;

  RealtimeBatchResponse({
    required this.success,
    required this.timestamp,
    required this.source,
    required this.pumps,
    required this.pressure,
  });

  factory RealtimeBatchResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final pumpsJson = data['pumps'] as List<dynamic>? ?? [];
    final pressureJson = data['pressure'] as Map<String, dynamic>? ?? {};

    return RealtimeBatchResponse(
      // 12, 解析成功标志
      success: json['success'] as bool? ?? false,
      // 13, 解析时间戳
      timestamp: json['timestamp'] as String? ?? '',
      // 14, 解析数据来源
      source: json['source'] as String? ?? 'unknown',
      // 15, 解析水泵列表
      pumps: pumpsJson
          .map((e) => PumpData.fromJson(e as Map<String, dynamic>))
          .toList(),
      // 16, 解析压力数据
      pressure: PressureData.fromJson(pressureJson),
    );
  }

  /// 创建空响应 (网络错误时使用)
  factory RealtimeBatchResponse.empty() {
    return RealtimeBatchResponse(
      success: false,
      timestamp: '',
      source: 'none',
      pumps: List.generate(6, (i) => PumpData.empty(i + 1)),
      pressure: PressureData.empty(),
    );
  }

  /// 15, 获取指定水泵数据 (安全方式，避免异常)
  PumpData? getPump(int id) {
    for (final pump in pumps) {
      if (pump.id == id) return pump;
    }
    return null;
  }
}

// ============================================================
// 17, 健康检查响应
// ============================================================
class HealthResponse {
  // 18, 后端服务是否存活
  final bool serverHealthy;

  // 19, PLC 是否连接
  final bool plcConnected;

  // 20, InfluxDB 是否连接
  final bool dbConnected;

  // 21, 错误信息
  final String? error;

  HealthResponse({
    required this.serverHealthy,
    required this.plcConnected,
    required this.dbConnected,
    this.error,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      // 18, 能解析说明服务存活
      serverHealthy: true,
      // 19, 解析 PLC 连接状态
      plcConnected: json['plc_connected'] as bool? ?? false,
      // 20, 解析 DB 连接状态
      dbConnected: json['db_connected'] as bool? ?? false,
      // 21, 解析错误信息
      error: json['error'] as String?,
    );
  }

  /// 创建离线响应
  factory HealthResponse.offline() {
    return HealthResponse(
      serverHealthy: false,
      plcConnected: false,
      dbConnected: false,
      error: '无法连接到后端服务',
    );
  }

  // 18+19+20, 判断全部健康
  bool get allHealthy => serverHealthy && plcConnected && dbConnected;
}

// ============================================================
// 22, 系统状态响应
// ============================================================
class StatusResponse {
  final bool success;

  // 23, PLC 连接状态 (connected/disconnected/error)
  final String plcStatus;

  // 24, DB 连接状态
  final String dbStatus;

  // 25, 轮询状态 (running/stopped)
  final String pollingStatus;

  // 26, 上次轮询时间戳
  final int? lastPollTime;

  StatusResponse({
    required this.success,
    required this.plcStatus,
    required this.dbStatus,
    required this.pollingStatus,
    this.lastPollTime,
  });

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return StatusResponse(
      success: json['success'] as bool? ?? false,
      // 23, 解析 PLC 状态
      plcStatus: data['plc_status'] as String? ?? 'unknown',
      // 24, 解析 DB 状态
      dbStatus: data['db_status'] as String? ?? 'unknown',
      // 25, 解析轮询状态
      pollingStatus: data['polling_status'] as String? ?? 'unknown',
      // 26, 解析上次轮询时间
      lastPollTime: data['last_poll_time'] as int?,
    );
  }

  // 23, PLC 是否已连接
  bool get plcConnected => plcStatus == 'connected';

  // 24, DB 是否已连接
  bool get dbConnected => dbStatus == 'connected';
}
