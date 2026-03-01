import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../widgets/tech_line_widgets.dart';

// ============================================================
// 报警记录页面 - 六宫格布局
// ============================================================
// 6个分类: 电流报警/电压报警/压力报警/振动速度/振动位移/振动频率
// 顶部: 时间范围选择 + 查询全部 + 重置
// 每格: 标题 + 设备下拉框 + 查询按钮 + 数据表格
// ============================================================

// -- 宫格配置 --
class _GridConfig {
  final String title;
  final String paramPrefix;
  final Map<String, String> devices; // 显示名 -> suffix

  const _GridConfig({
    required this.title,
    required this.paramPrefix,
    required this.devices,
  });
}

// -- 设备显示名映射 --
const _deviceNameMap = <String, String>{
  'pump_1': '1#水泵',
  'pump_2': '2#水泵',
  'pump_3': '3#水泵',
  'pump_4': '4#水泵',
  'pump_5': '5#水泵',
  'pump_6': '6#水泵',
  'pressure': '压力表',
  'vib_1': '1#振动',
  'vib_2': '2#振动',
  'vib_3': '3#振动',
  'vib_4': '4#振动',
  'vib_5': '5#振动',
  'vib_6': '6#振动',
};

// -- 水泵设备下拉选项 --
const _pumpDevices = <String, String>{
  '全部': '',
  '1#水泵': '_pump_1',
  '2#水泵': '_pump_2',
  '3#水泵': '_pump_3',
  '4#水泵': '_pump_4',
  '5#水泵': '_pump_5',
  '6#水泵': '_pump_6',
};

// -- 振动设备下拉选项 --
const _vibDevices = <String, String>{
  '全部': '',
  '1#振动': '_vib_1',
  '2#振动': '_vib_2',
  '3#振动': '_vib_3',
  '4#振动': '_vib_4',
  '5#振动': '_vib_5',
  '6#振动': '_vib_6',
};

// -- 压力设备下拉选项 (只有高/低两种) --
const _pressureDevices = <String, String>{
  '全部': '',
  '高压报警': '_high',
  '低压报警': '_low',
};

// -- 6个宫格定义 --
const _gridConfigs = <_GridConfig>[
  _GridConfig(
    title: '电流报警',
    paramPrefix: 'pump_current',
    devices: _pumpDevices,
  ),
  _GridConfig(
    title: '电压报警',
    paramPrefix: 'pump_voltage',
    devices: _pumpDevices,
  ),
  _GridConfig(
    title: '压力报警',
    paramPrefix: 'pressure',
    devices: _pressureDevices,
  ),
  _GridConfig(
    title: '振动速度',
    paramPrefix: 'vib_speed',
    devices: _vibDevices,
  ),
  _GridConfig(
    title: '振动位移',
    paramPrefix: 'vib_displacement',
    devices: _vibDevices,
  ),
  _GridConfig(
    title: '振动频率',
    paramPrefix: 'vib_frequency',
    devices: _vibDevices,
  ),
];

class AlarmLogPage extends StatefulWidget {
  const AlarmLogPage({super.key});

  @override
  State<AlarmLogPage> createState() => AlarmLogPageState();
}

class AlarmLogPageState extends State<AlarmLogPage> {
  final AlarmService _alarmService = AlarmService();
  final DateFormat _dtFmt = DateFormat('MM-dd HH:mm:ss');
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  // 共享时间范围 (默认最近24小时)
  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _endTime = DateTime.now();

  // 每个宫格的状态
  final List<String> _selectedDeviceKeys = List.filled(6, '全部');
  final List<List<AlarmRecord>> _gridRecords = List.generate(6, (_) => []);
  final List<bool> _gridLoading = List.filled(6, false);

  // 每个宫格的滚动控制器
  final List<ScrollController> _scrollControllers =
      List.generate(6, (_) => ScrollController());

  // -- 供 main_page 调用 --
  void resumePolling() {}
  void pausePolling() {}

