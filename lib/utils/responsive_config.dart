// 响应式配置 - 全局缩放管理
// ============================================================
// 功能:
//   - 统一管理应用分辨率和缩放比例
//   - 提供尺寸转换方法 (设计尺寸 → 实际尺寸)
//   - 支持快速切换不同分辨率
// ============================================================

import 'package:flutter/material.dart';

/// 响应式配置类
class ResponsiveConfig {
  // ============================================================
  // 1. 分辨率配置
  // ============================================================
  
  // 1.1 设计稿分辨率 (原始设计尺寸)
  static const double designWidth = 1280.0;
  static const double designHeight = 800.0;
  
  // 1.2 目标分辨率 (实际工控机屏幕)
  static const double targetWidth = 800.0;
  static const double targetHeight = 600.0;
  
  // 1.3 缩放比例 (自动计算)
  static const double scaleFactorWidth = targetWidth / designWidth;   // 0.625
  static const double scaleFactorHeight = targetHeight / designHeight; // 0.75
  
  // 1.4 统一缩放比例 (取较小值，保证不超出屏幕)
  static const double scaleFactor = scaleFactorWidth < scaleFactorHeight 
      ? scaleFactorWidth 
      : scaleFactorHeight; // 0.625
  
  // ============================================================
  // 2. 尺寸转换方法
  // ============================================================
  
  // 2.1 宽度缩放
  static double w(double designWidth) {
    return designWidth * scaleFactor;
  }
  
  // 2.2 高度缩放
  static double h(double designHeight) {
    return designHeight * scaleFactor;
  }
  
  // 2.3 字体大小缩放
  static double sp(double designFontSize) {
    return designFontSize * scaleFactor;
  }
  
  // 2.4 边距/间距缩放
  static double padding(double designPadding) {
    return designPadding * scaleFactor;
  }
  
  // 2.5 圆角半径缩放
  static double radius(double designRadius) {
    return designRadius * scaleFactor;
  }
  
  // 2.6 边框宽度缩放
  static double borderWidth(double designBorderWidth) {
    return designBorderWidth * scaleFactor;
  }
  
  // ============================================================
  // 3. EdgeInsets 缩放
  // ============================================================
  
  // 3.1 对称边距
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: horizontal * scaleFactor,
      vertical: vertical * scaleFactor,
    );
  }
  
  // 3.2 全部边距
  static EdgeInsets all(double value) {
    return EdgeInsets.all(value * scaleFactor);
  }
  
  // 3.3 自定义边距
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: left * scaleFactor,
      top: top * scaleFactor,
      right: right * scaleFactor,
      bottom: bottom * scaleFactor,
    );
  }
  
  // ============================================================
  // 4. Size 缩放
  // ============================================================
  
  static Size size(double width, double height) {
    return Size(width * scaleFactor, height * scaleFactor);
  }
  
  // ============================================================
  // 5. 窗口配置
  // ============================================================
  
  static Size get windowSize => const Size(targetWidth, targetHeight);
  static Size get minimumSize => const Size(targetWidth, targetHeight);
  static Size get maximumSize => const Size(targetWidth, targetHeight);
  
  // ============================================================
  // 6. 调试信息
  // ============================================================
  
  static void printDebugInfo() {
    print('========================================');
    print('ResponsiveConfig 调试信息');
    print('========================================');
    print('设计稿分辨率: ${designWidth.toInt()}×${designHeight.toInt()}');
    print('目标分辨率: ${targetWidth.toInt()}×${targetHeight.toInt()}');
    print('宽度缩放比例: ${scaleFactorWidth.toStringAsFixed(3)}');
    print('高度缩放比例: ${scaleFactorHeight.toStringAsFixed(3)}');
    print('统一缩放比例: ${scaleFactor.toStringAsFixed(3)}');
    print('========================================');
    print('示例转换:');
    print('  设计宽度 100 → 实际宽度 ${w(100).toStringAsFixed(1)}');
    print('  设计高度 100 → 实际高度 ${h(100).toStringAsFixed(1)}');
    print('  设计字体 16 → 实际字体 ${sp(16).toStringAsFixed(1)}');
    print('========================================');
  }
}

// ============================================================
// 7. 扩展方法 (可选，更简洁的写法)
// ============================================================

extension ResponsiveDouble on double {
  // 宽度缩放
  double get w => ResponsiveConfig.w(this);
  
  // 高度缩放
  double get h => ResponsiveConfig.h(this);
  
  // 字体缩放
  double get sp => ResponsiveConfig.sp(this);
  
  // 边距缩放
  double get p => ResponsiveConfig.padding(this);
  
  // 圆角缩放
  double get r => ResponsiveConfig.radius(this);
}

extension ResponsiveInt on int {
  // 宽度缩放
  double get w => ResponsiveConfig.w(toDouble());
  
  // 高度缩放
  double get h => ResponsiveConfig.h(toDouble());
  
  // 字体缩放
  double get sp => ResponsiveConfig.sp(toDouble());
  
  // 边距缩放
  double get p => ResponsiveConfig.padding(toDouble());
  
  // 圆角缩放
  double get r => ResponsiveConfig.radius(toDouble());
}

