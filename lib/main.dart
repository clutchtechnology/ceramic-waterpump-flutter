import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'pages/main_page.dart';
import 'utils/app_logger.dart';
import 'utils/responsive_config.dart';
import 'utils/timer_manager.dart';
import 'utils/ui_watchdog.dart';

void main() async {
  // 捕获所有未处理的异步错误
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. 初始化日志系统
    await AppLogger.init();

    // 2. 捕获 Flutter 框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error('Flutter框架错误', details.exception, details.stack);
      FlutterError.presentError(details);
    };

    // 3. 捕获平台错误
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('平台错误', error, stack);
      return true;
    };

    await _initializeApp();
  }, (error, stack) {
    // 捕获 Zone 外的异步错误
    AppLogger.error('未捕获的异步错误', error, stack);
  });
}

Future<void> _initializeApp() async {
  // 1. 打印响应式配置信息
  ResponsiveConfig.printDebugInfo();

  // 2. 初始化窗口管理器 (Windows/Linux/macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    final windowSize = ResponsiveConfig.windowSize;

    WindowOptions windowOptions = WindowOptions(
      size: windowSize,
      minimumSize: const Size(640, 480),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setResizable(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 3. [CRITICAL] 启动 UI 看门狗（心跳检测 + 帧率监控 + 自动降级）
  UIWatchdog().start();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _cleanupResources();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 统一资源清理方法（dispose 和 detached 都调用）
  void _cleanupResources() {
    if (_isDisposed) return;
    _isDisposed = true;

    debugPrint('[App] 开始清理资源...');

    // 0. [CRITICAL] 停止 UI 看门狗
    UIWatchdog().stop();

    // 1. [CRITICAL] 关闭所有 Timer
    TimerManager().shutdown();

    debugPrint('[App] 资源清理完成');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('[App] 应用进入前台 (resumed)');
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        // [CRITICAL] Windows 关闭时 dispose 可能不执行，这里是最后机会
        debugPrint('[App] 应用即将退出 (detached)');
        _cleanupResources();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ceramic Waterpump',
      debugShowCheckedModeBanner: false,
      // 支持触摸屏拖拽滚动
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
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
