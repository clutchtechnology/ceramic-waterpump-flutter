// 历史数据页面 - 8宫格布局
// ============================================================
// 功能:
//   - 8个图表: 功率/能耗/电流/电压/压力/速度/位移/频率
//   - 每个图表独立查询和刷新
//   - 默认查询最近24小时数据
//   - 自动聚合间隔计算
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../widgets/tech_line_widgets.dart';
import '../widgets/history_chart_card.dart';
import '../services/history_service.dart';

/// 历史数据页面 - 8宫格布局
class HistoryDataPage extends StatefulWidget {
  const HistoryDataPage({super.key});

  @override
  State<HistoryDataPage> createState() => HistoryDataPageState();
}

class HistoryDataPageState extends State<HistoryDataPage> {
  // 历史数据服务
  final HistoryService _historyService = HistoryService();

  // 防抖定时器
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // [CRITICAL] 页面进入防抖：防止频繁切换 Tab 导致重复加载
  static const Duration _refreshDebounceInterval = Duration(seconds: 10);
  DateTime? _lastRefreshTime;

  // ==================== 8个图表的状态 ====================
  // 1. 功率
  int _powerSelectedPump = 1;
  late DateTime _powerStartTime;
  late DateTime _powerEndTime;
  List<FlSpot> _powerData = [];
  bool _powerLoading = false;

  // 2. 能耗
  int _energySelectedPump = 1;
  late DateTime _energyStartTime;
  late DateTime _energyEndTime;
  List<FlSpot> _energyData = [];
  bool _energyLoading = false;

  // 3. 电流 (三相)
  int _currentSelectedPump = 1;
  late DateTime _currentStartTime;
  late DateTime _currentEndTime;
  Map<String, List<FlSpot>> _currentData = {};
  bool _currentLoading = false;

  // 4. 电压 (三相)
  int _voltageSelectedPump = 1;
  late DateTime _voltageStartTime;
  late DateTime _voltageEndTime;
  Map<String, List<FlSpot>> _voltageData = {};
  bool _voltageLoading = false;

  // 5. 压力 (无水泵选择)
  late DateTime _pressureStartTime;
  late DateTime _pressureEndTime;
  List<FlSpot> _pressureData = [];
  bool _pressureLoading = false;

  // 6. 振动速度 (三轴)
  int _velocitySelectedVib = 1; // 改为振动传感器编号
  late DateTime _velocityStartTime;
  late DateTime _velocityEndTime;
  Map<String, List<FlSpot>> _velocityData = {};
  bool _velocityLoading = false;

  // 7. 振动位移 (三轴)
  int _displacementSelectedVib = 1; // 改为振动传感器编号
  late DateTime _displacementStartTime;
  late DateTime _displacementEndTime;
  Map<String, List<FlSpot>> _displacementData = {};
  bool _displacementLoading = false;

