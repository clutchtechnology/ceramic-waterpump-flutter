import 'dart:async';
import '../api/index.dart';

/// 历史数据服务
/// 用于获取电表、压力、功率等历史数据，支持动态聚合间隔
class HistoryService {
  final ApiClient _apiClient = ApiClient();

  // ============================================================
  // 动态聚合间隔计算
  // ============================================================

  /// 目标数据点数（保持图表显示效果一致）
  static const int _targetPoints = 50;

  /// 可接受的数据点范围
  static const int _minPoints = 30;
  static const int _maxPoints = 80;

  /// 有效的聚合间隔选项（秒）
  /// InfluxDB 支持的常用间隔值
  static const List<int> _validIntervals = [
    5, // 5s - 原始精度
    10, // 10s
    15, // 15s
    30, // 30s
    60, // 1m
    120, // 2m
    180, // 3m
    300, // 5m
    600, // 10m
    900, // 15m
    1800, // 30m
    3600, // 1h
    7200, // 2h
    14400, // 4h
    21600, // 6h
    43200, // 12h
    86400, // 1d
    172800, // 2d
    259200, // 3d
    604800, // 7d (1周)
    1209600, // 14d (2周)
    2592000, // 30d (1月)
  ];

  /// 根据时间范围计算最佳聚合间隔
  ///
  /// 核心逻辑：选择能让数据点数最接近目标值(50)的聚合间隔
  /// 这样无论时间范围多大，返回的数据点数都相对一致
  ///
  /// 示例（目标50点）：
  /// - 2分钟 → 5s → ~24点 (短时间保持原始精度)
  /// - 5分钟 → 5s → 60点
  /// - 1小时 → 1m → 60点
  /// - 6小时 → 5m → 72点 → 取10m → 36点
  /// - 24小时 → 30m → 48点
  /// - 7天 → 4h → 42点
  static String calculateAggregateInterval(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final totalSeconds = duration.inSeconds;

    // 特殊情况：时间范围太短，直接返回原始精度
    if (totalSeconds <= 0) {
      return '5s';
    }

    // 计算理想的聚合间隔（秒）
    final idealIntervalSeconds = totalSeconds / _targetPoints;

    // 找到最佳的有效间隔
    int bestInterval = _validIntervals[0];
    double minDiff = double.infinity;

    for (final interval in _validIntervals) {
      final estimatedPoints = totalSeconds / interval;

      // 优先选择在合理范围内且最接近目标的间隔
      if (estimatedPoints >= _minPoints && estimatedPoints <= _maxPoints) {
        final diff = (estimatedPoints - _targetPoints).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestInterval = interval;
        }
      }
    }

