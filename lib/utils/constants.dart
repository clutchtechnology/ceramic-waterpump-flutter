// 应用常量定义
// ============================================================
// 功能:
//   - [C-1] 颜色常量 (从 tech_line_widgets 统一导出)
//   - [C-2] 应用基础配置 (名称/版本/设备数量)
//   - [C-3] 安全配置 (固定密码)
// ============================================================

// [C-1] TechColors 已在 tech_line_widgets.dart 中定义，直接使用 export 避免重复
export '../widgets/tech_line_widgets.dart' show TechColors;

/// [C-2] 应用常量
class AppConstants {
  // 2.1, 应用名称
  static const String appName = '水泵房监控系统';

  // 2.2, 应用版本
  static const String appVersion = '1.0.0';

  // 2.3, 水泵数量 (硬件配置: 6台水泵)
  static const int pumpCount = 6;

  // [C-3] 设置页面固定密码
  static const String fixedPassword = 'clutch86';
}
