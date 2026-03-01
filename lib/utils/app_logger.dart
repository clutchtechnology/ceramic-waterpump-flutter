import 'dart:io';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

class AppLogger {
  static Logger? _logger;
  static File? _logFile;
  static Directory? _logsDir;
  static bool _isInitialized = false;
  static String _currentDate = '';

  // 日志保留天数
  static const int _retentionDays = 30;

  // 1. 初始化日志系统
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      final exeDir = File(Platform.resolvedExecutable).parent;

      _logsDir = Directory(path.join(exeDir.path, 'logs'));
      if (!_logsDir!.existsSync()) {
        _logsDir!.createSync(recursive: true);
      }

      // 按日期创建日志文件: app.log.2026-02-09
      _currentDate = _todayString();
      _logFile = File(path.join(_logsDir!.path, 'app.log.$_currentDate'));
      // 新建时写入 UTF-8 BOM，使 Windows GBK 系统能正确识别 UTF-8 编码
      _writeBomIfNew(_logFile!);

      _logger = Logger(
        filter: _CustomFilter(),
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 120,
          colors: false,
          printEmojis: false,
          printTime: true,
        ),
        output: _DailyFileOutput(),
        level: Level.warning,
      );

      _isInitialized = true;

      // 清理过期日志文件
      _cleanOldLogs();

      if (!_isReleaseMode()) {
        print('[AppLogger] init ok: ${_logFile!.path}');
      }
    } catch (e) {
      print('[AppLogger] init failed: $e');
    }
  }

  // 2. 记录警告日志
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.w(message, error: error, stackTrace: stackTrace);
  }

  // 3. 记录错误日志
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.e(message, error: error, stackTrace: stackTrace);
  }

  // 4. 判断是否为 Release 模式
  static bool _isReleaseMode() {
    return const bool.fromEnvironment('dart.vm.product');
  }

  // 5. 获取日志文件路径
  static String? getLogFilePath() {
    return _logFile?.path;
  }

  // 6. 获取今天的日期字符串 (YYYY-MM-DD)
  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // 6.5 新建日志文件时写入 UTF-8 BOM
  static void _writeBomIfNew(File file) {
    try {
      if (!file.existsSync()) {
        file.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
      }
    } catch (e) {
      print('[AppLogger] write bom failed: $e');
    }
  }

  // 7. 检查日期是否变更，如变更则切换日志文件
  static void _checkDateRotation() {
    final today = _todayString();
    if (today != _currentDate && _logsDir != null) {
      _currentDate = today;
      _logFile = File(path.join(_logsDir!.path, 'app.log.$_currentDate'));
      // 新日期文件写入 UTF-8 BOM
      _writeBomIfNew(_logFile!);
      _cleanOldLogs();
    }
  }

  // 8. 清理超过30天的日志文件
  static void _cleanOldLogs() {
    try {
      if (_logsDir == null || !_logsDir!.existsSync()) return;

      final cutoff =
          DateTime.now().subtract(const Duration(days: _retentionDays));
      final pattern = RegExp(r'^app\.log\.(\d{4}-\d{2}-\d{2})$');

      for (final entity in _logsDir!.listSync()) {
        if (entity is! File) continue;
        final fileName = path.basename(entity.path);
        final match = pattern.firstMatch(fileName);
        if (match == null) continue;

        final dateStr = match.group(1)!;
        final fileDate = DateTime.tryParse(dateStr);
        if (fileDate != null && fileDate.isBefore(cutoff)) {
          entity.deleteSync();
          if (!_isReleaseMode()) {
            print('[AppLogger] deleted expired log: $fileName');
          }
        }
      }
    } catch (e) {
      print('[AppLogger] clean old logs failed: $e');
    }
  }
}

// 按日期自动轮转的文件输出
class _DailyFileOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    try {
      // 每次写入前检查日期轮转
      AppLogger._checkDateRotation();

      final file = AppLogger._logFile;
      if (file == null) return;

      final buffer = StringBuffer();
      for (var line in event.lines) {
        buffer.writeln(line);
      }
      // 强制 UTF-8 编码，避免中文系统下乱码
      file.writeAsStringSync(buffer.toString(),
          mode: FileMode.append, encoding: utf8);
    } catch (e) {
      print('[AppLogger] write failed: $e');
    }
  }
}

// 自定义过滤器 - 生产环境也记录 warning 和 error
class _CustomFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return event.level.index >= Level.warning.index;
  }
}
