import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'pages/main_page.dart';
import 'utils/app_logger.dart';
import 'utils/responsive_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化日志系统
  await AppLogger.init();

  // 2. 打印响应式配置信息
  ResponsiveConfig.printDebugInfo();

  // 3. 初始化窗口管理器 (Windows/Linux/macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // 使用响应式配置的窗口尺寸 (800×600)
    final windowSize = ResponsiveConfig.windowSize;

    WindowOptions windowOptions = WindowOptions(
      size: windowSize,
      minimumSize: Size(640, 480), // 最小尺寸
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // 隐藏原生标题栏
      windowButtonVisibility: false, // 隐藏原生窗口按钮
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setResizable(true); // 允许调整大小
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceramic Waterpump',
      debugShowCheckedModeBanner: false,
      // 中文本地化支持
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ResponsiveWrapper(child: MainPage()),
    );
  }
}

/// 响应式包装器 - 拉伸填充整个窗口（方案 B）
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 设计稿尺寸
    const designWidth = 1280.0;
    const designHeight = 800.0;

    return FittedBox(
      fit: BoxFit.fill, // 拉伸填充，不保持宽高比
      child: SizedBox(
        width: designWidth,
        height: designHeight,
        child: child,
      ),
    );
  }
}