  @override
  void dispose() {
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // 时间选择
  // ============================================================

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: _endTime,
      builder: _darkThemeBuilder,
    );
    if (picked != null && mounted) {
      setState(() {
        _startTime = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: _startTime,
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: _darkThemeBuilder,
    );
    if (picked != null && mounted) {
      setState(() {
        _endTime = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Widget Function(BuildContext, Widget?) get _darkThemeBuilder =>
      (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: TechColors.glowCyan,
                onPrimary: TechColors.bgDeep,
                surface: TechColors.bgMedium,
                onSurface: TechColors.textPrimary,
              ),
            ),
            child: child!,
          );

  // ============================================================
  // 数据查询
  // ============================================================

  // 查询全部6个宫格
  Future<void> _queryAll() async {
    for (int i = 0; i < 6; i++) {
      _queryGrid(i);
    }
  }

  // 查询单个宫格
  Future<void> _queryGrid(int index) async {
    if (_gridLoading[index]) return;
    setState(() => _gridLoading[index] = true);

    final config = _gridConfigs[index];
    final deviceKey = _selectedDeviceKeys[index];
    final suffix = config.devices[deviceKey] ?? '';
    final paramPrefix = '${config.paramPrefix}$suffix';

    try {
      final records = await _alarmService.queryAlarms(
        start: _startTime,
        end: _endTime,
        paramPrefix: paramPrefix,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _gridRecords[index] = records;
          _gridLoading[index] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gridLoading[index] = false);
      }
    }
  }

  // 重置为最近24小时
  void _resetTimeRange() {
    setState(() {
      _startTime = DateTime.now().subtract(const Duration(hours: 24));
      _endTime = DateTime.now();
    });
  }

  // ============================================================
  // 设备名称辅助
  // ============================================================

  String _getDeviceLabel(AlarmRecord record) {
    return _deviceNameMap[record.deviceId] ?? record.deviceId;
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 顶部筛选栏
          _buildTopFilterBar(),
          const SizedBox(height: 10),
          // 六宫格 (3列 x 2行)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildGridCard(0)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridCard(1)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridCard(2)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildGridCard(3)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridCard(4)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridCard(5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- 顶部筛选栏 --
  Widget _buildTopFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TechColors.glowCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _buildDateButton(
            label: '开始',
            value: _dateFmt.format(_startTime),
            onTap: _pickStartDate,
          ),
          const SizedBox(width: 10),
          const Text('至',
              style: TextStyle(color: TechColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 10),
          _buildDateButton(
            label: '结束',
            value: _dateFmt.format(_endTime),
            onTap: _pickEndDate,
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            label: '查询',
            color: TechColors.glowCyan,
            onTap: _queryAll,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            label: '重置',
            color: TechColors.textSecondary,
            onTap: _resetTimeRange,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: TechColors.bgMedium,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: TechColors.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today,
                size: 14, color: TechColors.glowCyan),
            const SizedBox(width: 6),
            Text(
              '$label: $value',
              style:
                  const TextStyle(color: TechColors.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 单个宫格卡片
  // ============================================================

  Widget _buildGridCard(int index) {
    final config = _gridConfigs[index];
    final records = _gridRecords[index];
    final isLoading = _gridLoading[index];

    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TechColors.glowCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildGridHeader(index, config),
          Expanded(child: _buildGridTable(index, records, isLoading, config)),
        ],
      ),
    );
  }

  // -- 宫格头部 --
  Widget _buildGridHeader(int index, _GridConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TechColors.bgMedium,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        border: Border(
          bottom: BorderSide(color: TechColors.glowCyan.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Text(
            config.title,
            style: const TextStyle(
              color: TechColors.glowCyan,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          _buildDeviceDropdown(index, config),
          const Spacer(),
          _buildSmallButton(
            label: '查询',
            onTap: () => _queryGrid(index),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceDropdown(int index, _GridConfig config) {
    final keys = config.devices.keys.toList();

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: TechColors.bgDeep,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDeviceKeys[index],
          dropdownColor: TechColors.bgMedium,
          isDense: true,
          style: const TextStyle(
            color: TechColors.textPrimary,
            fontSize: 12,
          ),
          icon: const Icon(Icons.arrow_drop_down,
              color: TechColors.textSecondary, size: 16),
          items: keys.map((k) {
            return DropdownMenuItem(value: k, child: Text(k));
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedDeviceKeys[index] = v);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: TechColors.glowCyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: TechColors.glowCyan.withValues(alpha: 0.4)),
        ),
        child: const Text(
          '查询',
          style: TextStyle(
            color: TechColors.glowCyan,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 宫格内表格
  // ============================================================

  Widget _buildGridTable(int index, List<AlarmRecord> records, bool isLoading,
      _GridConfig config) {
    // 多设备 + 选择"全部"时才显示设备列
    final showDeviceCol =
        config.devices.length > 2 && _selectedDeviceKeys[index] == '全部';

    return Column(
      children: [
        _buildTableHeaderRow(showDeviceCol),
        Expanded(
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: TechColors.glowCyan,
                    ),
                  ),
                )
              : records.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无报警记录',
                        style: TextStyle(
                          color: TechColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: Scrollbar(
                        controller: _scrollControllers[index],
                        thumbVisibility: true,
                        thickness: 4,
                        radius: const Radius.circular(2),
                        child: ListView.builder(
                          controller: _scrollControllers[index],
                          itemCount: records.length,
                          padding: const EdgeInsets.only(right: 6),
                          itemBuilder: (context, i) {
                            return _buildRecordRow(
                                records[i], i, showDeviceCol);
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderRow(bool showDeviceCol) {
    const style = TextStyle(
      color: TechColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withValues(alpha: 0.5),
        border: Border(
          bottom:
              BorderSide(color: TechColors.borderDark.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          const Expanded(flex: 4, child: Text('时间', style: style)),
          if (showDeviceCol)
            const Expanded(flex: 2, child: Text('设备', style: style)),
          const Expanded(flex: 2, child: Text('实测值', style: style)),
          const Expanded(flex: 2, child: Text('阈值', style: style)),
        ],
      ),
    );
  }

  Widget _buildRecordRow(AlarmRecord record, int index, bool showDeviceCol) {
    final isEven = index % 2 == 0;
    final timeStr = DateTime.tryParse(record.time) != null
        ? _dtFmt.format(DateTime.parse(record.time).toLocal())
        : record.time;
    final valueStr =
        record.value != null ? record.value!.toStringAsFixed(1) : '-';
    final threshStr =
        record.threshold != null ? record.threshold!.toStringAsFixed(1) : '-';

    const rowTextStyle = TextStyle(
      color: TechColors.textPrimary,
      fontSize: 12,
      fontFamily: 'Roboto Mono',
    );

    return Container(
      color: isEven
          ? Colors.transparent
          : TechColors.bgMedium.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              timeStr,
              style: const TextStyle(
                color: TechColors.textSecondary,
                fontSize: 12,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ),
          if (showDeviceCol)
            Expanded(
              flex: 2,
              child: Text(_getDeviceLabel(record), style: rowTextStyle),
            ),
          Expanded(
            flex: 2,
            child: Text(
              valueStr,
              style: const TextStyle(
                color: TechColors.glowRed,
                fontSize: 12,
                fontFamily: 'Roboto Mono',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(threshStr, style: rowTextStyle),
          ),
        ],
      ),
    );
  }
}
