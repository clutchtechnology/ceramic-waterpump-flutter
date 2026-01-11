/// 阈值配置状态管理 Provider
///
/// 功能职责:
/// - [P-1] 本地持久化存储阈值配置 (SharedPreferences)
/// - [P-2] 同步阈值配置到后端
/// - [P-3] 提供阈值颜色判断接口 (正常/警告/报警)
/// - [P-4] 支持实时更新和重置默认值
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/index.dart';

/// 阈值颜色配置 (固定三色)
class ThresholdColors {
  static const Color normal = Color(0xFF00ff88); // 绿色 - 正常
  static const Color warning = Color(0xFFffcc00); // 黄色 - 警告
  static const Color alarm = Color(0xFFff3b30); // 红色 - 报警
}

/// 单个参数的阈值配置
class ThresholdConfig {
  final String key; // 配置键值
  final String displayName; // 显示名称
  double normalMax; // 正常上限 (绿色)
  double warningMax; // 警告上限 (黄色，超过为红色)

  ThresholdConfig({
    required this.key,
    required this.displayName,
    this.normalMax = 0.0,
    this.warningMax = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'displayName': displayName,
        'normalMax': normalMax,
        'warningMax': warningMax,
      };

  factory ThresholdConfig.fromJson(Map<String, dynamic> json) {
    return ThresholdConfig(
      key: json['key'] as String,
      displayName: json['displayName'] as String,
      normalMax: (json['normalMax'] as num?)?.toDouble() ?? 0.0,
      warningMax: (json['warningMax'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 根据数值获取状态颜色
  /// value <= normalMax: 绿色 (正常)
  /// normalMax < value <= warningMax: 黄色 (警告)
  /// value > warningMax: 红色 (报警)
  Color getColor(double value) {
    if (value <= normalMax) {
      return ThresholdColors.normal;
    } else if (value <= warningMax) {
      return ThresholdColors.warning;
    } else {
      return ThresholdColors.alarm;
    }
  }

  /// 获取状态文本
  String getStatus(double value) {
    if (value <= normalMax) {
      return '正常';
    } else if (value <= warningMax) {
      return '警告';
    } else {
      return '报警';
    }
  }
}

/// 阈值配置 Provider
/// 用于持久化存储水泵监控系统的报警阈值
///
/// 包含：
/// - 电流阈值 (6个水泵)
/// - 功率阈值 (6个水泵)
/// - 压力阈值 (1号水泵，高低双阈值)
/// - 振动幅度阈值 (6个水泵)
class ThresholdConfigProvider extends ChangeNotifier {
  static const String _storageKey = 'waterpump_threshold_config_v1';

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // ============================================================
  // 电流阈值配置 (6个水泵)
  // ============================================================
  final List<ThresholdConfig> currentConfigs = [
    ThresholdConfig(
        key: 'pump_1_current',
        displayName: '1号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
    ThresholdConfig(
        key: 'pump_2_current',
        displayName: '2号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
    ThresholdConfig(
        key: 'pump_3_current',
        displayName: '3号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
    ThresholdConfig(
        key: 'pump_4_current',
        displayName: '4号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
    ThresholdConfig(
        key: 'pump_5_current',
        displayName: '5号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
    ThresholdConfig(
        key: 'pump_6_current',
        displayName: '6号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
  ];

  // ============================================================
  // 功率阈值配置 (6个水泵)
  // ============================================================
  final List<ThresholdConfig> powerConfigs = [
    ThresholdConfig(
        key: 'pump_1_power',
        displayName: '1号泵功率',
        normalMax: 30.0,
        warningMax: 50.0),
    ThresholdConfig(
        key: 'pump_2_power',
        displayName: '2号泵功率',
        normalMax: 30.0,
        warningMax: 50.0),
    ThresholdConfig(
        key: 'pump_3_power',
        displayName: '3号泵功率',
        normalMax: 30.0,
        warningMax: 50.0),
    ThresholdConfig(
        key: 'pump_4_power',
        displayName: '4号泵功率',
        normalMax: 30.0,
        warningMax: 50.0),
    ThresholdConfig(
        key: 'pump_5_power',
        displayName: '5号泵功率',
        normalMax: 30.0,
        warningMax: 50.0),
    ThresholdConfig(
        key: 'pump_6_power',
        displayName: '6号泵功率',
        normalMax: 30.0,
        warningMax: 50.0),
  ];

  // ============================================================
  // 压力阈值配置 (1号水泵，高低双阈值)
  // ============================================================
  double pressureHighAlarm = 1.0; // 高压报警阈值 (MPa)
  double pressureLowAlarm = 0.3; // 低压报警阈值 (MPa)

  // ============================================================
  // 振动幅度阈值配置 (6个水泵)
  // ============================================================
  final List<ThresholdConfig> vibrationConfigs = [
    ThresholdConfig(
        key: 'pump_1_vibration',
        displayName: '1号泵振动',
        normalMax: 1.0,
        warningMax: 1.5),
    ThresholdConfig(
        key: 'pump_2_vibration',
        displayName: '2号泵振动',
        normalMax: 1.0,
        warningMax: 1.5),
    ThresholdConfig(
        key: 'pump_3_vibration',
        displayName: '3号泵振动',
        normalMax: 1.0,
        warningMax: 1.5),
    ThresholdConfig(
        key: 'pump_4_vibration',
        displayName: '4号泵振动',
        normalMax: 1.0,
        warningMax: 1.5),
    ThresholdConfig(
        key: 'pump_5_vibration',
        displayName: '5号泵振动',
        normalMax: 1.0,
        warningMax: 1.5),
    ThresholdConfig(
        key: 'pump_6_vibration',
        displayName: '6号泵振动',
        normalMax: 1.0,
        warningMax: 1.5),
  ];

  /// 从本地存储加载配置
  Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        _loadFromJson(jsonData);
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('加载阈值配置失败: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  void _loadFromJson(Map<String, dynamic> json) {
    // 加载电流配置
    if (json['current'] != null) {
      final data = json['current'] as Map<String, dynamic>;
      for (var config in currentConfigs) {
        if (data[config.key] != null) {
          final item = data[config.key] as Map<String, dynamic>;
          config.normalMax =
              (item['normalMax'] as num?)?.toDouble() ?? config.normalMax;
          config.warningMax =
              (item['warningMax'] as num?)?.toDouble() ?? config.warningMax;
        }
      }
    }

    // 加载功率配置
    if (json['power'] != null) {
      final data = json['power'] as Map<String, dynamic>;
      for (var config in powerConfigs) {
        if (data[config.key] != null) {
          final item = data[config.key] as Map<String, dynamic>;
          config.normalMax =
              (item['normalMax'] as num?)?.toDouble() ?? config.normalMax;
          config.warningMax =
              (item['warningMax'] as num?)?.toDouble() ?? config.warningMax;
        }
      }
    }

    // 加载压力配置
    if (json['pressure'] != null) {
      final data = json['pressure'] as Map<String, dynamic>;
      pressureHighAlarm =
          (data['high'] as num?)?.toDouble() ?? pressureHighAlarm;
      pressureLowAlarm = (data['low'] as num?)?.toDouble() ?? pressureLowAlarm;
    }

    // 加载振动配置
    if (json['vibration'] != null) {
      final data = json['vibration'] as Map<String, dynamic>;
      for (var config in vibrationConfigs) {
        if (data[config.key] != null) {
          final item = data[config.key] as Map<String, dynamic>;
          config.normalMax =
              (item['normalMax'] as num?)?.toDouble() ?? config.normalMax;
          config.warningMax =
              (item['warningMax'] as num?)?.toDouble() ?? config.warningMax;
        }
      }
    }
  }

  Map<String, dynamic> _toJson() {
    return {
      'current': {
        for (var config in currentConfigs)
          config.key: {
            'normalMax': config.normalMax,
            'warningMax': config.warningMax
          }
      },
      'power': {
        for (var config in powerConfigs)
          config.key: {
            'normalMax': config.normalMax,
            'warningMax': config.warningMax
          }
      },
      'pressure': {
        'high': pressureHighAlarm,
        'low': pressureLowAlarm,
      },
      'vibration': {
        for (var config in vibrationConfigs)
          config.key: {
            'normalMax': config.normalMax,
            'warningMax': config.warningMax
          }
      },
    };
  }

  /// 保存配置到本地存储
  Future<bool> saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_toJson());
      await prefs.setString(_storageKey, jsonString);
      notifyListeners();

      // 同步到后端 (await 确保同步完成)
      final syncSuccess = await _syncToBackend();
      if (!syncSuccess) {
        debugPrint('⚠️ 本地保存成功，但后端同步失败');
      }

      return true;
    } catch (e) {
      debugPrint('保存阈值配置失败: $e');
      return false;
    }
  }

  /// 同步阈值配置到后端
  Future<bool> _syncToBackend() async {
    try {
      final apiClient = ApiClient();
      final backendConfig = _toBackendJson();

      final response =
          await apiClient.post(Api.thresholds, body: backendConfig);

      if (response != null && response['success'] == true) {
        debugPrint('✅ 阈值配置已同步到后端');
        return true;
      } else {
        debugPrint('⚠️ 后端同步失败: ${response?['error']}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ 后端同步异常: $e');
      return false;
    }
  }

  /// 转换为后端格式的JSON
  Map<String, dynamic> _toBackendJson() {
    return {
      'current': {
        for (int i = 0; i < currentConfigs.length; i++)
          'pump_${i + 1}': {
            'normal_max': currentConfigs[i].normalMax,
            'warning_max': currentConfigs[i].warningMax,
          }
      },
      'power': {
        for (int i = 0; i < powerConfigs.length; i++)
          'pump_${i + 1}': {
            'normal_max': powerConfigs[i].normalMax,
            'warning_max': powerConfigs[i].warningMax,
          }
      },
      'pressure': {
        'high_alarm': pressureHighAlarm,
        'low_alarm': pressureLowAlarm,
      },
      'vibration': {
        for (int i = 0; i < vibrationConfigs.length; i++)
          'pump_${i + 1}': {
            'normal_max': vibrationConfigs[i].normalMax,
            'warning_max': vibrationConfigs[i].warningMax,
          }
      },
    };
  }

  // ============================================================
  // 更新配置方法
  // ============================================================

  /// 更新电流配置
  void updateCurrentConfig(int index, {double? normalMax, double? warningMax}) {
    if (index >= 0 && index < currentConfigs.length) {
      if (normalMax != null) currentConfigs[index].normalMax = normalMax;
      if (warningMax != null) currentConfigs[index].warningMax = warningMax;
      notifyListeners();
    }
  }

  /// 更新功率配置
  void updatePowerConfig(int index, {double? normalMax, double? warningMax}) {
    if (index >= 0 && index < powerConfigs.length) {
      if (normalMax != null) powerConfigs[index].normalMax = normalMax;
      if (warningMax != null) powerConfigs[index].warningMax = warningMax;
      notifyListeners();
    }
  }

  /// 更新压力配置
  void updatePressureConfig({double? highAlarm, double? lowAlarm}) {
    if (highAlarm != null) pressureHighAlarm = highAlarm;
    if (lowAlarm != null) pressureLowAlarm = lowAlarm;
    notifyListeners();
  }

  /// 更新振动配置
  void updateVibrationConfig(int index,
      {double? normalMax, double? warningMax}) {
    if (index >= 0 && index < vibrationConfigs.length) {
      if (normalMax != null) vibrationConfigs[index].normalMax = normalMax;
      if (warningMax != null) vibrationConfigs[index].warningMax = warningMax;
      notifyListeners();
    }
  }

  /// 重置为默认配置
  void resetToDefault() {
    // 重置电流
    for (var config in currentConfigs) {
      config.normalMax = 50.0;
      config.warningMax = 80.0;
    }
    // 重置功率
    for (var config in powerConfigs) {
      config.normalMax = 30.0;
      config.warningMax = 50.0;
    }
    // 重置压力
    pressureHighAlarm = 1.0;
    pressureLowAlarm = 0.3;
    // 重置振动
    for (var config in vibrationConfigs) {
      config.normalMax = 1.0;
      config.warningMax = 1.5;
    }
    notifyListeners();
  }

  // ============================================================
  // 便捷获取颜色的方法
  // ============================================================

  /// 获取电流颜色 (泵索引 1-6)
  Color getCurrentColor(int pumpIndex, double current) {
    if (pumpIndex < 1 || pumpIndex > currentConfigs.length) {
      return ThresholdColors.normal;
    }
    return currentConfigs[pumpIndex - 1].getColor(current);
  }

  /// 获取功率颜色 (泵索引 1-6)
  Color getPowerColor(int pumpIndex, double power) {
    if (pumpIndex < 1 || pumpIndex > powerConfigs.length) {
      return ThresholdColors.normal;
    }
    return powerConfigs[pumpIndex - 1].getColor(power);
  }

  /// 获取压力颜色 (仅1号泵)
  /// 低于lowAlarm: 红色报警
  /// 高于highAlarm: 红色报警
  /// 在范围内: 绿色正常
  Color getPressureColor(double pressure) {
    if (pressure < pressureLowAlarm || pressure > pressureHighAlarm) {
      return ThresholdColors.alarm;
    }
    // 接近边界时显示警告
    final lowMargin = (pressureHighAlarm - pressureLowAlarm) * 0.2;
    if (pressure < pressureLowAlarm + lowMargin ||
        pressure > pressureHighAlarm - lowMargin) {
      return ThresholdColors.warning;
    }
    return ThresholdColors.normal;
  }

  /// 获取振动颜色 (泵索引 1-6)
  Color getVibrationColor(int pumpIndex, double vibration) {
    if (pumpIndex < 1 || pumpIndex > vibrationConfigs.length) {
      return ThresholdColors.normal;
    }
    return vibrationConfigs[pumpIndex - 1].getColor(vibration);
  }

  // ============================================================
  // 获取阈值配置
  // ============================================================

  /// 获取电流阈值配置 (泵索引 1-6)
  ThresholdConfig? getCurrentThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > currentConfigs.length) return null;
    return currentConfigs[pumpIndex - 1];
  }

  /// 获取功率阈值配置 (泵索引 1-6)
  ThresholdConfig? getPowerThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > powerConfigs.length) return null;
    return powerConfigs[pumpIndex - 1];
  }

  /// 获取振动阈值配置 (泵索引 1-6)
  ThresholdConfig? getVibrationThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > vibrationConfigs.length) return null;
    return vibrationConfigs[pumpIndex - 1];
  }
}
