// TechColors 已在 tech_line_widgets.dart 中定义，直接使用 export 避免重复
export '../widgets/tech_line_widgets.dart' show TechColors;

/// API 配置
class ApiConfig {
  static const String baseUrl = 'http://localhost:8081/api/waterpump'; // 连接本地后端
  static const Duration timeout = Duration(seconds: 5);
}

/// 应用常量
class AppConstants {
  static const String appName = '水泵房监控系统';
  static const String appVersion = '1.0.0';
  static const int pumpCount = 6;
  static const int refreshInterval = 1000; // 毫秒
  static const String fixedPassword = 'clutch86';
}

/// 阈值默认值 (6个水泵)
class DefaultThresholds {
  static const Map<String, dynamic> pump = {
    'voltageMin': 360.0, // 报警下限 (红色)
    'voltageWarningMin': 370.0, // 警告下限 (黄色)
    'voltageWarningMax': 390.0, // 警告上限 (黄色)
    'voltageMax': 400.0, // 报警上限 (红色)
    'currentMax': 50.0,
    'powerMax': 30.0,
  };

  static const Map<String, dynamic> pressure = {
    'min': 0.2, // 报警下限
    'warningMin': 0.3, // 警告下限
    'warningMax': 0.8, // 警告上限
    'max': 1.0, // 报警上限
  };
}