    // 如果没有找到合理范围内的，选择最接近理想值的间隔
    if (minDiff == double.infinity) {
      minDiff = double.infinity;
      for (final interval in _validIntervals) {
        final diff = (interval - idealIntervalSeconds).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestInterval = interval;
        }
      }
    }

    return _formatInterval(bestInterval);
  }

  /// 将秒数格式化为 InfluxDB 支持的间隔字符串
  static String _formatInterval(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      return '${seconds ~/ 60}m';
    } else if (seconds < 86400) {
      return '${seconds ~/ 3600}h';
    } else {
      return '${seconds ~/ 86400}d';
    }
  }

  /// 获取聚合间隔的预估数据点数（用于调试或UI显示）
  static int getEstimatedPoints(DateTime start, DateTime end) {
    final totalSeconds = end.difference(start).inSeconds;
    final interval = calculateAggregateInterval(start, end);
    final intervalSeconds = _parseIntervalToSeconds(interval);
    return (totalSeconds / intervalSeconds).round();
  }

  /// 将间隔字符串解析为秒数
  static int _parseIntervalToSeconds(String interval) {
    final value = int.tryParse(interval.substring(0, interval.length - 1)) ?? 1;
    final unit = interval[interval.length - 1];
    switch (unit) {
      case 's':
        return value;
      case 'm':
        return value * 60;
      case 'h':
        return value * 3600;
      case 'd':
        return value * 86400;
      default:
        return value;
    }
  }

  // ============================================================
  // 历史数据查询
  // ============================================================

  /// 获取历史数据
  ///
  /// 参数：
  /// - pumpId: 水泵编号 (1-6)，null 表示查询压力表
  /// - parameter: 参数名 (voltage/current/power/pressure)
  /// - start: 开始时间
  /// - end: 结束时间
  /// - interval: 聚合间隔 (可选，不传则自动计算最佳聚合间隔)
  Future<HistoryDataResponse> fetchHistory({
    int? pumpId,
    required String parameter,
    required DateTime start,
    required DateTime end,
    String? interval,
  }) async {
    try {
      // 自动计算最佳聚合间隔
      final effectiveInterval =
          interval ?? calculateAggregateInterval(start, end);

      final params = <String, String>{
        'parameter': parameter,
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'interval': effectiveInterval,
      };

      if (pumpId != null) {
        params['pump_id'] = pumpId.toString();
      }

      print(
          '[HistoryService] 查询参数: $parameter, 时间范围: ${end.difference(start).inMinutes}分钟, 聚合间隔: $effectiveInterval');

      final response = await _apiClient.get(Api.history, params: params);

      if (response != null && response['success'] == true) {
        final dataList = response['data'] as List<dynamic>? ?? [];
        final points = dataList.map((item) {
          // 保留1位小数，避免浮点数精度问题
          final rawValue = (item['value'] as num?)?.toDouble() ?? 0.0;
          final roundedValue = double.parse(rawValue.toStringAsFixed(1));
          return HistoryDataPoint(
            timestamp: DateTime.parse(item['timestamp'] as String),
            value: roundedValue,
          );
        }).toList();

        print('[HistoryService] 获取到 ${points.length} 个数据点');

        return HistoryDataResponse(
          success: true,
          data: points,
          query: HistoryQuery(
            pumpId: pumpId,
            parameter: parameter,
            start: start,
            end: end,
            interval: effectiveInterval,
          ),
        );
      }

      return HistoryDataResponse.empty(
        pumpId: pumpId,
        parameter: parameter,
        start: start,
        end: end,
        interval: interval ?? calculateAggregateInterval(start, end),
      );
    } catch (e) {
      print('[HistoryService] 获取历史数据失败: $e');
      return HistoryDataResponse.empty(
        pumpId: pumpId,
        parameter: parameter,
        start: start,
        end: end,
        interval: interval ?? calculateAggregateInterval(start, end),
        error: e.toString(),
      );
    }
  }

  /// 批量获取多个水泵的历史数据（同一参数）
  /// interval 为 null 时自动计算最佳聚合间隔
  Future<Map<int, List<HistoryDataPoint>>> fetchMultiplePumpsHistory({
    required List<int> pumpIds,
    required String parameter,
    required DateTime start,
    required DateTime end,
    String? interval,
  }) async {
    final results = <int, List<HistoryDataPoint>>{};

    // 并行请求所有水泵数据
    final futures = pumpIds.map((pumpId) async {
      final response = await fetchHistory(
        pumpId: pumpId,
        parameter: parameter,
        start: start,
        end: end,
        interval: interval, // null 时由 fetchHistory 自动计算
      );
      return MapEntry(pumpId, response.data);
    });

    final entries = await Future.wait(futures);
    for (final entry in entries) {
      results[entry.key] = entry.value;
    }

    return results;
  }

  /// 获取压力历史数据
  /// interval 为 null 时自动计算最佳聚合间隔
  Future<List<HistoryDataPoint>> fetchPressureHistory({
    required DateTime start,
    required DateTime end,
    String? interval,
  }) async {
    final response = await fetchHistory(
      pumpId: null,
      parameter: 'pressure',
      start: start,
      end: end,
      interval: interval,
    );
    return response.data;
  }

  /// 获取电表能耗历史数据 (6个电表)
  /// interval 为 null 时自动计算最佳聚合间隔
  Future<Map<int, List<HistoryDataPoint>>> fetchEnergyHistory({
    required DateTime start,
    required DateTime end,
    String? interval,
  }) async {
    return fetchMultiplePumpsHistory(
      pumpIds: [1, 2, 3, 4, 5, 6],
      parameter: 'power', // 使用功率作为能耗
      start: start,
      end: end,
      interval: interval,
    );
  }

  /// 获取电表功率历史数据 (6个电表)
  /// interval 为 null 时自动计算最佳聚合间隔
  Future<Map<int, List<HistoryDataPoint>>> fetchPowerHistory({
    required DateTime start,
    required DateTime end,
    String? interval,
  }) async {
    return fetchMultiplePumpsHistory(
      pumpIds: [1, 2, 3, 4, 5, 6],
      parameter: 'power',
      start: start,
      end: end,
      interval: interval,
    );
  }
}

/// 历史数据点
class HistoryDataPoint {
  final DateTime timestamp;
  final double value;

  HistoryDataPoint({
    required this.timestamp,
    required this.value,
  });
}

/// 历史查询参数
class HistoryQuery {
  final int? pumpId;
  final String parameter;
  final DateTime start;
  final DateTime end;
  final String? interval;

  HistoryQuery({
    this.pumpId,
    required this.parameter,
    required this.start,
    required this.end,
    this.interval,
  });
}

/// 历史数据响应
class HistoryDataResponse {
  final bool success;
  final List<HistoryDataPoint> data;
  final HistoryQuery? query;
  final String? error;

  HistoryDataResponse({
    required this.success,
    required this.data,
    this.query,
    this.error,
  });

  factory HistoryDataResponse.empty({
    int? pumpId,
    required String parameter,
    required DateTime start,
    required DateTime end,
    String? interval,
    String? error,
  }) {
    return HistoryDataResponse(
      success: false,
      data: [],
      query: HistoryQuery(
        pumpId: pumpId,
        parameter: parameter,
        start: start,
        end: end,
        interval: interval,
      ),
      error: error,
    );
  }
}
