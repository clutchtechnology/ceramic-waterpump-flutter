import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

/// [CRITICAL] 统一 Timer 管理器
///
/// 解决的问题:
/// 1. Timer 泄漏: 页面切换时未取消的 Timer 继续运行
/// 2. 重复创建: 同一个 ID 的 Timer 被多次创建
/// 3. 卡死检测: 自动检测长时间未执行的 Timer
/// 4. 资源清理: 应用退出时统一清理所有 Timer
class TimerManager {
  static final TimerManager _instance = TimerManager._internal();
  factory TimerManager() => _instance;
  TimerManager._internal();

  final Map<String, _TimerEntry> _timers = {};
  bool _isShutdown = false;

  /// 注册一个周期性 Timer
  void register(
    String id,
    Duration interval,
    Future<void> Function() callback, {
    String? description,
    bool immediate = false,
  }) {
    if (_isShutdown) {
      AppLogger.warning('TimerManager 已关闭，无法注册 Timer: $id');
      return;
    }

    if (_timers.containsKey(id)) {
      debugPrint('[TimerManager] Timer [$id] 已存在，将先取消旧 Timer');
      cancel(id);
    }

    final entry = _TimerEntry(
      id: id,
      interval: interval,
      callback: callback,
      description: description ?? id,
    );

    _timers[id] = entry;

    if (immediate) {
      _executeCallback(entry);
    }

    entry.start();
    debugPrint('[TimerManager] Timer [$id] 已注册: ${description ?? id}, '
        '间隔: ${interval.inSeconds}s');
  }

  /// 取消 Timer
  void cancel(String id) {
    final entry = _timers.remove(id);
    if (entry != null) {
      entry.dispose();
      debugPrint('[TimerManager] Timer [$id] 已取消');
    }
  }

  /// 暂停 Timer（不删除，可恢复）
  void pause(String id) {
    final entry = _timers[id];
    if (entry != null && !entry.isPaused) {
      entry.pause();
      debugPrint('[TimerManager] Timer [$id] 已暂停');
    }
  }

  /// 恢复 Timer
  void resume(String id) {
    final entry = _timers[id];
    if (entry != null && entry.isPaused) {
      entry.resume();
      debugPrint('[TimerManager] Timer [$id] 已恢复');
    }
  }

  /// 检查 Timer 是否存在
  bool exists(String id) => _timers.containsKey(id);

  /// 检查 Timer 是否暂停
  bool isPaused(String id) => _timers[id]?.isPaused ?? false;

  /// 获取所有活跃的 Timer ID
  List<String> getActiveTimers() {
    return _timers.entries
        .where((e) => !e.value.isPaused)
        .map((e) => e.key)
        .toList();
  }

  /// 执行回调（带异常保护）
  Future<void> _executeCallback(_TimerEntry entry) async {
    if (_isShutdown) return;

    try {
      entry.lastExecuted = DateTime.now();
      await entry.callback();
      entry.executionCount++;
      entry.failureCount = 0;
    } catch (e, stack) {
      entry.failureCount++;
      AppLogger.error(
          'Timer [${entry.id}] 回调异常 (失败${entry.failureCount}次)', e, stack);

      // 连续失败 5 次，自动暂停
      if (entry.failureCount >= 5) {
        AppLogger.error('Timer [${entry.id}] 连续失败 5 次，自动暂停');
        pause(entry.id);
      }
    }
  }

  /// 关闭所有 Timer（应用退出时调用）
  void shutdown() {
    if (_isShutdown) return;
    _isShutdown = true;

    debugPrint('[TimerManager] 正在关闭，取消所有 Timer...');
    final ids = _timers.keys.toList();
    for (final id in ids) {
      cancel(id);
    }
    debugPrint('[TimerManager] 已关闭，共取消 ${ids.length} 个 Timer');
  }

  /// 诊断：检测卡死的 Timer
  void diagnose() {
    final now = DateTime.now();
    for (final entry in _timers.entries) {
      final timer = entry.value;
      if (timer.isPaused) continue;

      final lastExecuted = timer.lastExecuted;
      if (lastExecuted != null) {
        final elapsed = now.difference(lastExecuted);
        final expectedInterval = timer.interval.inSeconds * 2;

        if (elapsed.inSeconds > expectedInterval) {
          AppLogger.warning(
            'Timer [${entry.key}] 可能卡死: 上次执行 ${elapsed.inSeconds}s 前，'
            '预期间隔 ${timer.interval.inSeconds}s',
          );
        }
      }
    }
  }
}

/// Timer 条目（内部类）
class _TimerEntry {
  final String id;
  final Duration interval;
  final Future<void> Function() callback;
  final String description;

  Timer? _timer;
  bool isPaused = false;
  DateTime? lastExecuted;
  int executionCount = 0;
  int failureCount = 0;

  _TimerEntry({
    required this.id,
    required this.interval,
    required this.callback,
    required this.description,
  });

  void start() {
    if (_timer != null) return;

    _timer = Timer.periodic(interval, (timer) async {
      if (isPaused) return;

      try {
        lastExecuted = DateTime.now();
        await callback();
        executionCount++;
        failureCount = 0;
      } catch (e, stack) {
        failureCount++;
        AppLogger.error('Timer [$id] 执行失败 (${failureCount}次)', e, stack);
      }
    });
  }

  void pause() {
    isPaused = true;
  }

  void resume() {
    isPaused = false;
    if (_timer == null) {
      start();
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
