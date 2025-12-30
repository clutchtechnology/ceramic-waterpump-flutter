/// 水泵数据模型
/// 用于解析后端 API 返回的 JSON 数据

/// 单个水泵实时数据
class PumpData {
  final int id;
  final double voltage;
  final double current;
  final double power;
  final String status; // normal, warning, alarm
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
      id: json['id'] as int? ?? 0,
      voltage: (json['voltage'] as num?)?.toDouble() ?? 0.0,
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      power: (json['power'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'unknown',
      alarms: (json['alarms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// 是否运行中 (有电流说明在运行)
  bool get isRunning => current > 0.1;

  /// 是否有报警
  bool get hasAlarm => status == 'alarm' || alarms.isNotEmpty;

  /// 是否有警告
  bool get hasWarning => status == 'warning';

  /// 创建空数据 (离线状态)
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

/// 压力表数据
class PressureData {
  final double value;
  final String status;

  PressureData({
    required this.value,
    required this.status,
  });

  factory PressureData.fromJson(Map<String, dynamic> json) {
    return PressureData(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'unknown',
    );
  }

  /// 创建空数据
  factory PressureData.empty() {
    return PressureData(value: 0.0, status: 'offline');
  }
}

/// 批量实时数据响应
class RealtimeBatchResponse {
  final bool success;
  final String timestamp;
  final String source; // mock 或 plc
  final List<PumpData> pumps;
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
      success: json['success'] as bool? ?? false,
      timestamp: json['timestamp'] as String? ?? '',
      source: json['source'] as String? ?? 'unknown',
      pumps: pumpsJson
          .map((e) => PumpData.fromJson(e as Map<String, dynamic>))
          .toList(),
      pressure: PressureData.fromJson(pressureJson),
    );
  }

  /// 创建空响应 (错误情况)
  factory RealtimeBatchResponse.empty() {
    return RealtimeBatchResponse(
      success: false,
      timestamp: '',
      source: 'none',
      pumps: List.generate(6, (i) => PumpData.empty(i + 1)),
      pressure: PressureData.empty(),
    );
  }

  /// 获取指定水泵数据
  PumpData? getPump(int id) {
    try {
      return pumps.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// 健康检查响应
class HealthResponse {
  final bool serverHealthy;
  final bool plcConnected;
  final bool dbConnected;
  final String? error;

  HealthResponse({
    required this.serverHealthy,
    required this.plcConnected,
    required this.dbConnected,
    this.error,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      serverHealthy: true, // 能解析说明服务可用
      plcConnected: json['plc_connected'] as bool? ?? false,
      dbConnected: json['db_connected'] as bool? ?? false,
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

  bool get allHealthy => serverHealthy && plcConnected && dbConnected;
}

/// 系统状态响应
class StatusResponse {
  final bool success;
  final String plcStatus; // connected, disconnected, error
  final String dbStatus;
  final String pollingStatus; // running, stopped
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
      plcStatus: data['plc_status'] as String? ?? 'unknown',
      dbStatus: data['db_status'] as String? ?? 'unknown',
      pollingStatus: data['polling_status'] as String? ?? 'unknown',
      lastPollTime: data['last_poll_time'] as int?,
    );
  }

  bool get plcConnected => plcStatus == 'connected';
  bool get dbConnected => dbStatus == 'connected';
}
