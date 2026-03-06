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
/// - 电压阈值 (6个水泵)
/// - 水压阈值 (高低双阈值)
/// - 速度阈值 (6个水泵)
/// - 位移阈值 (6个水泵)
/// - 频率阈值 (6个水泵)
class ThresholdConfigProvider extends ChangeNotifier {
  static const String _storageKey = 'waterpump_threshold_config_v3';

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // ============================================================
  // 电流阈值配置 I (6个水泵)
  // ============================================================
  final List<ThresholdConfig> iConfigs = [
    ThresholdConfig(
        key: 'pump_1_I',
        displayName: '1号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
    ThresholdConfig(
        key: 'pump_2_I',
        displayName: '2号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
    ThresholdConfig(
        key: 'pump_3_I',
        displayName: '3号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
    ThresholdConfig(
        key: 'pump_4_I',
        displayName: '4号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
    ThresholdConfig(
        key: 'pump_5_I',
        displayName: '5号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
    ThresholdConfig(
        key: 'pump_6_I',
        displayName: '6号泵电流',
        normalMax: 50.0,
        warningMax: 80.0),
  ];

  // ============================================================
  // 电压阈值配置 Ua (6个水泵, 相电压 220V 标准)
  // ============================================================
  final List<ThresholdConfig> uaConfigs = [
    ThresholdConfig(
        key: 'pump_1_Ua',
        displayName: '1号泵电压',
        normalMax: 230.0,
        warningMax: 242.0),
    ThresholdConfig(
        key: 'pump_2_Ua',
        displayName: '2号泵电压',
        normalMax: 230.0,
        warningMax: 242.0),
    ThresholdConfig(
        key: 'pump_3_Ua',
        displayName: '3号泵电压',
        normalMax: 230.0,
        warningMax: 242.0),
    ThresholdConfig(
        key: 'pump_4_Ua',
        displayName: '4号泵电压',
        normalMax: 230.0,
        warningMax: 242.0),
    ThresholdConfig(
        key: 'pump_5_Ua',
        displayName: '5号泵电压',
        normalMax: 230.0,
        warningMax: 242.0),
    ThresholdConfig(
        key: 'pump_6_Ua',
        displayName: '6号泵电压',
        normalMax: 230.0,
        warningMax: 242.0),
  ];

  // ============================================================
  // 水压阈值配置 (高低双阈值)
  // ============================================================
  double pressureHighAlarm = 1.0; // 高压报警阈值 (MPa)
  double pressureLowAlarm = 0.3; // 低压报警阈值 (MPa)

  // ============================================================
  // 速度阈值配置 (6个水泵, 振动速度 mm/s)
  // ============================================================
  final List<ThresholdConfig> speedConfigs = [
    ThresholdConfig(
        key: 'pump_1_speed',
        displayName: '1号泵速度',
        normalMax: 3.5,
        warningMax: 4.5),
    ThresholdConfig(
        key: 'pump_2_speed',
        displayName: '2号泵速度',
        normalMax: 3.5,
        warningMax: 4.5),
    ThresholdConfig(
        key: 'pump_3_speed',
        displayName: '3号泵速度',
        normalMax: 3.5,
        warningMax: 4.5),
    ThresholdConfig(
        key: 'pump_4_speed',
        displayName: '4号泵速度',
        normalMax: 3.5,
        warningMax: 4.5),
    ThresholdConfig(
        key: 'pump_5_speed',
        displayName: '5号泵速度',
        normalMax: 3.5,
        warningMax: 4.5),
    ThresholdConfig(
        key: 'pump_6_speed',
        displayName: '6号泵速度',
        normalMax: 3.5,
        warningMax: 4.5),
  ];

  // ============================================================
  // 位移阈值配置 (6个水泵, 振动位移 um)
  // ============================================================
  final List<ThresholdConfig> displacementConfigs = [
    ThresholdConfig(
        key: 'pump_1_displacement',
        displayName: '1号泵位移',
        normalMax: 20.0,
        warningMax: 30.0),
    ThresholdConfig(
        key: 'pump_2_displacement',
        displayName: '2号泵位移',
        normalMax: 20.0,
        warningMax: 30.0),
    ThresholdConfig(
        key: 'pump_3_displacement',
        displayName: '3号泵位移',
        normalMax: 20.0,
        warningMax: 30.0),
    ThresholdConfig(
        key: 'pump_4_displacement',
        displayName: '4号泵位移',
        normalMax: 20.0,
        warningMax: 30.0),
    ThresholdConfig(
        key: 'pump_5_displacement',
        displayName: '5号泵位移',
        normalMax: 20.0,
        warningMax: 30.0),
    ThresholdConfig(
        key: 'pump_6_displacement',
        displayName: '6号泵位移',
        normalMax: 20.0,
        warningMax: 30.0),
  ];

  // ============================================================
  // 频率阈值配置 (6个水泵)
  // ============================================================
  final List<ThresholdConfig> frequencyConfigs = [
    ThresholdConfig(
        key: 'pump_1_frequency',
        displayName: '1号泵频率',
        normalMax: 50.0,
        warningMax: 52.0),
    ThresholdConfig(
        key: 'pump_2_frequency',
        displayName: '2号泵频率',
        normalMax: 50.0,
        warningMax: 52.0),
    ThresholdConfig(
        key: 'pump_3_frequency',
        displayName: '3号泵频率',
        normalMax: 50.0,
        warningMax: 52.0),
    ThresholdConfig(
        key: 'pump_4_frequency',
        displayName: '4号泵频率',
        normalMax: 50.0,
        warningMax: 52.0),
    ThresholdConfig(
        key: 'pump_5_frequency',
        displayName: '5号泵频率',
        normalMax: 50.0,
        warningMax: 52.0),
    ThresholdConfig(
        key: 'pump_6_frequency',
        displayName: '6号泵频率',
        normalMax: 50.0,
        warningMax: 52.0),
  ];

  // ============================================================
  // 功率阈值配置 Pt (6个水泵)
  // ============================================================
  final List<ThresholdConfig> ptConfigs = [
    ThresholdConfig(
        key: 'pump_1_Pt',
        displayName: '1号泵功率',
        normalMax: 10.0,
        warningMax: 15.0),
    ThresholdConfig(
        key: 'pump_2_Pt',
        displayName: '2号泵功率',
        normalMax: 10.0,
        warningMax: 15.0),
    ThresholdConfig(
        key: 'pump_3_Pt',
        displayName: '3号泵功率',
        normalMax: 10.0,
        warningMax: 15.0),
    ThresholdConfig(
        key: 'pump_4_Pt',
        displayName: '4号泵功率',
        normalMax: 10.0,
        warningMax: 15.0),
    ThresholdConfig(
        key: 'pump_5_Pt',
        displayName: '5号泵功率',
        normalMax: 10.0,
        warningMax: 15.0),
    ThresholdConfig(
        key: 'pump_6_Pt',
        displayName: '6号泵功率',
        normalMax: 10.0,
        warningMax: 15.0),
  ];

  // ============================================================
  // 运行功率阈值配置 (6个水泵)
  // 功率 >= 此阈值 判定为"运行中"，否则为"停止"
  // ============================================================
  final List<double> runningPowerThresholds = [
    0.5, // 1号泵运行功率阈值 (kW)
    0.5, // 2号泵运行功率阈值 (kW)
    0.5, // 3号泵运行功率阈值 (kW)
    0.5, // 4号泵运行功率阈值 (kW)
    0.5, // 5号泵运行功率阈值 (kW)
    0.5, // 6号泵运行功率阈值 (kW)
  ];

  // ============================================================
  // 振动阈值配置 (6个水泵)
  // ============================================================
  final List<ThresholdConfig> vibrationConfigs = [
    ThresholdConfig(
        key: 'pump_1_vibration',
        displayName: '1号泵振动',
        normalMax: 5.0,
        warningMax: 10.0),
    ThresholdConfig(
        key: 'pump_2_vibration',
        displayName: '2号泵振动',
        normalMax: 5.0,
        warningMax: 10.0),
    ThresholdConfig(
        key: 'pump_3_vibration',
        displayName: '3号泵振动',
        normalMax: 5.0,
        warningMax: 10.0),
    ThresholdConfig(
        key: 'pump_4_vibration',
        displayName: '4号泵振动',
        normalMax: 5.0,
        warningMax: 10.0),
    ThresholdConfig(
        key: 'pump_5_vibration',
        displayName: '5号泵振动',
        normalMax: 5.0,
        warningMax: 10.0),
    ThresholdConfig(
        key: 'pump_6_vibration',
        displayName: '6号泵振动',
        normalMax: 5.0,
        warningMax: 10.0),
  ];

  /// 从本地存储加载配置，优先从后端获取最新配置
  Future<void> loadConfig() async {
    try {
      // 1. 尝试从后端加载最新阈值配置
      final backendLoaded = await _loadFromBackend();
      if (backendLoaded) {
        debugPrint('[ThresholdConfig] 已从后端加载阈值配置');
        _isLoaded = true;
        notifyListeners();
        return;
      }

      // 2. 后端不可用，从本地存储加载
      debugPrint('[ThresholdConfig] 后端不可用，从本地存储加载');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        _loadFromJson(jsonData);
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[ThresholdConfig] 加载阈值配置失败: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// 从后端 API 加载阈值配置
  /// 返回 true 表示加载成功
  Future<bool> _loadFromBackend() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(Api.thresholds);

      if (response == null || response['success'] != true) {
        return false;
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      _loadFromBackendJson(data);
      return true;
    } catch (e) {
      debugPrint('[ThresholdConfig] 从后端加载失败: $e');
      return false;
    }
  }

  /// 解析后端返回的阈值格式
  /// 后端格式: {"current": {"pump_1": {"normal_max": 50.0, "warning_max": 80.0}}, ...}
  void _loadFromBackendJson(Map<String, dynamic> json) {
    // 加载电流配置 (后端 key: current)
    _loadPumpConfigsFromBackend(json, 'current', iConfigs);

    // 加载电压配置 (后端 key: voltage)
    _loadPumpConfigsFromBackend(json, 'voltage', uaConfigs);

    // 加载压力配置
    if (json['pressure'] != null) {
      final data = json['pressure'] as Map<String, dynamic>;
      pressureHighAlarm =
          (data['high_alarm'] as num?)?.toDouble() ?? pressureHighAlarm;
      pressureLowAlarm =
          (data['low_alarm'] as num?)?.toDouble() ?? pressureLowAlarm;
    }

    // 加载速度配置
    _loadPumpConfigsFromBackend(json, 'speed', speedConfigs);

    // 加载位移配置
    _loadPumpConfigsFromBackend(json, 'displacement', displacementConfigs);

    // 加载频率配置
    _loadPumpConfigsFromBackend(json, 'frequency', frequencyConfigs);

    // 加载运行功率阈值 (后端 key: running_power, 值为单个 float)
    if (json['running_power'] != null) {
      final data = json['running_power'] as Map<String, dynamic>;
      for (int i = 0; i < runningPowerThresholds.length; i++) {
        final pumpKey = 'pump_${i + 1}';
        if (data[pumpKey] != null) {
          runningPowerThresholds[i] =
              (data[pumpKey] as num?)?.toDouble() ?? runningPowerThresholds[i];
        }
      }
    }
  }

  /// 从后端 JSON 加载水泵参数配置的通用方法
  /// 后端格式: {"pump_1": {"normal_max": x, "warning_max": y}, ...}
  void _loadPumpConfigsFromBackend(
      Map<String, dynamic> json, String key, List<ThresholdConfig> configs) {
    if (json[key] == null) return;
    final data = json[key] as Map<String, dynamic>;

    for (int i = 0; i < configs.length; i++) {
      final pumpKey = 'pump_${i + 1}';
      if (data[pumpKey] != null) {
        final item = data[pumpKey] as Map<String, dynamic>;
        configs[i].normalMax =
            (item['normal_max'] as num?)?.toDouble() ?? configs[i].normalMax;
        configs[i].warningMax =
            (item['warning_max'] as num?)?.toDouble() ?? configs[i].warningMax;
      }
    }
  }

  void _loadFromJson(Map<String, dynamic> json) {
    // 加载电流配置
    if (json['I'] != null) {
      final data = json['I'] as Map<String, dynamic>;
      for (var config in iConfigs) {
        if (data[config.key] != null) {
          final item = data[config.key] as Map<String, dynamic>;
          config.normalMax =
              (item['normalMax'] as num?)?.toDouble() ?? config.normalMax;
          config.warningMax =
              (item['warningMax'] as num?)?.toDouble() ?? config.warningMax;
        }
      }
    }

    // 加载电压配置
    if (json['Ua'] != null) {
      final data = json['Ua'] as Map<String, dynamic>;
      for (var config in uaConfigs) {
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

    // 加载速度配置
    if (json['speed'] != null) {
      final data = json['speed'] as Map<String, dynamic>;
      for (var config in speedConfigs) {
        if (data[config.key] != null) {
          final item = data[config.key] as Map<String, dynamic>;
          config.normalMax =
              (item['normalMax'] as num?)?.toDouble() ?? config.normalMax;
          config.warningMax =
              (item['warningMax'] as num?)?.toDouble() ?? config.warningMax;
        }
      }
    }

    // 加载位移配置
    if (json['displacement'] != null) {
      final data = json['displacement'] as Map<String, dynamic>;
      for (var config in displacementConfigs) {
        if (data[config.key] != null) {
          final item = data[config.key] as Map<String, dynamic>;
          config.normalMax =
              (item['normalMax'] as num?)?.toDouble() ?? config.normalMax;
          config.warningMax =
              (item['warningMax'] as num?)?.toDouble() ?? config.warningMax;
        }
      }
    }

    // 加载频率配置
    if (json['frequency'] != null) {
      final data = json['frequency'] as Map<String, dynamic>;
      for (var config in frequencyConfigs) {
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
    if (json['Pt'] != null) {
      final data = json['Pt'] as Map<String, dynamic>;
      for (var config in ptConfigs) {
        if (data[config.key] != null) {
          final item = data[config.key] as Map<String, dynamic>;
          config.normalMax =
              (item['normalMax'] as num?)?.toDouble() ?? config.normalMax;
          config.warningMax =
              (item['warningMax'] as num?)?.toDouble() ?? config.warningMax;
        }
      }
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

    // 加载运行功率阈值配置
    if (json['runningPower'] != null) {
      final data = json['runningPower'] as Map<String, dynamic>;
      for (int i = 0; i < runningPowerThresholds.length; i++) {
        final key = 'pump_${i + 1}';
        if (data[key] != null) {
          runningPowerThresholds[i] =
              (data[key] as num?)?.toDouble() ?? runningPowerThresholds[i];
        }
      }
    }
  }

  Map<String, dynamic> _toJson() {
    return {
      'I': {
        for (var config in iConfigs)
          config.key: {
            'normalMax': config.normalMax,
            'warningMax': config.warningMax
          }
      },
      'Ua': {
        for (var config in uaConfigs)
          config.key: {
            'normalMax': config.normalMax,
            'warningMax': config.warningMax
          }
      },
      'pressure': {
        'high': pressureHighAlarm,
        'low': pressureLowAlarm,
      },
      'speed': {
        for (var config in speedConfigs)
          config.key: {
            'normalMax': config.normalMax,
            'warningMax': config.warningMax
          }
      },
      'displacement': {
        for (var config in displacementConfigs)
          config.key: {
            'normalMax': config.normalMax,
            'warningMax': config.warningMax
          }
      },
      'frequency': {
        for (var config in frequencyConfigs)
          config.key: {
            'normalMax': config.normalMax,
            'warningMax': config.warningMax
          }
      },
      'Pt': {
        for (var config in ptConfigs)
          config.key: {
            'normalMax': config.normalMax,
            'warningMax': config.warningMax
          }
      },
      'vibration': {
        for (var config in vibrationConfigs)
          config.key: {
            'normalMax': config.normalMax,
            'warningMax': config.warningMax
          }
      },
      'runningPower': {
        for (int i = 0; i < runningPowerThresholds.length; i++)
          'pump_${i + 1}': runningPowerThresholds[i],
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
        debugPrint(' 本地保存成功，但后端同步失败');
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
        debugPrint(' 阈值配置已同步到后端');
        return true;
      } else {
        debugPrint(' 后端同步失败: ${response?['error']}');
        return false;
      }
    } catch (e) {
      debugPrint(' 后端同步异常: $e');
      return false;
    }
  }

  /// 转换为后端格式的JSON
  /// 后端 ThresholdUpdateRequest 接受: current, voltage, pressure, speed, displacement, frequency
  Map<String, dynamic> _toBackendJson() {
    return {
      'current': {
        for (int i = 0; i < iConfigs.length; i++)
          'pump_${i + 1}': {
            'normal_max': iConfigs[i].normalMax,
            'warning_max': iConfigs[i].warningMax,
          }
      },
      'voltage': {
        for (int i = 0; i < uaConfigs.length; i++)
          'pump_${i + 1}': {
            'normal_max': uaConfigs[i].normalMax,
            'warning_max': uaConfigs[i].warningMax,
          }
      },
      'pressure': {
        'high_alarm': pressureHighAlarm,
        'low_alarm': pressureLowAlarm,
      },
      'speed': {
        for (int i = 0; i < speedConfigs.length; i++)
          'pump_${i + 1}': {
            'normal_max': speedConfigs[i].normalMax,
            'warning_max': speedConfigs[i].warningMax,
          }
      },
      'displacement': {
        for (int i = 0; i < displacementConfigs.length; i++)
          'pump_${i + 1}': {
            'normal_max': displacementConfigs[i].normalMax,
            'warning_max': displacementConfigs[i].warningMax,
          }
      },
      'frequency': {
        for (int i = 0; i < frequencyConfigs.length; i++)
          'pump_${i + 1}': {
            'normal_max': frequencyConfigs[i].normalMax,
            'warning_max': frequencyConfigs[i].warningMax,
          }
      },
      'running_power': {
        for (int i = 0; i < runningPowerThresholds.length; i++)
          'pump_${i + 1}': runningPowerThresholds[i],
      },
    };
  }

  // ============================================================
  // 更新配置方法
  // ============================================================

  /// 更新电流配置
  void updateIConfig(int index, {double? normalMax, double? warningMax}) {
    if (index >= 0 && index < iConfigs.length) {
      if (normalMax != null) iConfigs[index].normalMax = normalMax;
      if (warningMax != null) iConfigs[index].warningMax = warningMax;
      notifyListeners();
    }
  }

  /// 更新电压配置
  void updateUaConfig(int index, {double? normalMax, double? warningMax}) {
    if (index >= 0 && index < uaConfigs.length) {
      if (normalMax != null) uaConfigs[index].normalMax = normalMax;
      if (warningMax != null) uaConfigs[index].warningMax = warningMax;
      notifyListeners();
    }
  }

  /// 更新压力配置
  void updatePressureConfig({double? highAlarm, double? lowAlarm}) {
    if (highAlarm != null) pressureHighAlarm = highAlarm;
    if (lowAlarm != null) pressureLowAlarm = lowAlarm;
    notifyListeners();
  }

  /// 更新速度配置
  void updateSpeedConfig(int index, {double? normalMax, double? warningMax}) {
    if (index >= 0 && index < speedConfigs.length) {
      if (normalMax != null) speedConfigs[index].normalMax = normalMax;
      if (warningMax != null) speedConfigs[index].warningMax = warningMax;
      notifyListeners();
    }
  }

  /// 更新位移配置
  void updateDisplacementConfig(int index,
      {double? normalMax, double? warningMax}) {
    if (index >= 0 && index < displacementConfigs.length) {
      if (normalMax != null) displacementConfigs[index].normalMax = normalMax;
      if (warningMax != null)
        displacementConfigs[index].warningMax = warningMax;
      notifyListeners();
    }
  }

  /// 更新频率配置
  void updateFrequencyConfig(int index,
      {double? normalMax, double? warningMax}) {
    if (index >= 0 && index < frequencyConfigs.length) {
      if (normalMax != null) frequencyConfigs[index].normalMax = normalMax;
      if (warningMax != null) frequencyConfigs[index].warningMax = warningMax;
      notifyListeners();
    }
  }

  /// 更新功率配置
  void updatePtConfig(int index, {double? normalMax, double? warningMax}) {
    if (index >= 0 && index < ptConfigs.length) {
      if (normalMax != null) ptConfigs[index].normalMax = normalMax;
      if (warningMax != null) ptConfigs[index].warningMax = warningMax;
      notifyListeners();
    }
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
    for (var config in iConfigs) {
      config.normalMax = 50.0;
      config.warningMax = 80.0;
    }
    // 重置电压 (相电压 220V 标准)
    for (var config in uaConfigs) {
      config.normalMax = 230.0;
      config.warningMax = 242.0;
    }
    // 重置压力
    pressureHighAlarm = 1.0;
    pressureLowAlarm = 0.3;
    // 重置速度 (振动速度 mm/s)
    for (var config in speedConfigs) {
      config.normalMax = 3.5;
      config.warningMax = 4.5;
    }
    // 重置位移 (振动位移 um)
    for (var config in displacementConfigs) {
      config.normalMax = 20.0;
      config.warningMax = 30.0;
    }
    // 重置频率
    for (var config in frequencyConfigs) {
      config.normalMax = 50.0;
      config.warningMax = 52.0;
    }
    // 重置功率
    for (var config in ptConfigs) {
      config.normalMax = 10.0;
      config.warningMax = 15.0;
    }
    // 重置振动
    for (var config in vibrationConfigs) {
      config.normalMax = 5.0;
      config.warningMax = 10.0;
    }
    // 重置运行功率阈值
    for (int i = 0; i < runningPowerThresholds.length; i++) {
      runningPowerThresholds[i] = 0.5;
    }
    notifyListeners();
  }

  // ============================================================
  // 便捷获取颜色的方法
  // ============================================================

  /// 获取电流颜色 (泵索引 1-6)
  Color getIColor(int pumpIndex, double current) {
    if (pumpIndex < 1 || pumpIndex > iConfigs.length) {
      return ThresholdColors.normal;
    }
    return iConfigs[pumpIndex - 1].getColor(current);
  }

  /// 获取电压颜色 (泵索引 1-6)
  Color getUaColor(int pumpIndex, double voltage) {
    if (pumpIndex < 1 || pumpIndex > uaConfigs.length) {
      return ThresholdColors.normal;
    }
    return uaConfigs[pumpIndex - 1].getColor(voltage);
  }

  /// 获取压力颜色
  /// 低于lowAlarm: 红色报警
  /// 高于highAlarm: 红色报警
  /// 在范围内: 绿色正常
  /// 注意：压力只有正常和报警两种状态，没有警告状态
  Color getPressureColor(double pressure) {
    if (pressure < pressureLowAlarm || pressure > pressureHighAlarm) {
      return ThresholdColors.alarm;
    }
    return ThresholdColors.normal;
  }

  /// 获取速度颜色 (泵索引 1-6)
  Color getSpeedColor(int pumpIndex, double speed) {
    if (pumpIndex < 1 || pumpIndex > speedConfigs.length) {
      return ThresholdColors.normal;
    }
    return speedConfigs[pumpIndex - 1].getColor(speed);
  }

  /// 获取位移颜色 (泵索引 1-6)
  Color getDisplacementColor(int pumpIndex, double displacement) {
    if (pumpIndex < 1 || pumpIndex > displacementConfigs.length) {
      return ThresholdColors.normal;
    }
    return displacementConfigs[pumpIndex - 1].getColor(displacement);
  }

  /// 获取频率颜色 (泵索引 1-6)
  Color getFrequencyColor(int pumpIndex, double frequency) {
    if (pumpIndex < 1 || pumpIndex > frequencyConfigs.length) {
      return ThresholdColors.normal;
    }
    return frequencyConfigs[pumpIndex - 1].getColor(frequency);
  }

  /// 获取功率颜色 (泵索引 1-6)
  Color getPtColor(int pumpIndex, double power) {
    if (pumpIndex < 1 || pumpIndex > ptConfigs.length) {
      return ThresholdColors.normal;
    }
    return ptConfigs[pumpIndex - 1].getColor(power);
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
  ThresholdConfig? getIThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > iConfigs.length) return null;
    return iConfigs[pumpIndex - 1];
  }

  /// 获取电压阈值配置 (泵索引 1-6)
  ThresholdConfig? getUaThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > uaConfigs.length) return null;
    return uaConfigs[pumpIndex - 1];
  }

  /// 获取速度阈值配置 (泵索引 1-6)
  ThresholdConfig? getSpeedThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > speedConfigs.length) return null;
    return speedConfigs[pumpIndex - 1];
  }

  /// 获取位移阈值配置 (泵索引 1-6)
  ThresholdConfig? getDisplacementThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > displacementConfigs.length) return null;
    return displacementConfigs[pumpIndex - 1];
  }

  /// 获取频率阈值配置 (泵索引 1-6)
  ThresholdConfig? getFrequencyThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > frequencyConfigs.length) return null;
    return frequencyConfigs[pumpIndex - 1];
  }

  /// 获取功率阈值配置 (泵索引 1-6)
  ThresholdConfig? getPtThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > ptConfigs.length) return null;
    return ptConfigs[pumpIndex - 1];
  }

  /// 获取振动阈值配置 (泵索引 1-6)
  ThresholdConfig? getVibrationThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > vibrationConfigs.length) return null;
    return vibrationConfigs[pumpIndex - 1];
  }

  // ============================================================
  // 运行状态判断
  // ============================================================

  /// 判断水泵是否运行中 (泵索引 1-6)
  /// 功率 >= 运行功率阈值 则判定为运行中
  bool isPumpRunning(int pumpIndex, double power) {
    if (pumpIndex < 1 || pumpIndex > runningPowerThresholds.length) {
      return false;
    }
    return power >= runningPowerThresholds[pumpIndex - 1];
  }

  /// 获取运行功率阈值 (泵索引 1-6)
  double getRunningPowerThreshold(int pumpIndex) {
    if (pumpIndex < 1 || pumpIndex > runningPowerThresholds.length) {
      return 0.5;
    }
    return runningPowerThresholds[pumpIndex - 1];
  }

  /// 更新运行功率阈值 (泵索引 0-5)
  void updateRunningPowerThreshold(int index, double value) {
    if (index >= 0 && index < runningPowerThresholds.length && value >= 0) {
      runningPowerThresholds[index] = value;
      notifyListeners();
    }
  }
}
