// 设备状态位数据模型 - 水泵房监控系统
// ============================================================
// 功能: 解析后端 DB3 状态数据，用于设备通信状态监控
// ============================================================

// ============================================================
// 1, 单个设备的通信状态 (对应 DB3 状态字)
// ============================================================
class DeviceStatus {
  // 2, 设备唯一标识 (pump_1, pump_2, ..., pressure)
  final String deviceId;

  // 3, 设备显示名称 (1#水泵, 2#水泵, ..., 压力表)
  final String deviceName;

  // 4, 关联的数据设备 ID (用于关联 DB8 数据)
  final String? dataDeviceId;

  // 5, DB3 中的字节偏移量
  final int offset;

  // 6, 设备是否启用
  final bool enabled;

  // 7, 是否有通信错误
  final bool error;

  // 8, 状态码原始值 (用于调试)
  final int statusCode;

  // 9, 状态码十六进制显示
  final String statusHex;

  // 10, 是否正常 (无错误)
  final bool isNormal;

  DeviceStatus({
    required this.deviceId,
    required this.deviceName,
    this.dataDeviceId,
    required this.offset,
    required this.enabled,
    required this.error,
    required this.statusCode,
    required this.statusHex,
    required this.isNormal,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      // 2, 解析设备 ID
      deviceId: json['device_id'] ?? '',
      // 3, 解析设备名称
      deviceName: json['device_name'] ?? '',
      // 4, 解析关联数据设备
      dataDeviceId: json['data_device_id'],
      // 5, 解析偏移量
      offset: json['offset'] ?? 0,
      // 6, 解析启用状态
      enabled: json['enabled'] ?? true,
      // 7, 解析错误标志
      error: json['error'] ?? false,
      // 8, 解析状态码
      statusCode: json['status_code'] ?? 0,
      // 9, 解析十六进制状态
      statusHex: json['status_hex'] ?? '0000',
      // 10, 解析正常标志
      isNormal: json['is_normal'] ?? true,
    );
  }
}

// ============================================================
// 11, 状态统计信息
// ============================================================
class StatusSummary {
  // 12, 设备总数
  final int total;

  // 13, 正常设备数
  final int normal;

  // 14, 异常设备数
  final int error;

  StatusSummary({
    required this.total,
    required this.normal,
    required this.error,
  });

  factory StatusSummary.fromJson(Map<String, dynamic> json) {
    return StatusSummary(
      // 12, 解析总数
      total: json['total'] ?? 0,
      // 13, 解析正常数
      normal: json['normal'] ?? 0,
      // 14, 解析异常数
      error: json['error'] ?? 0,
    );
  }
}

// ============================================================
// 15, 设备状态位 API 响应
// ============================================================
class DeviceStatusResponse {
  // 16, 请求是否成功
  final bool success;

  // 17, 状态数据 (按 DB 分组: "db3" -> [DeviceStatus])
  final Map<String, List<DeviceStatus>>? data;

  // 18, 统计信息
  final StatusSummary? summary;

  // 19, 数据来源 (mock/plc)
  final String? source;

  // 20, 错误信息
  final String? error;

  // 21, 数据时间戳
  final String? timestamp;

  DeviceStatusResponse({
    required this.success,
    this.data,
    this.summary,
    this.source,
    this.error,
    this.timestamp,
  });

  factory DeviceStatusResponse.fromJson(Map<String, dynamic> json) {
    // 17, 解析状态数据 Map
    Map<String, List<DeviceStatus>>? dataMap;

    if (json['data'] != null && json['data'] is Map) {
      dataMap = {};
      (json['data'] as Map).forEach((key, value) {
        if (value is List) {
          dataMap![key] = value
              .map(
                  (item) => DeviceStatus.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      });
    }

    return DeviceStatusResponse(
      // 16, 解析成功标志
      success: json['success'] ?? false,
      // 17, 状态数据
      data: dataMap,
      // 18, 解析统计信息
      summary: json['summary'] != null
          ? StatusSummary.fromJson(json['summary'])
          : null,
      // 19, 解析数据来源
      source: json['source'],
      // 20, 解析错误信息
      error: json['error'],
      // 21, 解析时间戳
      timestamp: json['timestamp'],
    );
  }

  /// 17, 获取 DB3 状态列表 (所有设备通信状态)
  List<DeviceStatus> get db3Status => data?['db3'] ?? [];
}
