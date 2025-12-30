import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../widgets/tech_line_widgets.dart';
import '../widgets/data_display/tech_line_chart.dart';
import '../widgets/data_display/tech_bar_chart.dart';
import '../widgets/data_display/time_range_selector.dart';
import '../services/history_service.dart';
import '../providers/threshold_config_provider.dart';

/// 历史数据页面
/// 上部分：振动幅值和压力的柱状图 + 历史曲线
/// 下部分：电表能耗和功率的历史曲线
class HistoryDataPage extends StatefulWidget {
  const HistoryDataPage({super.key});

  @override
  State<HistoryDataPage> createState() => HistoryDataPageState();
}

/// 暴露给外部调用的刷新方法
class HistoryDataPageState extends State<HistoryDataPage>
    with AutomaticKeepAliveClientMixin, RouteAware {
  bool _isLoading = false;
  bool _isInitialized = false;

  // 历史数据服务
  final HistoryService _historyService = HistoryService();

  // 阈值配置Provider (从设置页面读取)
  final ThresholdConfigProvider _thresholdProvider = ThresholdConfigProvider();

  // 防抖定时器
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // ==================== 时间范围 ====================
  late DateTime _vibrationChartStartTime;
  late DateTime _vibrationChartEndTime;
  late DateTime _pressureChartStartTime;
  late DateTime _pressureChartEndTime;
  late DateTime _energyChartStartTime;
  late DateTime _energyChartEndTime;
  late DateTime _powerChartStartTime;
  late DateTime _powerChartEndTime;

  // ==================== 动态报警阈值 (从ThresholdConfigProvider获取) ====================
  // 这些值会在initState和页面显示时从Provider同步
  double _pressureHighAlarm = 1.0;
  double _pressureLowAlarm = 0.3;
  double _vibrationHighAlarm = 1.5;

  // ==================== 设备选择状态 ====================
  // 电表选择 (6个)
  final List<bool> _selectedMeters = List.generate(6, (_) => true);
  // 振动选择 (6个水泵)
  final List<bool> _selectedVibrations = List.generate(6, (_) => true);

  // ==================== 图表数据 ====================
  // 振动幅值数据 (6个水泵)
  final Map<int, List<FlSpot>> _vibrationData = {};
  // 压力数据 (仅1号水泵)
  final Map<int, List<FlSpot>> _pressureData = {};
  // 电表能耗数据 (6个)
  final Map<int, List<FlSpot>> _energyData = {};
  // 电表功率数据 (6个)
  final Map<int, List<FlSpot>> _powerData = {};

  // 颜色配置
  final List<Color> _meterColors = [
    TechColors.glowCyan, // 电表1
    TechColors.glowGreen, // 电表2
    TechColors.glowOrange, // 电表3
    const Color(0xFFff3b30), // 电表4
    const Color(0xFFaf52de), // 电表5
    const Color(0xFFffcc00), // 电表6
  ];

  final List<Color> _vibrationColors = [
    TechColors.glowCyan, // 水泵1
    TechColors.glowGreen, // 水泵2
    TechColors.glowOrange, // 水泵3
    const Color(0xFFff3b30), // 水泵4
    const Color(0xFFaf52de), // 水泵5
    const Color(0xFFffcc00), // 水泵6
  ];

  // 压力颜色 (仅1号)
  final List<Color> _pressureColors = [TechColors.glowCyan];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeTimeRanges();
    _loadThresholdConfig();
    _loadMockData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 页面可见时自动刷新数据
    if (!_isInitialized) {
      _isInitialized = true;
      _triggerAutoRefresh();
    }
  }

  /// 外部调用刷新方法 (进入页面时调用)
  void refreshData() {
    // 立即显示加载动画
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    // 直接调用刷新，不使用防抖
    _doRefreshAllCharts();
  }

  /// 触发自动刷新 (带防抖)
  void _triggerAutoRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _doRefreshAllCharts();
    });
  }

  /// 实际执行刷新所有图表数据 (最近1分钟)
  Future<void> _doRefreshAllCharts() async {
    // 设置加载状态
    if (mounted && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 同步阈值
      await _loadThresholdConfig();

      // 查询 5分钟前 到 4分钟前 的数据（避开批量写入延迟）
      // 后端每 150 秒（2.5 分钟）批量写入一次，查询最近数据可能还未入库
      final now = DateTime.now();
      final end = now.subtract(const Duration(minutes: 4));
      final start = now.subtract(const Duration(minutes: 5));

      if (mounted) {
        setState(() {
          _vibrationChartStartTime = start;
          _vibrationChartEndTime = end;
          _pressureChartStartTime = start;
          _pressureChartEndTime = end;
          _energyChartStartTime = start;
          _energyChartEndTime = end;
          _powerChartStartTime = start;
          _powerChartEndTime = end;
        });
      }

      // 并行加载所有数据
      await Future.wait([
        _refreshPressureData(),
        _refreshEnergyData(),
        _refreshPowerData(),
      ]);
    } catch (e) {
      debugPrint('刷新图表数据失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 保留旧方法名兼容
  Future<void> _refreshAllCharts() async {
    await _doRefreshAllCharts();
  }

  /// 加载阈值配置 (从Provider同步)
  Future<void> _loadThresholdConfig() async {
    await _thresholdProvider.loadConfig();
    _syncThresholds();
  }

  /// 同步阈值到本地变量
  void _syncThresholds() {
    if (mounted) {
      setState(() {
        _pressureHighAlarm = _thresholdProvider.pressureHighAlarm;
        _pressureLowAlarm = _thresholdProvider.pressureLowAlarm;
        // 振动阈值取第一个水泵的配置作为显示阈值
        if (_thresholdProvider.vibrationConfigs.isNotEmpty) {
          _vibrationHighAlarm =
              _thresholdProvider.vibrationConfigs[0].warningMax;
        }
      });
    }
  }

  /// 刷新压力数据
  Future<void> _refreshPressureData() async {
    try {
      // interval 不传，由 HistoryService 自动计算最佳聚合间隔
      final data = await _historyService.fetchPressureHistory(
        start: _pressureChartStartTime,
        end: _pressureChartEndTime,
      );

      if (data.isNotEmpty && mounted) {
        setState(() {
          _pressureData[0] = _convertToFlSpots(data);
        });
      }
    } catch (e) {
      debugPrint('加载压力历史数据失败: $e');
    }
  }

  /// 刷新能耗数据
  Future<void> _refreshEnergyData() async {
    try {
      // interval 不传，由 HistoryService 自动计算最佳聚合间隔
      final data = await _historyService.fetchEnergyHistory(
        start: _energyChartStartTime,
        end: _energyChartEndTime,
      );

      setState(() {
        for (final entry in data.entries) {
          final pumpIndex = entry.key - 1; // pump_id 1-6 -> index 0-5
          if (pumpIndex >= 0 && pumpIndex < 6) {
            _energyData[pumpIndex] = _convertToFlSpots(entry.value);
          }
        }
      });
    } catch (e) {
      debugPrint('加载能耗历史数据失败: $e');
    }
  }

  /// 刷新功率数据
  Future<void> _refreshPowerData() async {
    try {
      // interval 不传，由 HistoryService 自动计算最佳聚合间隔
      final data = await _historyService.fetchPowerHistory(
        start: _powerChartStartTime,
        end: _powerChartEndTime,
      );

      setState(() {
        for (final entry in data.entries) {
          final pumpIndex = entry.key - 1;
          if (pumpIndex >= 0 && pumpIndex < 6) {
            _powerData[pumpIndex] = _convertToFlSpots(entry.value);
          }
        }
      });
    } catch (e) {
      debugPrint('加载功率历史数据失败: $e');
    }
  }

  /// 转换历史数据点为FlSpot列表
  List<FlSpot> _convertToFlSpots(List<HistoryDataPoint> data) {
    if (data.isEmpty) return [];

    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  void _initializeTimeRanges() {
    final now = DateTime.now();
    final end = now.subtract(const Duration(seconds: 30));
    final start = end.subtract(const Duration(minutes: 5));

    _vibrationChartStartTime = start;
    _vibrationChartEndTime = end;
    _pressureChartStartTime = start;
    _pressureChartEndTime = end;
    _energyChartStartTime = start;
    _energyChartEndTime = end;
    _powerChartStartTime = start;
    _powerChartEndTime = end;
  }

  /// 加载模拟数据（后续替换为API调用）
  void _loadMockData() {
    // 生成模拟振动数据 (6个水泵)
    for (int i = 0; i < 6; i++) {
      _vibrationData[i] = List.generate(20, (j) {
        return FlSpot(j.toDouble(), 0.5 + (i * 0.1) + (j % 5) * 0.1);
      });
    }

    // 生成模拟压力数据 (仅1号)
    _pressureData[0] = List.generate(20, (j) {
      return FlSpot(j.toDouble(), 0.4 + (j % 5) * 0.15);
    });

    // 生成模拟能耗数据 (6个电表)
    for (int i = 0; i < 6; i++) {
      _energyData[i] = List.generate(20, (j) {
        return FlSpot(j.toDouble(), 100.0 + i * 50 + j * 5.0);
      });
    }

    // 生成模拟功率数据 (6个电表)
    for (int i = 0; i < 6; i++) {
      _powerData[i] = List.generate(20, (j) {
        return FlSpot(j.toDouble(), 30.0 + i * 10 + (j % 5) * 3.0);
      });
    }
  }

  String _getMeterLabel(int index) => '电表${index + 1}';
  String _getVibrationLabel(int index) => '水泵${index + 1}';
  String _getPressureLabel(int index) => '压力${index + 1}';

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return Container(
        color: TechColors.bgDeep,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: TechColors.glowCyan),
              SizedBox(height: 16),
              Text('加载历史数据...',
                  style: TextStyle(color: TechColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: TechColors.bgDeep,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 上部分：振动 + 压力 (50%高度)
          Expanded(
            flex: 5,
            child: Row(
              children: [
                // 左侧：振动幅值柱状图 + 历史曲线
                Expanded(
                  child: _buildVibrationSection(),
                ),
                const SizedBox(width: 8),
                // 右侧：压力柱状图 + 历史曲线
                Expanded(
                  child: _buildPressureSection(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 下部分：电表能耗 + 功率 (50%高度)
          Expanded(
            flex: 5,
            child: Row(
              children: [
                // 左侧：电表能耗历史曲线
                Expanded(
                  child: _buildEnergyChart(),
                ),
                const SizedBox(width: 8),
                // 右侧：电表功率历史曲线
                Expanded(
                  child: _buildPowerChart(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建振动幅值区域
  Widget _buildVibrationSection() {
    return TechPanel(
      accentColor: TechColors.glowOrange,
      child: Column(
        children: [
          // 标题栏 (无报警设置按钮)
          _buildSectionHeader(
            '振动幅值监测',
            TechColors.glowOrange,
          ),
          const SizedBox(height: 8),
          // 图表
          Expanded(
            child: TechBarChart(
              title: '振动幅值历史曲线',
              accentColor: TechColors.glowOrange,
              yAxisLabel: '振动(mm/s)',
              xAxisLabel: '数据点',
              xInterval: 5,
              dataMap: _vibrationData,
              selectedItems: _selectedVibrations,
              itemColors: _vibrationColors,
              itemCount: 6,
              getItemLabel: _getVibrationLabel,
              selectorLabel: '选择水泵',
              highAlarmThreshold: _vibrationHighAlarm,
              headerActions: [
                TimeRangeSelector(
                  startTime: _vibrationChartStartTime,
                  endTime: _vibrationChartEndTime,
                  onStartTimeTap: () => _selectChartStartTime('vibration'),
                  onEndTimeTap: () => _selectChartEndTime('vibration'),
                  onCancel: () => _refreshChartData('vibration'),
                  accentColor: TechColors.glowOrange,
                  compact: true,
                ),
              ],
              onItemToggle: (index) {
                setState(() {
                  _selectedVibrations[index] = !_selectedVibrations[index];
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建压力区域
  Widget _buildPressureSection() {
    return TechPanel(
      accentColor: TechColors.glowCyan,
      child: Column(
        children: [
          // 标题栏 (无设置按钮，阈值设置移至设置页面)
          _buildSectionHeader(
            '压力监测 (1号泵)',
            TechColors.glowCyan,
          ),
          const SizedBox(height: 8),
          // 图表
          Expanded(
            child: TechBarChart(
              title: '压力历史曲线',
              accentColor: TechColors.glowCyan,
              yAxisLabel: '压力(MPa)',
              xAxisLabel: '数据点',
              xInterval: 5,
              dataMap: _pressureData,
              selectedItems: const [true],
              itemColors: _pressureColors,
              itemCount: 1,
              getItemLabel: _getPressureLabel,
              selectorLabel: '压力',
              showSelector: false,
              highAlarmThreshold: _pressureHighAlarm,
              lowAlarmThreshold: _pressureLowAlarm,
              headerActions: [
                TimeRangeSelector(
                  startTime: _pressureChartStartTime,
                  endTime: _pressureChartEndTime,
                  onStartTimeTap: () => _selectChartStartTime('pressure'),
                  onEndTimeTap: () => _selectChartEndTime('pressure'),
                  onCancel: () => _refreshChartData('pressure'),
                  accentColor: TechColors.glowCyan,
                  compact: true,
                ),
              ],
              onItemToggle: (index) {},
            ),
          ),
        ],
      ),
    );
  }

  /// 构建电表能耗图表
  Widget _buildEnergyChart() {
    return TechPanel(
      accentColor: TechColors.glowGreen,
      child: TechLineChart(
        title: '电表能耗历史曲线',
        accentColor: TechColors.glowGreen,
        yAxisLabel: '能耗(kWh)',
        xAxisLabel: '数据点',
        xInterval: 5,
        dataMap: _energyData,
        selectedItems: _selectedMeters,
        itemColors: _meterColors,
        itemCount: 6,
        getItemLabel: _getMeterLabel,
        selectorLabel: '选择电表',
        headerActions: [
          TimeRangeSelector(
            startTime: _energyChartStartTime,
            endTime: _energyChartEndTime,
            onStartTimeTap: () => _selectChartStartTime('energy'),
            onEndTimeTap: () => _selectChartEndTime('energy'),
            onCancel: () => _refreshChartData('energy'),
            accentColor: TechColors.glowGreen,
            compact: true,
          ),
        ],
        onItemToggle: (index) {
          setState(() {
            _selectedMeters[index] = !_selectedMeters[index];
          });
        },
      ),
    );
  }

  /// 构建电表功率图表
  Widget _buildPowerChart() {
    return TechPanel(
      accentColor: TechColors.glowCyan,
      child: TechLineChart(
        title: '电表功率历史曲线',
        accentColor: TechColors.glowCyan,
        yAxisLabel: '功率(kW)',
        xAxisLabel: '数据点',
        xInterval: 5,
        dataMap: _powerData,
        selectedItems: _selectedMeters,
        itemColors: _meterColors,
        itemCount: 6,
        getItemLabel: _getMeterLabel,
        selectorLabel: '选择电表',
        headerActions: [
          TimeRangeSelector(
            startTime: _powerChartStartTime,
            endTime: _powerChartEndTime,
            onStartTimeTap: () => _selectChartStartTime('power'),
            onEndTimeTap: () => _selectChartEndTime('power'),
            onCancel: () => _refreshChartData('power'),
            accentColor: TechColors.glowCyan,
            compact: true,
          ),
        ],
        onItemToggle: (index) {
          setState(() {
            _selectedMeters[index] = !_selectedMeters[index];
          });
        },
      ),
    );
  }

  /// 构建区域标题栏
  Widget _buildSectionHeader(String title, Color color,
      {VoidCallback? onSettingsTap}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (onSettingsTap != null)
          GestureDetector(
            onTap: onSettingsTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.settings, size: 16, color: color),
            ),
          ),
      ],
    );
  }

  // ==================== 报警阈值设置对话框 ====================

  void _showVibrationAlarmDialog() {
    showDialog(
      context: context,
      builder: (context) => _AlarmSettingsDialog(
        title: '振动报警设置',
        accentColor: TechColors.glowOrange,
        highValue: _vibrationHighAlarm,
        highLabel: '高幅度报警 (mm/s)',
        onSave: (high, _) {
          setState(() {
            _vibrationHighAlarm = high;
          });
        },
      ),
    );
  }

  void _showPressureAlarmDialog() {
    showDialog(
      context: context,
      builder: (context) => _AlarmSettingsDialog(
        title: '压力报警设置',
        accentColor: TechColors.glowCyan,
        highValue: _pressureHighAlarm,
        lowValue: _pressureLowAlarm,
        highLabel: '高压报警 (MPa)',
        lowLabel: '低压报警 (MPa)',
        showLow: true,
        onSave: (high, low) {
          setState(() {
            _pressureHighAlarm = high;
            if (low != null) _pressureLowAlarm = low;
          });
        },
      ),
    );
  }

  // ==================== 时间选择方法 ====================

  Future<void> _selectChartStartTime(String chartType) async {
    final startTime = _getChartStartTime(chartType);
    final accentColor = _getChartAccentColor(chartType);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: startTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) => _buildDatePickerTheme(child, accentColor),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(startTime),
        builder: (context, child) => _buildTimePickerTheme(child, accentColor),
      );

      if (pickedTime != null) {
        setState(() {
          final newStart = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _setChartStartTime(chartType, newStart);
        });
        _refreshChartData(chartType);
      }
    }
  }

  Future<void> _selectChartEndTime(String chartType) async {
    final endTime = _getChartEndTime(chartType);
    final accentColor = _getChartAccentColor(chartType);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: endTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) => _buildDatePickerTheme(child, accentColor),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(endTime),
        builder: (context, child) => _buildTimePickerTheme(child, accentColor),
      );

      if (pickedTime != null) {
        setState(() {
          final newEnd = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _setChartEndTime(chartType, newEnd);
        });
        _refreshChartData(chartType);
      }
    }
  }

  Widget _buildDatePickerTheme(Widget? child, Color accentColor) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: accentColor),
      ),
      child: child!,
    );
  }

  Widget _buildTimePickerTheme(Widget? child, Color accentColor) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: accentColor),
      ),
      child: child!,
    );
  }

  Color _getChartAccentColor(String chartType) {
    switch (chartType) {
      case 'vibration':
        return TechColors.glowOrange;
      case 'pressure':
        return TechColors.glowCyan;
      case 'energy':
        return TechColors.glowGreen;
      case 'power':
        return TechColors.glowCyan;
      default:
        return TechColors.glowCyan;
    }
  }

  DateTime _getChartStartTime(String chartType) {
    switch (chartType) {
      case 'vibration':
        return _vibrationChartStartTime;
      case 'pressure':
        return _pressureChartStartTime;
      case 'energy':
        return _energyChartStartTime;
      case 'power':
        return _powerChartStartTime;
      default:
        return DateTime.now().subtract(const Duration(hours: 1));
    }
  }

  void _setChartStartTime(String chartType, DateTime time) {
    switch (chartType) {
      case 'vibration':
        _vibrationChartStartTime = time;
        break;
      case 'pressure':
        _pressureChartStartTime = time;
        break;
      case 'energy':
        _energyChartStartTime = time;
        break;
      case 'power':
        _powerChartStartTime = time;
        break;
    }
  }

  DateTime _getChartEndTime(String chartType) {
    switch (chartType) {
      case 'vibration':
        return _vibrationChartEndTime;
      case 'pressure':
        return _pressureChartEndTime;
      case 'energy':
        return _energyChartEndTime;
      case 'power':
        return _powerChartEndTime;
      default:
        return DateTime.now();
    }
  }

  void _setChartEndTime(String chartType, DateTime time) {
    switch (chartType) {
      case 'vibration':
        _vibrationChartEndTime = time;
        break;
      case 'pressure':
        _pressureChartEndTime = time;
        break;
      case 'energy':
        _energyChartEndTime = time;
        break;
      case 'power':
        _powerChartEndTime = time;
        break;
    }
  }

  void _refreshChartData(String chartType) {
    // 带防抖的刷新
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      debugPrint('刷新 $chartType 图表数据');

      // 同步阈值配置
      _syncThresholds();

      switch (chartType) {
        case 'vibration':
          // 振动数据暂时使用模拟数据
          break;
        case 'pressure':
          await _refreshPressureData();
          break;
        case 'energy':
          await _refreshEnergyData();
          break;
        case 'power':
          await _refreshPowerData();
          break;
      }
    });
  }
}

/// 报警阈值设置对话框
class _AlarmSettingsDialog extends StatefulWidget {
  final String title;
  final Color accentColor;
  final double highValue;
  final double? lowValue;
  final String highLabel;
  final String? lowLabel;
  final bool showLow;
  final void Function(double high, double? low) onSave;

  const _AlarmSettingsDialog({
    required this.title,
    required this.accentColor,
    required this.highValue,
    this.lowValue,
    required this.highLabel,
    this.lowLabel,
    this.showLow = false,
    required this.onSave,
  });

  @override
  State<_AlarmSettingsDialog> createState() => _AlarmSettingsDialogState();
}

class _AlarmSettingsDialogState extends State<_AlarmSettingsDialog> {
  late TextEditingController _highController;
  late TextEditingController _lowController;

  @override
  void initState() {
    super.initState();
    _highController = TextEditingController(text: widget.highValue.toString());
    _lowController =
        TextEditingController(text: widget.lowValue?.toString() ?? '');
  }

  @override
  void dispose() {
    _highController.dispose();
    _lowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: TechColors.bgDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: widget.accentColor.withOpacity(0.5)),
      ),
      title: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: widget.accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.title,
            style: TextStyle(color: widget.accentColor, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(
              widget.highLabel, _highController, TechColors.statusAlarm),
          if (widget.showLow) ...[
            const SizedBox(height: 16),
            _buildTextField(
                widget.lowLabel!, _lowController, TechColors.statusWarning),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消', style: TextStyle(color: TechColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final high =
                double.tryParse(_highController.text) ?? widget.highValue;
            final low = widget.showLow
                ? double.tryParse(_lowController.text) ?? widget.lowValue
                : null;
            widget.onSave(high, low);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentColor.withOpacity(0.2),
            foregroundColor: widget.accentColor,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: labelColor, fontSize: 12),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: TechColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: TechColors.bgMedium,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: labelColor),
            ),
          ),
        ),
      ],
    );
  }
}
