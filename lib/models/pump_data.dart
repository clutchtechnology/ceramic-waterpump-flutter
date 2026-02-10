// 水泵数据模型 - 水泵房监控系统
// ============================================================
// 功能: 解析后端 API 返回的 JSON 数据，提供类型安全访问
// ============================================================

// ============================================================
// 1, 单个水泵实时数据 (对应 DB2 数据块)
// 字段名与 InfluxDB / WebSocket 推送完全一致
// ============================================================
class PumpData {
  // 2, 水泵编号 (1-6)
  final int id;

  // 3, 运行状态 (running/stopped)
  final String status;

  // 4, 总有功功率 Pt (kW)
  final double pt;

  // 5, 正向有功电能 ImpEp (kWh)
  final double impEp;

  // 6, A相电流 I_0 (A)
  final double i0;

  // 7, B相电流 I_1 (A)
  final double i1;

  // 8, C相电流 I_2 (A)
  final double i2;

  // 9, A相电压 Ua_0 (V)
  final double ua0;

  // 10, B相电压 Ua_1 (V)
  final double ua1;

  // 11, C相电压 Ua_2 (V)
  final double ua2;

  // 12, X轴振动速度 (mm/s)
  final double vibVelocityX;

  // 13, Y轴振动速度 (mm/s)
  final double vibVelocityY;

  // 14, Z轴振动速度 (mm/s)
  final double vibVelocityZ;

  // 15, X轴振动位移 (um)
  final double vibDisplacementX;

  // 16, Y轴振动位移 (um)
  final double vibDisplacementY;

  // 17, Z轴振动位移 (um)
  final double vibDisplacementZ;

  // 18, X轴振动频率 (Hz)
  final double vibFrequencyX;

  // 19, Y轴振动频率 (Hz)
  final double vibFrequencyY;

  // 20, Z轴振动频率 (Hz)
  final double vibFrequencyZ;

  PumpData({
    required this.id,
    required this.status,
    required this.pt,
    required this.impEp,
    required this.i0,
    required this.i1,
    required this.i2,
    required this.ua0,
    required this.ua1,
    required this.ua2,
    required this.vibVelocityX,
    required this.vibVelocityY,
    required this.vibVelocityZ,
    required this.vibDisplacementX,
    required this.vibDisplacementY,
    required this.vibDisplacementZ,
    required this.vibFrequencyX,
    required this.vibFrequencyY,
    required this.vibFrequencyZ,
  });

  factory PumpData.fromJson(Map<String, dynamic> json) {
    return PumpData(
      // 2, 解析水泵编号
      id: json['id'] as int? ?? 0,
      // 3, 解析运行状态
      status: json['status'] as String? ?? 'stopped',
      // 4, 解析总有功功率
      pt: (json['Pt'] as num?)?.toDouble() ?? 0.0,
      // 5, 解析正向有功电能
      impEp: (json['ImpEp'] as num?)?.toDouble() ?? 0.0,
      // 6, 解析A相电流
      i0: (json['I_0'] as num?)?.toDouble() ?? 0.0,
      // 7, 解析B相电流
      i1: (json['I_1'] as num?)?.toDouble() ?? 0.0,
      // 8, 解析C相电流
      i2: (json['I_2'] as num?)?.toDouble() ?? 0.0,
      // 9, 解析A相电压
      ua0: (json['Ua_0'] as num?)?.toDouble() ?? 0.0,
      // 10, 解析B相电压
      ua1: (json['Ua_1'] as num?)?.toDouble() ?? 0.0,
      // 11, 解析C相电压
      ua2: (json['Ua_2'] as num?)?.toDouble() ?? 0.0,
      // 12, 解析X轴振动速度
      vibVelocityX: (json['vib_velocity_x'] as num?)?.toDouble() ?? 0.0,
      // 13, 解析Y轴振动速度
      vibVelocityY: (json['vib_velocity_y'] as num?)?.toDouble() ?? 0.0,
      // 14, 解析Z轴振动速度
      vibVelocityZ: (json['vib_velocity_z'] as num?)?.toDouble() ?? 0.0,
      // 15, 解析X轴振动位移
      vibDisplacementX: (json['vib_displacement_x'] as num?)?.toDouble() ?? 0.0,
      // 16, 解析Y轴振动位移
      vibDisplacementY: (json['vib_displacement_y'] as num?)?.toDouble() ?? 0.0,
      // 17, 解析Z轴振动位移
      vibDisplacementZ: (json['vib_displacement_z'] as num?)?.toDouble() ?? 0.0,
      // 18, 解析X轴振动频率
      vibFrequencyX: (json['vib_frequency_x'] as num?)?.toDouble() ?? 0.0,
      // 19, 解析Y轴振动频率
      vibFrequencyY: (json['vib_frequency_y'] as num?)?.toDouble() ?? 0.0,
      // 20, 解析Z轴振动频率
      vibFrequencyZ: (json['vib_frequency_z'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // 4, 是否运行中
  bool get isRunning => status == 'running';

  // 6, 三相电流平均值
  double get iAvg => (i0 + i1 + i2) / 3;

  // 9, 三相电压平均值
  double get uaAvg => (ua0 + ua1 + ua2) / 3;

  // 创建离线状态空数据
  factory PumpData.empty(int id) {
    return PumpData(
      id: id,
      status: 'stopped',
      pt: 0.0,
      impEp: 0.0,
      i0: 0.0,
      i1: 0.0,
      i2: 0.0,
      ua0: 0.0,
      ua1: 0.0,
      ua2: 0.0,
      vibVelocityX: 0.0,
      vibVelocityY: 0.0,
      vibVelocityZ: 0.0,
      vibDisplacementX: 0.0,
      vibDisplacementY: 0.0,
      vibDisplacementZ: 0.0,
      vibFrequencyX: 0.0,
      vibFrequencyY: 0.0,
      vibFrequencyZ: 0.0,
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