  // 8. 振动频率 (三轴)
  int _frequencySelectedVib = 1; // 改为振动传感器编号
  late DateTime _frequencyStartTime;
  late DateTime _frequencyEndTime;
  Map<String, List<FlSpot>> _frequencyData = {};
  bool _frequencyLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeTimeRanges();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 初始化所有图表的时间范围 (默认最近24小时)
  void _initializeTimeRanges() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));

    _powerStartTime = start;
    _powerEndTime = now;
    _energyStartTime = start;
    _energyEndTime = now;
    _currentStartTime = start;
    _currentEndTime = now;
    _voltageStartTime = start;
    _voltageEndTime = now;
    _pressureStartTime = start;
    _pressureEndTime = now;
    _velocityStartTime = start;
    _velocityEndTime = now;
    _displacementStartTime = start;
    _displacementEndTime = now;
    _frequencyStartTime = start;
    _frequencyEndTime = now;
  }

  /// 外部调用刷新方法 (进入页面时调用)
  void refreshData() {
    // [CRITICAL] 防抖：10秒内不重复刷新，防止频繁切换 Tab 导致重复加载
    final now = DateTime.now();
    final lastRefresh = _lastRefreshTime;
    if (lastRefresh != null &&
        now.difference(lastRefresh) < _refreshDebounceInterval) {
      debugPrint('HistoryDataPage: 刷新防抖，跳过本次刷新');
      return;
    }
    _lastRefreshTime = now;
    _refreshAllCharts();
  }

  /// 刷新所有图表数据
  Future<void> _refreshAllCharts() async {
    // [CRITICAL] 并发加载所有图表，但限制并发数为 4，防止同时发起 8 个 HTTP 请求导致卡死
    // 分 2 批加载：每批 4 个图表
    await Future.wait([
      _refreshPowerData(),
      _refreshEnergyData(),
      _refreshCurrentData(),
      _refreshVoltageData(),
    ]);

    await Future.wait([
      _refreshPressureData(),
      _refreshVelocityData(),
      _refreshDisplacementData(),
      _refreshFrequencyData(),
    ]);
  }

  /// 转换历史数据点为FlSpot列表
  List<FlSpot> _convertToFlSpots(List<HistoryDataPoint> data) {
    if (data.isEmpty) return [];
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  /// 转换三相/三轴历史数据为FlSpot Map
  Map<String, List<FlSpot>> _convertToMultiLineFlSpots(
      Map<String, List<HistoryDataPoint>> data) {
    final result = <String, List<FlSpot>>{};
    for (final entry in data.entries) {
      result[entry.key] = _convertToFlSpots(entry.value);
    }
    return result;
  }

  // ==================== 1. 功率数据刷新 ====================
  Future<void> _refreshPowerData() async {
    setState(() => _powerLoading = true);
    try {
      final response = await _historyService.fetchHistory(
        pumpId: _powerSelectedPump,
        parameter: 'Pt',
        start: _powerStartTime,
        end: _powerEndTime,
      );
      if (mounted) {
        setState(() {
          _powerData = _convertToFlSpots(response.data);
          _powerLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载功率数据失败: $e');
      if (mounted) setState(() => _powerLoading = false);
    }
  }

  // ==================== 2. 能耗数据刷新 ====================
  Future<void> _refreshEnergyData() async {
    setState(() => _energyLoading = true);
    try {
      final response = await _historyService.fetchHistory(
        pumpId: _energySelectedPump,
        parameter: 'ImpEp',
        start: _energyStartTime,
        end: _energyEndTime,
      );
      if (mounted) {
        setState(() {
          _energyData = _convertToFlSpots(response.data);
          _energyLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载能耗数据失败: $e');
      if (mounted) setState(() => _energyLoading = false);
    }
  }

  // ==================== 3. 电流数据刷新 (三相) ====================
  Future<void> _refreshCurrentData() async {
    setState(() => _currentLoading = true);
    try {
      final response = await _historyService.fetchThreePhaseCurrentHistory(
        pumpId: _currentSelectedPump,
        start: _currentStartTime,
        end: _currentEndTime,
      );
      if (mounted) {
        setState(() {
          _currentData = _convertToMultiLineFlSpots(response);
          _currentLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载电流数据失败: $e');
      if (mounted) setState(() => _currentLoading = false);
    }
  }

  // ==================== 4. 电压数据刷新 (三相) ====================
  Future<void> _refreshVoltageData() async {
    setState(() => _voltageLoading = true);
    try {
      final response = await _historyService.fetchThreePhaseVoltageHistory(
        pumpId: _voltageSelectedPump,
        start: _voltageStartTime,
        end: _voltageEndTime,
      );
      if (mounted) {
        setState(() {
          _voltageData = _convertToMultiLineFlSpots(response);
          _voltageLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载电压数据失败: $e');
      if (mounted) setState(() => _voltageLoading = false);
    }
  }

  // ==================== 5. 压力数据刷新 ====================
  Future<void> _refreshPressureData() async {
    setState(() => _pressureLoading = true);
    try {
      final data = await _historyService.fetchPressureHistory(
        start: _pressureStartTime,
        end: _pressureEndTime,
      );
      if (mounted) {
        setState(() {
          _pressureData = _convertToFlSpots(data);
          _pressureLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载压力数据失败: $e');
      if (mounted) setState(() => _pressureLoading = false);
    }
  }

  // ==================== 6. 振动速度数据刷新 (三轴) ====================
  Future<void> _refreshVelocityData() async {
    setState(() => _velocityLoading = true);
    try {
      final response = await _historyService.fetchThreeAxisVelocityHistory(
        vibId: _velocitySelectedVib, // 使用振动传感器编号 (1-6)
        start: _velocityStartTime,
        end: _velocityEndTime,
      );
      if (mounted) {
        setState(() {
          _velocityData = _convertToMultiLineFlSpots(response);
          _velocityLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载振动速度数据失败: $e');
      if (mounted) setState(() => _velocityLoading = false);
    }
  }

  // ==================== 7. 振动位移数据刷新 (三轴) ====================
  Future<void> _refreshDisplacementData() async {
    setState(() => _displacementLoading = true);
    try {
      final response = await _historyService.fetchThreeAxisDisplacementHistory(
        vibId: _displacementSelectedVib, // 使用振动传感器编号 (1-6)
        start: _displacementStartTime,
        end: _displacementEndTime,
      );
      if (mounted) {
        setState(() {
          _displacementData = _convertToMultiLineFlSpots(response);
          _displacementLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载振动位移数据失败: $e');
      if (mounted) setState(() => _displacementLoading = false);
    }
  }

  // ==================== 8. 振动频率数据刷新 (三轴) ====================
  Future<void> _refreshFrequencyData() async {
    setState(() => _frequencyLoading = true);
    try {
      final response = await _historyService.fetchThreeAxisFrequencyHistory(
        vibId: _frequencySelectedVib, // 使用振动传感器编号 (1-6)
        start: _frequencyStartTime,
        end: _frequencyEndTime,
      );
      if (mounted) {
        setState(() {
          _frequencyData = _convertToMultiLineFlSpots(response);
          _frequencyLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载振动频率数据失败: $e');
      if (mounted) setState(() => _frequencyLoading = false);
    }
  }

  // ==================== 时间选择方法 ====================

  /// [备用方案] 使用 Cupertino 风格的日期选择器（更稳定）
  Future<void> _selectStartTimeCupertino(String chartType) async {
    if (!mounted) return;

    final currentStart = _getStartTime(chartType);
    final accentColor = _getAccentColor(chartType);

    DateTime? selectedDate = currentStart;

    await showModalBottomSheet(
      context: context,
      backgroundColor: TechColors.bgDark,
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('取消', style: TextStyle(color: accentColor)),
                  ),
                  Text('选择开始时间',
                      style: TextStyle(color: accentColor, fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (mounted && selectedDate != null) {
                        setState(() {
                          _setStartTime(chartType, selectedDate!);
                        });
                        if (mounted) {
                          _refreshChart(chartType);
                        }
                      }
                    },
                    child: Text('确定', style: TextStyle(color: accentColor)),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: currentStart,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime.now(),
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectStartTime(String chartType) async {
    // [推荐] 直接使用 Cupertino 选择器，避免 Flutter 框架 bug
    _selectStartTimeCupertino(chartType);
  }

  /// [备用方案] 使用 Cupertino 风格的日期选择器（更稳定）
  Future<void> _selectEndTimeCupertino(String chartType) async {
    if (!mounted) return;

    final currentEnd = _getEndTime(chartType);
    final accentColor = _getAccentColor(chartType);

    DateTime? selectedDate = currentEnd;

    await showModalBottomSheet(
      context: context,
      backgroundColor: TechColors.bgDark,
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('取消', style: TextStyle(color: accentColor)),
                  ),
                  Text('选择结束时间',
                      style: TextStyle(color: accentColor, fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (mounted && selectedDate != null) {
                        setState(() {
                          _setEndTime(chartType, selectedDate!);
                        });
                        if (mounted) {
                          _refreshChart(chartType);
                        }
                      }
                    },
                    child: Text('确定', style: TextStyle(color: accentColor)),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: currentEnd,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime.now(),
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectEndTime(String chartType) async {
    // [推荐] 直接使用 Cupertino 选择器，避免 Flutter 框架 bug
    _selectEndTimeCupertino(chartType);
  }

  Widget _buildDatePickerTheme(Widget? child, Color accentColor) {
    // [FIX] 添加空值检查
    if (child == null) return const SizedBox.shrink();

    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: accentColor),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(80, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _buildTimePickerTheme(Widget? child, Color accentColor) {
    // [FIX] 添加空值检查
    if (child == null) return const SizedBox.shrink();

    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: accentColor),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(80, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
      child: child,
    );
  }

  DateTime _getStartTime(String chartType) {
    switch (chartType) {
      case 'power':
        return _powerStartTime;
      case 'energy':
        return _energyStartTime;
      case 'current':
        return _currentStartTime;
      case 'voltage':
        return _voltageStartTime;
      case 'pressure':
        return _pressureStartTime;
      case 'velocity':
        return _velocityStartTime;
      case 'displacement':
        return _displacementStartTime;
      case 'frequency':
        return _frequencyStartTime;
      default:
        return DateTime.now().subtract(const Duration(hours: 24));
    }
  }

  DateTime _getEndTime(String chartType) {
    switch (chartType) {
      case 'power':
        return _powerEndTime;
      case 'energy':
        return _energyEndTime;
      case 'current':
        return _currentEndTime;
      case 'voltage':
        return _voltageEndTime;
      case 'pressure':
        return _pressureEndTime;
      case 'velocity':
        return _velocityEndTime;
      case 'displacement':
        return _displacementEndTime;
      case 'frequency':
        return _frequencyEndTime;
      default:
        return DateTime.now();
    }
  }

  void _setStartTime(String chartType, DateTime time) {
    switch (chartType) {
      case 'power':
        _powerStartTime = time;
        break;
      case 'energy':
        _energyStartTime = time;
        break;
      case 'current':
        _currentStartTime = time;
        break;
      case 'voltage':
        _voltageStartTime = time;
        break;
      case 'pressure':
        _pressureStartTime = time;
        break;
      case 'velocity':
        _velocityStartTime = time;
        break;
      case 'displacement':
        _displacementStartTime = time;
        break;
      case 'frequency':
        _frequencyStartTime = time;
        break;
    }
  }

  void _setEndTime(String chartType, DateTime time) {
    switch (chartType) {
      case 'power':
        _powerEndTime = time;
        break;
      case 'energy':
        _energyEndTime = time;
        break;
      case 'current':
        _currentEndTime = time;
        break;
      case 'voltage':
        _voltageEndTime = time;
        break;
      case 'pressure':
        _pressureEndTime = time;
        break;
      case 'velocity':
        _velocityEndTime = time;
        break;
      case 'displacement':
        _displacementEndTime = time;
        break;
      case 'frequency':
        _frequencyEndTime = time;
        break;
    }
  }

  Color _getAccentColor(String chartType) {
    // 所有图表统一使用青色
    return TechColors.glowCyan;
  }

  void _refreshChart(String chartType) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      switch (chartType) {
        case 'power':
          _refreshPowerData();
          break;
        case 'energy':
          _refreshEnergyData();
          break;
        case 'current':
          _refreshCurrentData();
          break;
        case 'voltage':
          _refreshVoltageData();
          break;
        case 'pressure':
          _refreshPressureData();
          break;
        case 'velocity':
          _refreshVelocityData();
          break;
        case 'displacement':
          _refreshDisplacementData();
          break;
        case 'frequency':
          _refreshFrequencyData();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 第一行: 功率 | 能耗 | 电流 | 电压
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildPowerChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildEnergyChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildCurrentChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildVoltageChart()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 第二行: 压力 | 速度 | 位移 | 频率
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildPressureChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildVelocityChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildDisplacementChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildFrequencyChart()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 8个图表构建方法 ====================

  Widget _buildPowerChart() {
    return HistoryChartCard(
      title: '功率',
      accentColor: TechColors.glowCyan,
      yAxisLabel: 'kW',
      showPumpSelector: true,
      selectedPump: _powerSelectedPump,
      onPumpChanged: (pump) {
        if (pump != null) {
          setState(() => _powerSelectedPump = pump);
          _refreshPowerData();
        }
      },
      startTime: _powerStartTime,
      endTime: _powerEndTime,
      onStartTimeTap: () => _selectStartTime('power'),
      onEndTimeTap: () => _selectEndTime('power'),
      onRefresh: _refreshPowerData,
      data: _powerData,
      isLoading: _powerLoading,
    );
  }

  Widget _buildEnergyChart() {
    return HistoryChartCard(
      title: '能耗',
      accentColor: TechColors.glowCyan,
      yAxisLabel: 'kWh',
      showPumpSelector: true,
      selectedPump: _energySelectedPump,
      onPumpChanged: (pump) {
        if (pump != null) {
          setState(() => _energySelectedPump = pump);
          _refreshEnergyData();
        }
      },
      startTime: _energyStartTime,
      endTime: _energyEndTime,
      onStartTimeTap: () => _selectStartTime('energy'),
      onEndTimeTap: () => _selectEndTime('energy'),
      onRefresh: _refreshEnergyData,
      data: _energyData,
      isLoading: _energyLoading,
    );
  }

  Widget _buildCurrentChart() {
    return HistoryChartCard(
      title: '电流',
      accentColor: TechColors.glowCyan,
      yAxisLabel: 'A',
      showPumpSelector: true,
      selectedPump: _currentSelectedPump,
      onPumpChanged: (pump) {
        if (pump != null) {
          setState(() => _currentSelectedPump = pump);
          _refreshCurrentData();
        }
      },
      startTime: _currentStartTime,
      endTime: _currentEndTime,
      onStartTimeTap: () => _selectStartTime('current'),
      onEndTimeTap: () => _selectEndTime('current'),
      onRefresh: _refreshCurrentData,
      multiLineData: _currentData,
      isLoading: _currentLoading,
    );
  }

  Widget _buildVoltageChart() {
    return HistoryChartCard(
      title: '电压',
      accentColor: TechColors.glowCyan,
      yAxisLabel: 'V',
      showPumpSelector: true,
      selectedPump: _voltageSelectedPump,
      onPumpChanged: (pump) {
        if (pump != null) {
          setState(() => _voltageSelectedPump = pump);
          _refreshVoltageData();
        }
      },
      startTime: _voltageStartTime,
      endTime: _voltageEndTime,
      onStartTimeTap: () => _selectStartTime('voltage'),
      onEndTimeTap: () => _selectEndTime('voltage'),
      onRefresh: _refreshVoltageData,
      multiLineData: _voltageData,
      isLoading: _voltageLoading,
    );
  }

  Widget _buildPressureChart() {
    return HistoryChartCard(
      title: '压力',
      accentColor: TechColors.glowCyan,
      yAxisLabel: 'MPa',
      showPumpSelector: false,
      selectedPump: 1,
      startTime: _pressureStartTime,
      endTime: _pressureEndTime,
      onStartTimeTap: () => _selectStartTime('pressure'),
      onEndTimeTap: () => _selectEndTime('pressure'),
      onRefresh: _refreshPressureData,
      data: _pressureData,
      isLoading: _pressureLoading,
      highAlarmThreshold: 1.0,
      lowAlarmThreshold: 0.3,
    );
  }

  Widget _buildVelocityChart() {
    return HistoryChartCard(
      title: '速度',
      accentColor: TechColors.glowCyan,
      yAxisLabel: 'mm/s',
      showPumpSelector: true,
      selectedPump: _velocitySelectedVib,
      onPumpChanged: (vib) {
        if (vib != null) {
          setState(() => _velocitySelectedVib = vib);
          _refreshVelocityData();
        }
      },
      startTime: _velocityStartTime,
      endTime: _velocityEndTime,
      onStartTimeTap: () => _selectStartTime('velocity'),
      onEndTimeTap: () => _selectEndTime('velocity'),
      onRefresh: _refreshVelocityData,
      multiLineData: _velocityData,
      isLoading: _velocityLoading,
    );
  }

  Widget _buildDisplacementChart() {
    return HistoryChartCard(
      title: '位移',
      accentColor: TechColors.glowCyan,
      yAxisLabel: 'μm',
      showPumpSelector: true,
      selectedPump: _displacementSelectedVib,
      onPumpChanged: (vib) {
        if (vib != null) {
          setState(() => _displacementSelectedVib = vib);
          _refreshDisplacementData();
        }
      },
      startTime: _displacementStartTime,
      endTime: _displacementEndTime,
      onStartTimeTap: () => _selectStartTime('displacement'),
      onEndTimeTap: () => _selectEndTime('displacement'),
      onRefresh: _refreshDisplacementData,
      multiLineData: _displacementData,
      isLoading: _displacementLoading,
    );
  }

  Widget _buildFrequencyChart() {
    return HistoryChartCard(
      title: '频率',
      accentColor: TechColors.glowCyan,
      yAxisLabel: 'Hz',
      showPumpSelector: true,
      selectedPump: _frequencySelectedVib,
      onPumpChanged: (vib) {
        if (vib != null) {
          setState(() => _frequencySelectedVib = vib);
          _refreshFrequencyData();
        }
      },
      startTime: _frequencyStartTime,
      endTime: _frequencyEndTime,
      onStartTimeTap: () => _selectStartTime('frequency'),
      onEndTimeTap: () => _selectEndTime('frequency'),
      onRefresh: _refreshFrequencyData,
      multiLineData: _frequencyData,
      isLoading: _frequencyLoading,
    );
  }
}
