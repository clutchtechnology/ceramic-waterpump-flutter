# Flutter 应用日志配置指南

## 概述

已为 Flutter 应用配置了日志系统，实现以下功能：

1. **Release 模式下**：只记录 error 级别的日志到文件
2. **日志文件位置**：`Release/logs/app.log`（与可执行文件同目录）
3. **开发模式下**：调试日志输出到控制台，不写入文件

## 已完成的修改

### 1. 添加依赖 (pubspec.yaml)

```yaml
dependencies:
  # 日志库
  logger: ^2.0.2+1
  path_provider: ^2.1.2
```

### 2. 创建日志工具类 (lib/utils/app_logger.dart)

```dart
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

class AppLogger {
  static Logger? _logger;
  static File? _logFile;
  static bool _isInitialized = false;

  // 初始化日志系统
  static Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // 获取可执行文件所在目录
      final exeDir = File(Platform.resolvedExecutable).parent;
      
      // 创建 logs 目录
      final logsDir = Directory(path.join(exeDir.path, 'logs'));
      if (!logsDir.existsSync()) {
        logsDir.createSync(recursive: true);
      }

      // 创建日志文件
      _logFile = File(path.join(logsDir.path, 'app.log'));

      // 初始化 Logger (只记录 error 级别)
      _logger = Logger(
        filter: ProductionFilter(),
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 120,
          colors: false,
          printEmojis: false,
          printTime: true,
        ),
        output: _FileOutput(_logFile!),
        level: Level.error, // 只记录 error 级别
      );

      _isInitialized = true;
    } catch (e) {
      print('[日志系统] 初始化失败: $e');
    }
  }

  // 记录错误日志 (只有这个会写入文件)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.e(message, error: error, stackTrace: stackTrace);
  }

  // 获取日志文件路径
  static String? getLogFilePath() {
    return _logFile?.path;
  }

  // 清空日志文件
  static Future<void> clearLog() async {
    try {
      if (_logFile != null && _logFile!.existsSync()) {
        await _logFile!.writeAsString('');
      }
    } catch (e) {
      print('[日志系统] 清空日志失败: $e');
    }
  }
}

// 自定义文件输出类
class _FileOutput extends LogOutput {
  final File file;
  _FileOutput(this.file);

  @override
  void output(OutputEvent event) {
    try {
      final buffer = StringBuffer();
      for (var line in event.lines) {
        buffer.writeln(line);
      }
      file.writeAsStringSync(buffer.toString(), mode: FileMode.append);
    } catch (e) {
      print('[日志系统] 写入日志失败: $e');
    }
  }
}
```

### 3. 在 main.dart 中初始化

```dart
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志系统
  await AppLogger.init();

  // ... 其他初始化代码
  runApp(const MyApp());
}
```

### 4. 移除频繁的调试日志

已移除以下文件中的频繁日志输出：

- `lib/services/realtime_service.dart`：移除了数据接收计数日志
- `lib/services/websocket_service.dart`：保留了错误日志，但有频率控制
- `lib/pages/main_page.dart`：移除了 UI 更新计数日志

## 使用方法

### 开发模式

在开发模式下，调试信息会输出到控制台：

```bash
flutter run -d windows
```

控制台会显示：
- `[RealtimeService]` 相关日志
- `[WebSocket]` 相关日志
- `[MainPage]` 相关日志

### Release 模式（打包）

打包后，只有 **error 级别** 的日志会写入文件：

```bash
flutter build windows --release
```

打包后的目录结构：

```
build/windows/x64/runner/Release/
├── ceramic_waterpump_flutter.exe
├── data/
├── flutter_windows.dll
├── logs/                          # 日志目录（自动创建）
│   └── app.log                    # 日志文件
└── ... 其他文件
```

### 记录错误日志

在代码中使用 `AppLogger.error()` 记录错误：

```dart
import '../utils/app_logger.dart';

try {
  // 可能出错的代码
  await someOperation();
} catch (e, stackTrace) {
  // 记录错误到文件（Release 模式）
  AppLogger.error('操作失败', e, stackTrace);
}
```

### 查看日志文件

打包后运行应用，日志文件位置：

```
C:\Users\20216\Documents\GitHub\Clutch\ceramic-waterpump-flutter\build\windows\x64\runner\Release\logs\app.log
```

### 清空日志

如果需要清空日志文件：

```dart
await AppLogger.clearLog();
```

## 操作步骤

### 1. 安装依赖

在项目目录下运行：

```bash
flutter pub get
```

### 2. 测试开发模式

```bash
flutter run -d windows
```

此时控制台会显示调试日志，但不会写入文件。

### 3. 打包 Release 版本

```bash
flutter build windows --release
```

### 4. 运行打包后的应用

```bash
cd build\windows\x64\runner\Release
.\ceramic_waterpump_flutter.exe
```

### 5. 查看日志文件

```bash
cd build\windows\x64\runner\Release\logs
type app.log
```

## 日志级别说明

| 级别 | 开发模式 | Release 模式 |
|------|---------|-------------|
| debug | 控制台 | 不输出 |
| info | 控制台 | 不输出 |
| warning | 控制台 | 不输出 |
| **error** | 控制台 + 文件 | **文件** |

## 注意事项

1. **日志文件位置**：日志文件始终在可执行文件同目录的 `logs/` 文件夹中
2. **自动创建目录**：首次运行时会自动创建 `logs/` 目录
3. **追加模式**：日志以追加模式写入，不会覆盖旧日志
4. **手动清理**：如果日志文件过大，需要手动删除或调用 `AppLogger.clearLog()`
5. **开发模式**：开发模式下的 `print()` 语句不会写入文件

## 常见问题

### Q1: 为什么开发模式下看不到日志文件？

A: 开发模式下，日志只输出到控制台，不写入文件。只有 Release 模式下的 error 日志才会写入文件。

### Q2: 日志文件在哪里？

A: 日志文件在可执行文件同目录的 `logs/app.log`。例如：
```
build\windows\x64\runner\Release\logs\app.log
```

### Q3: 如何减少日志输出？

A: 已经配置为只记录 error 级别的日志。如果还想进一步减少，可以：
1. 移除代码中的 `print()` 语句
2. 只在关键错误处使用 `AppLogger.error()`

### Q4: 日志文件会无限增长吗？

A: 是的，当前配置不会自动清理日志。如果需要限制大小，可以：
1. 定期手动删除日志文件
2. 调用 `AppLogger.clearLog()` 清空日志
3. 修改 `_FileOutput` 类实现日志轮转（按大小或日期）

## 下一步优化（可选）

如果需要更高级的日志功能，可以考虑：

1. **日志轮转**：按文件大小或日期自动分割日志
2. **日志压缩**：自动压缩旧日志文件
3. **日志上传**：将日志上传到服务器
4. **日志分析**：添加日志统计和分析功能

## 总结

大王，现在您的 Flutter 应用已经配置好日志系统：

1. **开发模式**：调试日志输出到控制台，方便调试
2. **Release 模式**：只有 error 日志写入 `Release/logs/app.log`
3. **日志减少**：移除了频繁的计数日志，只保留关键错误日志
4. **位置固定**：日志文件始终在可执行文件同目录的 `logs/` 文件夹

下次打包后运行应用，日志文件会自动创建在 `Release/logs/app.log`！

