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
    );
  }
}

// ============================================================
// 8, 压力表数据 (对应 DB2 压力传感器)
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
// 11, 振动传感器数据 (对应 DB4 振动传感器)
// ============================================================
class VibrationData {
  // 12, 振动传感器编号 (1-6)
  final int id;

  // 13, 设备ID (vib_1 ~ vib_6)
  final String deviceId;

  // 14, 设备名称
  final String deviceName;

  // 15, X轴振动速度 (mm/s)
  final double vx;

  // 16, Y轴振动速度 (mm/s)
  final double vy;

  // 17, Z轴振动速度 (mm/s)
  final double vz;

  // 18, X轴振动位移 (um)
  final double dx;

  // 19, Y轴振动位移 (um)
  final double dy;

  // 20, Z轴振动位移 (um)
  final double dz;

  // 21, X轴振动频率 (Hz)
  final double hzx;

  // 22, Y轴振动频率 (Hz)
  final double hzy;

  // 23, Z轴振动频率 (Hz)
  final double hzz;

  // 24, 状态 (normal/warning/alarm/offline)
  final String status;

  VibrationData({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.dx,
    required this.dy,
    required this.dz,
    required this.hzx,
    required this.hzy,
    required this.hzz,
    required this.status,
  });

  factory VibrationData.fromJson(Map<String, dynamic> json) {
    // 从 device_id 中提取编号 (vib_1 -> 1)
    final deviceId = json['device_id'] as String? ?? 'vib_0';
    final id = int.tryParse(deviceId.replaceAll('vib_', '')) ?? 0;

    return VibrationData(
      // 12, 解析振动传感器编号
      id: id,
      // 13, 解析设备ID
      deviceId: deviceId,
      // 14, 解析设备名称
      deviceName: json['device_name'] as String? ?? '未知振动传感器',
      // 15, 解析X轴振动速度
      vx: (json['vx'] as num?)?.toDouble() ?? 0.0,
      // 16, 解析Y轴振动速度
      vy: (json['vy'] as num?)?.toDouble() ?? 0.0,
      // 17, 解析Z轴振动速度
      vz: (json['vz'] as num?)?.toDouble() ?? 0.0,
      // 18, 解析X轴振动位移
      dx: (json['dx'] as num?)?.toDouble() ?? 0.0,
      // 19, 解析Y轴振动位移
      dy: (json['dy'] as num?)?.toDouble() ?? 0.0,
      // 20, 解析Z轴振动位移
      dz: (json['dz'] as num?)?.toDouble() ?? 0.0,
      // 21, 解析X轴振动频率
      hzx: (json['hzx'] as num?)?.toDouble() ?? 0.0,
      // 22, 解析Y轴振动频率
      hzy: (json['hzy'] as num?)?.toDouble() ?? 0.0,
      // 23, 解析Z轴振动频率
      hzz: (json['hzz'] as num?)?.toDouble() ?? 0.0,
      // 24, 解析状态
      status: json['status'] as String? ?? 'offline',
    );
  }

  /// 创建离线状态空数据
  factory VibrationData.empty(int id) {
    return VibrationData(
      id: id,
      deviceId: 'vib_$id',
      deviceName: '$id号振动传感器',
      vx: 0.0,
      vy: 0.0,
      vz: 0.0,
      dx: 0.0,
      dy: 0.0,
      dz: 0.0,
      hzx: 0.0,
      hzy: 0.0,
      hzz: 0.0,
      status: 'offline',
    );
  }
}

// ============================================================
// 22, 批量实时数据响应 (聚合 6 泵 + 1 压力表 + 6 振动传感器)
// ============================================================
class RealtimeBatchResponse {
  // 23, 请求是否成功
  final bool success;

  // 24, 数据时间戳 (ISO 8601)
  final String timestamp;

  // 25, 数据来源 (mock/plc)
  final String source;

  // 26, 6 个水泵数据列表
  final List<PumpData> pumps;

  // 27, 压力表数据
  final PressureData pressure;

  // 28, 6 个振动传感器数据列表
  final List<VibrationData> vibrations;

  RealtimeBatchResponse({
    required this.success,
    required this.timestamp,
    required this.source,
    required this.pumps,
    required this.pressure,
    required this.vibrations,
  });

  factory RealtimeBatchResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final pumpsJson = data['pumps'] as List<dynamic>? ?? [];
    final pressureJson = data['pressure'] as Map<String, dynamic>? ?? {};
    final vibrationsJson = data['vibrations'] as List<dynamic>? ?? [];

    return RealtimeBatchResponse(
      // 23, 解析成功标志
      success: json['success'] as bool? ?? false,
      // 24, 解析时间戳
      timestamp: json['timestamp'] as String? ?? '',
      // 25, 解析数据来源
      source: json['source'] as String? ?? 'unknown',
      // 26, 解析水泵列表
      pumps: pumpsJson
          .map((e) => PumpData.fromJson(e as Map<String, dynamic>))
          .toList(),
      // 27, 解析压力数据
      pressure: PressureData.fromJson(pressureJson),
      // 28, 解析振动传感器列表
      vibrations: vibrationsJson
          .map((e) => VibrationData.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      vibrations: List.generate(6, (i) => VibrationData.empty(i + 1)),
    );
  }

  /// 26, 获取指定水泵数据 (安全方式，避免异常)
  PumpData? getPump(int id) {
    for (final pump in pumps) {
      if (pump.id == id) return pump;
    }
    return null;
  }

  /// 28, 获取指定振动传感器数据 (安全方式，避免异常)
  VibrationData? getVibration(int id) {
    for (final vib in vibrations) {
      if (vib.id == id) return vib;
    }
    return null;
  }
}

// ============================================================
// 29, 健康检查响应
// ============================================================
class HealthResponse {
  // 30, 后端服务是否存活
  final bool serverHealthy;

  // 31, PLC 是否连接
  final bool plcConnected;

  // 32, InfluxDB 是否连接
  final bool dbConnected;

  // 33, 错误信息
  final String? error;

  HealthResponse({
    required this.serverHealthy,
    required this.plcConnected,
    required this.dbConnected,
    this.error,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      // 30, 能解析说明服务存活
      serverHealthy: true,
      // 31, 解析 PLC 连接状态
      plcConnected: json['plc_connected'] as bool? ?? false,
      // 32, 解析 DB 连接状态
      dbConnected: json['db_connected'] as bool? ?? false,
      // 33, 解析错误信息
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

  // 30+31+32, 判断全部健康
  bool get allHealthy => serverHealthy && plcConnected && dbConnected;
}

// ============================================================
// 34, 系统状态响应
// ============================================================
class StatusResponse {
  final bool success;

  // 35, PLC 连接状态 (connected/disconnected/error)
  final String plcStatus;

  // 36, DB 连接状态
  final String dbStatus;

  // 37, 轮询状态 (running/stopped)
  final String pollingStatus;

  // 38, 上次轮询时间戳
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
      // 35, 解析 PLC 状态
      plcStatus: data['plc_status'] as String? ?? 'unknown',
      // 36, 解析 DB 状态
      dbStatus: data['db_status'] as String? ?? 'unknown',
      // 37, 解析轮询状态
      pollingStatus: data['polling_status'] as String? ?? 'unknown',
      // 38, 解析上次轮询时间
      lastPollTime: data['last_poll_time'] as int?,
    );
  }

  // 35, PLC 是否已连接
  bool get plcConnected => plcStatus == 'connected';

  // 36, DB 是否已连接
  bool get dbConnected => dbStatus == 'connected';
}
