import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../widgets/tech_line_widgets.dart';
import '../widgets/custom_card_widget.dart';
import '../widgets/health_indicator.dart';
import '../services/health_service.dart';
import '../services/realtime_service.dart';
import '../models/pump_data.dart';
import '../providers/threshold_config_provider.dart';
import 'history_data_page.dart';
import 'settings_page.dart';
import 'alarm_log_page.dart';

/// 主页面 - 带Tab导航
/// Tab1: 实时监控 (水泵卡片)
/// Tab2: 历史数据 (图表)
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthService _healthService = HealthService();
  final RealtimeService _realtimeService = RealtimeService();

  // 阈值配置Provider
  final ThresholdConfigProvider _thresholdProvider = ThresholdConfigProvider();

  // HistoryDataPage 的 GlobalKey，用于调用刷新方法
  final GlobalKey<HistoryDataPageState> _historyPageKey = GlobalKey();

  // 健康状态
  bool _serverHealthy = false;
  bool _plcHealthy = false;
  bool _dbHealthy = false;
  bool _isHealthLoading = true;
  Timer? _healthCheckTimer;

  // 实时数据
  RealtimeBatchResponse? _realtimeData;
  String _dataSource = 'none'; // mock 或 plc

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged); // 监听tab切换
    _thresholdProvider.loadConfig(); // 加载阈值配置
    _thresholdProvider.addListener(_onThresholdChanged); // 监听阈值变化
    _startHealthCheck();
    _startRealtimePolling();
  }

  /// 阈值配置变化回调
  void _onThresholdChanged() {
    if (mounted) {
      setState(() {
        // 触发UI重建，更新颜色
      });
    }
  }

  /// Tab切换回调
  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      // 切换到历史数据页面时，触发刷新
      _historyPageKey.currentState?.refreshData();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _thresholdProvider.removeListener(_onThresholdChanged); // 移除阈值监听
    _tabController.dispose();
    _healthCheckTimer?.cancel();
    _healthService.dispose();
    _realtimeService.dispose();
    super.dispose();
  }

  /// 启动健康状态检查
  void _startHealthCheck() {
    _checkHealth();
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkHealth(),
    );
  }

  /// 启动实时数据轮询 (每6秒)
  void _startRealtimePolling() {
    _realtimeService.onDataUpdate = (data) {
      if (mounted) {
        setState(() {
          _realtimeData = data;
          _dataSource = data.source;
        });
      }
    };

    _realtimeService.onError = (error) {
      print('[MainPage] 实时数据错误: $error');
    };

    _realtimeService.startPolling(intervalSeconds: 5);
  }

  /// 检查健康状态
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
                // Tab1: 实时监控
                _buildRealtimeContent(),
                // Tab2: 历史数据
                HistoryDataPage(key: _historyPageKey),
                // Tab3: 系统设置 - 传入共享的阈值配置Provider
                SettingsPage(thresholdProvider: _thresholdProvider),
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
          color: TechColors.bgDark.withOpacity(0.95),
          border: Border(
            bottom: BorderSide(color: TechColors.glowCyan.withOpacity(0.3)),
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
                    color: TechColors.glowCyan.withOpacity(0.5),
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
            const SizedBox(width: 12),            // 报警日志按钮
            _buildAlarmButton(),
            const SizedBox(width: 12),            // 时钟
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
        _buildTabButton(0, '实时监控', Icons.monitor_heart),
        const SizedBox(width: 4),
        _buildTabButton(1, '历史数据', Icons.analytics),
        const SizedBox(width: 4),
        _buildTabButton(2, '系统设置', Icons.settings),
      ],
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _tabController.index == index;
    final color = isSelected ? TechColors.glowCyan : TechColors.textSecondary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? TechColors.glowCyan.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? TechColors.glowCyan.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
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
                    _buildPumpCardFromData(pumps.length > 0 ? pumps[0] : null,
                        pressure: pressure),
                    const SizedBox(width: 4),
                    _buildPumpCardFromData(pumps.length > 1 ? pumps[1] : null),
                    const SizedBox(width: 4),
                    _buildPumpCardFromData(pumps.length > 2 ? pumps[2] : null),
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
                    _buildPumpCardFromData(pumps.length > 3 ? pumps[3] : null),
                    const SizedBox(width: 4),
                    _buildPumpCardFromData(pumps.length > 4 ? pumps[4] : null),
                    const SizedBox(width: 4),
                    _buildPumpCardFromData(pumps.length > 5 ? pumps[5] : null),
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
  Widget _buildPumpCardFromData(PumpData? pump, {PressureData? pressure}) {
    if (pump == null) {
      return Expanded(
        child: CustomCardWidget(
          pumpNumber: '#?',
          power: 0.0,
          energy: 0.0,
          currentA: 0.0,
          currentB: 0.0,
          currentC: 0.0,
          isRunning: false,
          vibration: 0.0,
        ),
      );
    }

    // 根据阈值配置获取颜色
    final pumpIndex = pump.id;
    final powerColor = _thresholdProvider.getPowerColor(pumpIndex, pump.power);
    final currentColor =
        _thresholdProvider.getCurrentColor(pumpIndex, pump.current);
    final vibrationColor =
        _thresholdProvider.getVibrationColor(pumpIndex, 0.0); // 振动暂无数据
    final pressureColor = pressure != null
        ? _thresholdProvider.getPressureColor(pressure.value)
        : null;

    return Expanded(
      child: CustomCardWidget(
        pumpNumber: '#${pump.id}',
        power: pump.power,
        energy: 0.0, // API 暂无能耗数据
        currentA: pump.current,
        currentB: pump.current, // 暂用同一值
        currentC: pump.current, // 暂用同一值
        isRunning: pump.isRunning,
        vibration: 0.0, // 振动数据占位，暂不使用
        pressure: pressure?.value, // 仅1号泵显示压力
        // 阈值颜色
        powerColor: powerColor,
        currentColor: currentColor,
        vibrationColor: vibrationColor,
        pressureColor: pressureColor,
      ),
    );
  }

  /// 报警日志按钮
  Widget _buildAlarmButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AlarmLogPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: TechColors.bgMedium,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: TechColors.statusWarning.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: TechColors.statusWarning,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '报警日志',
              style: TextStyle(
                color: TechColors.statusWarning,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 时钟显示
  Widget _buildClock() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: TechColors.bgMedium,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: TechColors.glowCyan.withOpacity(0.3)),
          ),
          child: Text(
            timeStr,
            style: TextStyle(
              color: TechColors.glowCyan,
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  /// 窗口控制按钮
  Widget _buildWindowButtons() {
    return Row(
      children: [
        _buildWindowButton(
          icon: Icons.remove,
          onTap: () => windowManager.minimize(),
          hoverColor: TechColors.glowCyan,
        ),
        const SizedBox(width: 4),
        _buildWindowButton(
          icon: Icons.crop_square,
          onTap: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          hoverColor: TechColors.glowCyan,
        ),
        const SizedBox(width: 4),
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
          side: BorderSide(color: TechColors.borderDark),
        ),
        title: Text('确认退出', style: TextStyle(color: TechColors.textPrimary)),
        content: Text('确定要关闭应用程序吗？',
            style: TextStyle(color: TechColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                Text('取消', style: TextStyle(color: TechColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => windowManager.close(),
            style: ElevatedButton.styleFrom(
              backgroundColor: TechColors.statusAlarm.withOpacity(0.2),
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
              ? widget.hoverColor.withOpacity(0.2)
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
