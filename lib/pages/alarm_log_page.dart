import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/tech_line_widgets.dart';
import '../services/alarm_service.dart';

/// 报警日志页面
class AlarmLogPage extends StatefulWidget {
  const AlarmLogPage({super.key});

  @override
  State<AlarmLogPage> createState() => _AlarmLogPageState();
}

class _AlarmLogPageState extends State<AlarmLogPage> {
  final AlarmService _alarmService = AlarmService();

  List<AlarmRecord> _alarms = [];
  AlarmCount? _alarmCount;
  bool _isLoading = true;
  String? _selectedLevel; // null=全部, warning, alarm
  int _queryHours = 24;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // 释放服务资源
    _alarmService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(hours: _queryHours));

      final results = await Future.wait([
        _alarmService.fetchAlarms(
          startTime: startTime,
          endTime: now,
          level: _selectedLevel,
          limit: 200,
        ),
        _alarmService.fetchAlarmCount(hours: _queryHours),
      ]);

      if (!mounted) return;
      setState(() {
        _alarms = results[0] as List<AlarmRecord>;
        _alarmCount = results[1] as AlarmCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[AlarmLogPage] 加载数据失败: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TechColors.bgDeep,
      appBar: AppBar(
        backgroundColor: TechColors.bgDark,
        title:
            const Text('报警日志', style: TextStyle(color: TechColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TechColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: TechColors.glowCyan),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部统计和筛选
          _buildHeader(),
          // 报警列表
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: TechColors.glowCyan),
                  )
                : _alarms.isEmpty
                    ? _buildEmptyState()
                    : _buildAlarmList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        border: Border(
          bottom: BorderSide(color: TechColors.borderDark),
        ),
      ),
      child: Column(
        children: [
          // 统计卡片
          Row(
            children: [
              _buildCountCard(
                  '报警', _alarmCount?.alarm ?? 0, TechColors.statusAlarm),
              const SizedBox(width: 12),
              _buildCountCard(
                  '警告', _alarmCount?.warning ?? 0, TechColors.statusWarning),
              const SizedBox(width: 12),
              _buildCountCard(
                  '总计', _alarmCount?.total ?? 0, TechColors.glowCyan),
            ],
          ),
          const SizedBox(height: 12),
          // 筛选按钮
          Row(
            children: [
              // 时间范围
              _buildTimeRangeSelector(),
              const SizedBox(width: 12),
              // 级别筛选
              _buildLevelFilter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: TechColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TechColors.bgMedium,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _queryHours,
          dropdownColor: TechColors.bgDark,
          style: TextStyle(color: TechColors.textPrimary, fontSize: 13),
          items: const [
            DropdownMenuItem(value: 1, child: Text('最近1小时')),
            DropdownMenuItem(value: 6, child: Text('最近6小时')),
            DropdownMenuItem(value: 24, child: Text('最近24小时')),
            DropdownMenuItem(value: 72, child: Text('最近3天')),
            DropdownMenuItem(value: 168, child: Text('最近7天')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _queryHours = value);
              _loadData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildLevelFilter() {
    return Row(
      children: [
        _buildFilterChip('全部', null),
        const SizedBox(width: 8),
        _buildFilterChip('报警', 'alarm', color: TechColors.statusAlarm),
        const SizedBox(width: 8),
        _buildFilterChip('警告', 'warning', color: TechColors.statusWarning),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? level, {Color? color}) {
    final isSelected = _selectedLevel == level;
    final chipColor = color ?? TechColors.glowCyan;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedLevel = level);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.2) : TechColors.bgMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? chipColor : TechColors.borderDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : TechColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: TechColors.statusNormal.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无报警记录',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '系统运行正常',
            style: TextStyle(
              color: TechColors.textSecondary.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _alarms.length,
      itemBuilder: (context, index) {
        final alarm = _alarms[index];
        return _buildAlarmItem(alarm);
      },
    );
  }

  Widget _buildAlarmItem(AlarmRecord alarm) {
    final isAlarm = alarm.isAlarm;
    final color = isAlarm ? TechColors.statusAlarm : TechColors.statusWarning;
    final dateFormat = DateFormat('MM-dd HH:mm:ss');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 级别图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAlarm ? Icons.error : Icons.warning,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        alarm.deviceDisplayName,
                        style: TextStyle(
                          color: TechColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isAlarm ? '报警' : '警告',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${alarm.paramDisplayName}: ${alarm.value.toStringAsFixed(2)} (阈值: ${alarm.threshold.toStringAsFixed(2)})',
                    style: TextStyle(
                      color: TechColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 时间
            Text(
              dateFormat.format(alarm.timestamp.toLocal()),
              style: TextStyle(
                color: TechColors.textSecondary.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
