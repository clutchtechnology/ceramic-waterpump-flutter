import '../api/index.dart';
import '../api/api.dart';

/// 报警记录模型
class AlarmRecord {
  final DateTime timestamp;
  final String deviceId;
  final String alarmType;
  final String level; // warning / alarm
  final String paramName;
  final double value;
  final double threshold;
  final String message;
  final bool acknowledged;

  AlarmRecord({
    required this.timestamp,
    required this.deviceId,
    required this.alarmType,
    required this.level,
    required this.paramName,
    required this.value,
    required this.threshold,
    required this.message,
    required this.acknowledged,
  });

  factory AlarmRecord.fromJson(Map<String, dynamic> json) {
    return AlarmRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceId: json['device_id'] as String? ?? '',
      alarmType: json['alarm_type'] as String? ?? '',
      level: json['level'] as String? ?? 'warning',
      paramName: json['param_name'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? '',
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }

  /// 获取设备显示名称
  String get deviceDisplayName {
    if (deviceId.startsWith('pump_')) {
      final num = deviceId.replaceAll('pump_', '');
      return '$num号泵';
    } else if (deviceId == 'pressure') {
      return '压力表';
    }
    return deviceId;
  }

  /// 获取参数显示名称
  String get paramDisplayName {
    switch (paramName) {
      case 'current':
        return '电流';
      case 'power':
        return '功率';
      case 'pressure':
        return '压力';
      case 'vibration':
        return '振动';
      default:
        return paramName;
    }
  }

  /// 是否是报警级别
  bool get isAlarm => level == 'alarm';
}

/// 报警统计
class AlarmCount {
  final int warning;
  final int alarm;
  final int total;

  AlarmCount({
    required this.warning,
    required this.alarm,
    required this.total,
  });

  factory AlarmCount.fromJson(Map<String, dynamic> json) {
    return AlarmCount(
      warning: json['warning'] as int? ?? 0,
      alarm: json['alarm'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }
}

/// 报警日志服务
class AlarmService {
  final ApiClient _apiClient = ApiClient();

  /// 查询报警日志
  Future<List<AlarmRecord>> fetchAlarms({
    DateTime? startTime,
    DateTime? endTime,
    String? deviceId,
    String? level,
    int limit = 100,
  }) async {
    try {
      final params = <String, String>{};

      if (startTime != null) {
        params['start'] = startTime.toUtc().toIso8601String();
      }
      if (endTime != null) {
        params['end'] = endTime.toUtc().toIso8601String();
      }
      if (deviceId != null) {
        params['device_id'] = deviceId;
      }
      if (level != null) {
        params['level'] = level;
      }
      params['limit'] = limit.toString();

      final response = await _apiClient.get(Api.alarms, params: params);

      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => AlarmRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('[AlarmService] 查询报警日志失败: $e');
    }

    return [];
  }

  /// 获取报警统计
  Future<AlarmCount> fetchAlarmCount({int hours = 24}) async {
    try {
      final params = {'hours': hours.toString()};
      final response = await _apiClient.get(Api.alarmsCount, params: params);

      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        return AlarmCount.fromJson(data);
      }
    } catch (e) {
      print('[AlarmService] 获取报警统计失败: $e');
    }

    return AlarmCount(warning: 0, alarm: 0, total: 0);
  }
}
