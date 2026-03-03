import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../api/api_client.dart';
import '../widgets/tech_line_widgets.dart';
import '../widgets/custom_card_widget.dart';
import '../widgets/health_indicator.dart';
import '../services/health_service.dart';
import '../services/realtime_service.dart';
import '../services/websocket_service.dart';
import '../models/pump_data.dart';
import '../providers/threshold_config_provider.dart';
import '../utils/ui_watchdog.dart';
import 'history_data_page.dart';
import 'alarm_log_page.dart';
import 'settings_page.dart';
import 'sensor_status_page.dart';

/// 主页面 - 带Tab导航
/// Tab1: 实时监控 (水泵卡片)
/// Tab2: 历史数据 (图表)
/// Tab3: 报警记录
/// Tab4: 系统设置
/// Tab5: 设备状态
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin, WindowListener {
  // 1, Tab 控制器
  late TabController _tabController;

  // 2, 服务单例 (避免重复创建)
  final HealthService _healthService = HealthService();
  final RealtimeService _realtimeService = RealtimeService();
  final WebSocketService _wsService = WebSocketService();

  // 3, 阈值配置 Provider (共享给 SettingsPage)
  final ThresholdConfigProvider _thresholdProvider = ThresholdConfigProvider();

  // 4, HistoryDataPage 的 GlobalKey，用于调用刷新方法
  final GlobalKey<HistoryDataPageState> _historyPageKey = GlobalKey();

  // 5, 状态页 GlobalKey，用于控制轮询
  final GlobalKey<SensorStatusPageState> _statusPageKey = GlobalKey();

  // 6, 跟踪当前 Tab 索引 (用于控制轮询)
  int _currentTabIndex = 0;

  // 7, 时钟定时器
  Timer? _clockTimer;
  String _clockTime = '';

  // 10, 窗口状态: 最小化后自动恢复全屏
  bool _restoreFullScreenAfterMinimize = false;

  // 8, 健康状态
  bool _serverHealthy = false;
  bool _plcHealthy = false;
  bool _dbHealthy = false;
  bool _isHealthLoading = true;
  Timer? _healthCheckTimer;

  // 9, 实时数据
  RealtimeBatchResponse? _realtimeData;

  // [CRITICAL] WebSocket 节流控制：后端 0.1s 推送，UI 根据看门狗状态动态调整
  // normal=1s, degraded=3s, critical=5s，防止工控机过载
  DateTime? _lastWsUiUpdate;
  Duration get _wsUiThrottle => UIWatchdog().getThrottle(
        normal: const Duration(seconds: 1),
        degraded: const Duration(seconds: 3),
        critical: const Duration(seconds: 5),
      );

  @override
  void initState() {
    super.initState();
    // 10, 注册窗口事件监听
    windowManager.addListener(this);

    // 1, 初始化 Tab 控制器（5个Tab：实时数据、历史数据、报警记录、系统设置、设备状态）
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);

    // 3, 加载阈值配置并监听变化
    _thresholdProvider.loadConfig();
    _thresholdProvider.addListener(_onThresholdChanged);

    // 8, 启动健康检查
    _startHealthCheck();

    // 9, 启动实时数据轮询
    _startRealtimePolling();

    // 7, 启动时钟定时器
    _startClockTimer();
  }

  /// 3, 阈值配置变化回调 - 触发 UI 重建更新颜色
  void _onThresholdChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 6, Tab 切换回调 - 控制各页面轮询
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final newIndex = _tabController.index;
    final oldIndex = _currentTabIndex;
    _currentTabIndex = newIndex;

    // 5, 离开状态页时暂停轮询
    if (oldIndex == 4) {
      _statusPageKey.currentState?.pausePolling();
    }

    // 4, 进入历史数据页面时刷新
    if (newIndex == 1) {
      _historyPageKey.currentState?.refreshData();
    }
    // 5, 进入状态页面时恢复轮询
    else if (newIndex == 4) {
      _statusPageKey.currentState?.resumePolling();
    }
  }

  /// 7, 启动时钟定时器 (替代 StreamBuilder 避免无法取消的 Stream)
  void _startClockTimer() {
    _updateClockTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateClockTime();
    });
  }

  /// 7, 更新时钟显示
  void _updateClockTime() {
    if (!mounted) return;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    if (_clockTime != timeStr) {
      setState(() {
        _clockTime = timeStr;
      });
    }
  }

  @override
  void dispose() {
    // 1, 移除 Tab 监听器
    _tabController.removeListener(_onTabChanged);

    // 3, 移除阈值监听器
    _thresholdProvider.removeListener(_onThresholdChanged);

    // 1, 释放 Tab 控制器
    _tabController.dispose();

    // 8, 取消健康检查定时器
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    // 7, 取消时钟定时器
    _clockTimer?.cancel();
    _clockTimer = null;

    // 10, 移除窗口事件监听
    windowManager.removeListener(this);

    // 2, 释放服务资源
    _healthService.dispose();
    _realtimeService.dispose();

    // 释放 WebSocket 服务 (应用退出时)
    _wsService.dispose();

    // 清理 HTTP 客户端 (应用退出时)
    ApiClient.dispose();

    super.dispose();
  }

  /// 8, 启动健康状态检查 (每 10 秒)
  void _startHealthCheck() {
    _checkHealth();
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (!mounted) return;
        _checkHealth();
      },
    );
  }

  /// 9, 启动实时数据轮询 (每 5 秒)
  void _startRealtimePolling() {
    _realtimeService.onDataUpdate = (data) {
      if (!mounted) return;

      // [CRITICAL] 无论节流与否，始终更新内部数据变量（保证数据最新）
      _realtimeData = data;

      // [CRITICAL] 节流 setState：后端 0.1s 推送，UI 最多 1s 重建一次
      // 防止 10Hz 全量重建超复杂 Widget 树导致工控机主线程卡死
      final now = DateTime.now();
      final lastUiUpdate = _lastWsUiUpdate;
      if (lastUiUpdate == null ||
          now.difference(lastUiUpdate) >= _wsUiThrottle) {
        _lastWsUiUpdate = now;
        setState(() {
          // 数据已在上方更新，此处 setState 仅触发重建
        });
      }
    };

    _realtimeService.onError = (error) {
      // 仅在调试模式打印错误，避免日志泛滥
      assert(() {
        debugPrint('[MainPage] 实时数据错误: $error');
        return true;
      }());
    };

    // 监听 WebSocket 连接状态
    _realtimeService.onConnectionStateChanged = (state) {
      // 连接状态变化时的处理（如需显示可添加状态字段）
      if (mounted) {
        debugPrint('[MainPage] WebSocket 状态变化: $state');
      }
    };

    _realtimeService.startPolling(intervalSeconds: 5);
  }

  /// 8, 检查健康状态
  Future<void> _checkHealth() async {
    if (!mounted) return;

    final status = await _healthService.checkHealth();

    if (mounted) {
      setState(() {
        _serverHealthy = status.serverHealthy;
        _plcHealthy = status.plcHealthy;
        _dbHealthy = status.dbHealthy;
        _isHealthLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TechColors.bgDeep,
      body: Column(
        children: [
          // 顶部导航栏
          _buildTopBar(),
          // 主内容区
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Tab1: 实时数据
                _buildRealtimeContent(),
                // Tab2: 历史数据
                HistoryDataPage(key: _historyPageKey),
                // Tab3: 报警记录
                const AlarmLogPage(),
                // Tab4: 系统设置 - 传入共享的阈值配置Provider
                SettingsPage(thresholdProvider: _thresholdProvider),
                // Tab5: 设备状态 - 合并 DB1 和 DB3
                SensorStatusPage(key: _statusPageKey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildTopBar() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: TechColors.bgDark.withValues(alpha: 0.95),
          border: Border(
            bottom:
                BorderSide(color: TechColors.glowCyan.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: TechColors.glowCyan,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: TechColors.glowCyan.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // 标题
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [TechColors.glowCyan, TechColors.glowCyanLight],
              ).createShader(bounds),
              child: const Text(
                '水泵房监控系统',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Tab切换按钮
            _buildTabButtons(),
            const Spacer(),
            // 健康状态指示器
            HealthStatusBar(
              serverHealthy: _serverHealthy,
              plcHealthy: _plcHealthy,
              dbHealthy: _dbHealthy,
              serverLoading: _isHealthLoading,
              plcLoading: _isHealthLoading,
              dbLoading: _isHealthLoading,
              onRefresh: _checkHealth,
            ),
            const SizedBox(width: 12),
            // 时钟
            _buildClock(),
            const SizedBox(width: 12),
            // 窗口控制按钮
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
              _buildWindowButtons(),
          ],
        ),
      ),
    );
  }

  /// Tab切换按钮
  Widget _buildTabButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTabButton(0, '实时数据'),
        const SizedBox(width: 4),
        _buildTabButton(1, '历史数据'),
        const SizedBox(width: 4),
        _buildTabButton(2, '报警记录'),
        const SizedBox(width: 4),
        _buildTabButton(3, '系统设置'),
        const SizedBox(width: 4),
        _buildTabButton(4, '设备状态'),
      ],
    );
  }

  Widget _buildTabButton(int index, String label) {
    // 使用 _currentTabIndex 而不是 _tabController.index，避免未初始化错误
    final isSelected = _currentTabIndex == index;
    final color = isSelected ? TechColors.glowCyan : TechColors.textSecondary;

    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            _currentTabIndex = index;
            _tabController.animateTo(index);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? TechColors.glowCyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? TechColors.glowCyan.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 实时监控内容
  Widget _buildRealtimeContent() {
    // 获取水泵数据，如果没有数据则使用空数据
    final pumps =
        _realtimeData?.pumps ?? List.generate(6, (i) => PumpData.empty(i + 1));
    final pressure = _realtimeData?.pressure;
    final vibrations = _realtimeData?.vibrations ?? [];

    // 根据索引获取对应振动数据 (pump 1-6 对应 vib 0-5)
    VibrationData? getVib(int pumpIndex) {
      return pumpIndex < vibrations.length ? vibrations[pumpIndex] : null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          // 上半部分 - 3个水泵
          Expanded(
            child: TechPanel(
              accentColor: TechColors.glowCyan,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildPumpCardFromData(pumps.isNotEmpty ? pumps[0] : null,
                        pressure, getVib(0)),
                    const SizedBox(width: 4),
                    _buildPumpCardFromData(
                        pumps.length > 1 ? pumps[1] : null, null, getVib(1)),
                    const SizedBox(width: 4),
                    _buildPumpCardFromData(
                        pumps.length > 2 ? pumps[2] : null, null, getVib(2)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 下半部分 - 3个水泵
          Expanded(
            child: TechPanel(
              accentColor: TechColors.glowCyan,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildPumpCardFromData(
                        pumps.length > 3 ? pumps[3] : null, null, getVib(3)),
                    const SizedBox(width: 4),
                    _buildPumpCardFromData(
                        pumps.length > 4 ? pumps[4] : null, null, getVib(4)),
                    const SizedBox(width: 4),
                    _buildPumpCardFromData(
                        pumps.length > 5 ? pumps[5] : null, null, getVib(5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 从 PumpData 构建水泵卡片
  Widget _buildPumpCardFromData(PumpData? pump,
      [PressureData? pressure, VibrationData? vib]) {
    if (pump == null) {
      return const Expanded(
        child: CustomCardWidget(
          pumpNumber: '#?',
          pt: 0.0,
          impEp: 0.0,
          i0: 0.0,
          i1: 0.0,
          i2: 0.0,
          ua0: 0.0,
          ua1: 0.0,
          ua2: 0.0,
          isRunning: false,
          vibVelocityX: 0.0,
          vibVelocityY: 0.0,
          vibVelocityZ: 0.0,
          vibDisplacementX: 0.0,
          vibDisplacementY: 0.0,
          vibDisplacementZ: 0.0,
          vibFrequencyX: 0.0,
          vibFrequencyY: 0.0,
          vibFrequencyZ: 0.0,
        ),
      );
    }

    // 从 VibrationData 提取振动字段 (pump 5-6 无振动传感器，默认 0)
    final vibVx = vib?.vx ?? 0.0;
    final vibVy = vib?.vy ?? 0.0;
    final vibVz = vib?.vz ?? 0.0;
    final vibDx = vib?.dx ?? 0.0;
    final vibDy = vib?.dy ?? 0.0;
    final vibDz = vib?.dz ?? 0.0;
    final vibHzx = vib?.hzx ?? 0.0;
    final vibHzy = vib?.hzy ?? 0.0;
    final vibHzz = vib?.hzz ?? 0.0;

    // 根据阈值配置获取颜色
    final pumpIndex = pump.id;
    final powerColor = _thresholdProvider.getPtColor(pumpIndex, pump.pt);
    final currentColor = _thresholdProvider.getIColor(pumpIndex, pump.iAvg);
    final voltageColor = _thresholdProvider.getUaColor(pumpIndex, pump.uaAvg);
    // 振动速度的平均值（用于速度阈值判断）
    final avgVibVelocity = (vibVx + vibVy + vibVz) / 3;
    final speedColor =
        _thresholdProvider.getSpeedColor(pumpIndex, avgVibVelocity);
    // 振动位移的平均值
    final avgVibDisplacement = (vibDx + vibDy + vibDz) / 3;
    final displacementColor =
        _thresholdProvider.getDisplacementColor(pumpIndex, avgVibDisplacement);
    // 振动频率的平均值
    final avgVibFrequency = (vibHzx + vibHzy + vibHzz) / 3;
    final frequencyColor =
        _thresholdProvider.getFrequencyColor(pumpIndex, avgVibFrequency);
    // 振动速度颜色（用于振动阈值判断，与speedColor相同）
    final vibrationColor =
        _thresholdProvider.getVibrationColor(pumpIndex, avgVibVelocity);
    // 压力颜色
    final pressureColor = pressure != null
        ? _thresholdProvider.getPressureColor(pressure.value)
        : null;

    return Expanded(
      child: CustomCardWidget(
        pumpNumber: '#${pump.id}',
        pt: pump.pt,
        impEp: pump.impEp,
        i0: pump.i0,
        i1: pump.i1,
        i2: pump.i2,
        ua0: pump.ua0,
        ua1: pump.ua1,
        ua2: pump.ua2,
        isRunning: pump.isRunning,
        vibVelocityX: vibVx,
        vibVelocityY: vibVy,
        vibVelocityZ: vibVz,
        vibDisplacementX: vibDx,
        vibDisplacementY: vibDy,
        vibDisplacementZ: vibDz,
        vibFrequencyX: vibHzx,
        vibFrequencyY: vibHzy,
        vibFrequencyZ: vibHzz,
        pressure: pressure?.value, // 仅 #1 水泵传入压力
        // 阈值颜色
        powerColor: powerColor,
        currentColor: currentColor,
        voltageColor: voltageColor,
        speedColor: speedColor,
        displacementColor: displacementColor,
        frequencyColor: frequencyColor,
        vibrationColor: vibrationColor,
        pressureColor: pressureColor,
      ),
    );
  }

  /// 时钟显示 (使用Timer而非StreamBuilder，避免无法取消的Stream)
  Widget _buildClock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgMedium,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.glowCyan.withValues(alpha: 0.3)),
      ),
      child: Text(
        _clockTime.isEmpty ? '--:--:--' : _clockTime,
        style: const TextStyle(
          color: TechColors.glowCyan,
          fontSize: 13,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // 10, 窗口事件监听 (WindowListener)
  // ============================================================

  @override
  void onWindowRestore() {
    _tryRestoreFullScreenAfterMinimize();
  }

  @override
  void onWindowFocus() {
    _tryRestoreFullScreenAfterMinimize();
  }

  Future<void> _tryRestoreFullScreenAfterMinimize() async {
    if (!_restoreFullScreenAfterMinimize || !mounted) return;
    _restoreFullScreenAfterMinimize = false;
    try {
      await windowManager.setFullScreen(true);
    } catch (_) {
      // ignore
    }
  }

  /// 窗口控制按钮 (最小化 + 关闭)
  Widget _buildWindowButtons() {
    return Row(
      children: [
        // 最小化按钮
        _buildWindowButton(
          icon: Icons.remove,
          onTap: () async {
            // Windows 下全屏窗口无法直接最小化: 先退出全屏再最小化
            final isFullScreen = await windowManager.isFullScreen();
            if (isFullScreen) {
              _restoreFullScreenAfterMinimize = true;
              await windowManager.setFullScreen(false);
            }
            await windowManager.minimize();
          },
          hoverColor: TechColors.glowCyan,
        ),
        const SizedBox(width: 4),
        // 关闭按钮
        _buildWindowButton(
          icon: Icons.close,
          onTap: () => _showCloseDialog(),
          hoverColor: TechColors.statusAlarm,
        ),
      ],
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color hoverColor,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 28,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
          child: HoverBuilder(
            hoverColor: hoverColor,
            child: Icon(icon, size: 16, color: TechColors.textSecondary),
          ),
        ),
      ),
    );
  }

  /// 关闭确认对话框
  void _showCloseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TechColors.bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: TechColors.borderDark),
        ),
        title:
            const Text('确认退出', style: TextStyle(color: TechColors.textPrimary)),
        content: const Text('确定要关闭应用程序吗？',
            style: TextStyle(color: TechColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消',
                style: TextStyle(color: TechColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => windowManager.close(),
            style: ElevatedButton.styleFrom(
              backgroundColor: TechColors.statusAlarm.withValues(alpha: 0.2),
              foregroundColor: TechColors.statusAlarm,
            ),
            child: const Text('确认关闭'),
          ),
        ],
      ),
    );
  }
}

/// 悬停效果构建器
class HoverBuilder extends StatefulWidget {
  final Widget child;
  final Color hoverColor;

  const HoverBuilder({
    super.key,
    required this.child,
    required this.hoverColor,
  });

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.hoverColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: _isHovered
              ? Icon(
                  (widget.child as Icon).icon,
                  size: (widget.child as Icon).size,
                  color: widget.hoverColor,
                )
              : widget.child,
        ),
      ),
    );
  }
}
