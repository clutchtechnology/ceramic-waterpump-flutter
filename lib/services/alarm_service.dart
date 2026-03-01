// 报警服务 - 查询报警记录与统计

import '../api/api.dart';
import '../api/api_client.dart';
import '../models/alarm_model.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final ApiClient _httpClient = ApiClient();

  // ============================================================
  // 1. queryAlarms() - 查询历史报警记录
  // ============================================================
  Future<List<AlarmRecord>> queryAlarms({
    DateTime? start,
    DateTime? end,
    String? level,
    String? paramPrefix,
    int limit = 200,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
    };
    if (start != null) params['start'] = start.toUtc().toIso8601String();
    if (end != null) params['end'] = end.toUtc().toIso8601String();
    if (level != null && level.isNotEmpty) params['level'] = level;
    if (paramPrefix != null && paramPrefix.isNotEmpty) {
      params['param_prefix'] = paramPrefix;
    }

    try {
      final data = await _httpClient.get(Api.alarmRecords, params: params);
      if (data == null || data['success'] != true) return [];
      final list = (data['data']?['records'] as List?) ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(AlarmRecord.fromJson)
          .toList();
    } catch (e) {
      debugLog('[AlarmService] queryAlarms failed: $e');
      return [];
    }
  }

  // ============================================================
  // 2. getAlarmCount() - 统计报警数量
  // ============================================================
  Future<AlarmCount> getAlarmCount({int hours = 24}) async {
    try {
      final data = await _httpClient.get(
        Api.alarmCount,
        params: {'hours': hours.toString()},
      );
      if (data == null || data['success'] != true) return AlarmCount.zero;
      return AlarmCount.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      debugLog('[AlarmService] getAlarmCount failed: $e');
      return AlarmCount.zero;
    }
  }

  // 简易日志（避免引入无关依赖）
  void debugLog(String msg) {
    // ignore: avoid_print
    print(msg);
  }
}
