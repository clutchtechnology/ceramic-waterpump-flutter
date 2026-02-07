// 历史图表卡片组件 - 通用历史数据图表
// ============================================================
// 功能:
//   - 统一的图表卡片布局
//   - 标题 + 水泵选择 + 时间范围选择 + 刷新按钮
//   - 支持单水泵/多水泵数据展示
//   - 自动聚合查询
// ============================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'tech_line_widgets.dart';

/// 历史图表卡片
class HistoryChartCard extends StatelessWidget {
  /// 图表标题
  final String title;

  /// 主题色
  final Color accentColor;

  /// Y轴标签
  final String yAxisLabel;

  /// 是否显示水泵选择器
  final bool showPumpSelector;

  /// 当前选中的水泵 (1-6)
  final int selectedPump;

  /// 水泵选择回调
  final void Function(int?)? onPumpChanged;

  /// 开始时间
  final DateTime startTime;

  /// 结束时间
  final DateTime endTime;

  /// 时间选择回调
  final VoidCallback onStartTimeTap;
  final VoidCallback onEndTimeTap;

  /// 刷新回调
  final VoidCallback onRefresh;

  /// 图表数据 (x为索引, y为值)
  final List<FlSpot> data;

  /// 是否正在加载
  final bool isLoading;

  /// 高报警阈值 (可选)
  final double? highAlarmThreshold;

  /// 低报警阈值 (可选)
  final double? lowAlarmThreshold;

  const HistoryChartCard({
    super.key,
    required this.title,
    required this.accentColor,
    required this.yAxisLabel,
    this.showPumpSelector = true,
    required this.selectedPump,
    this.onPumpChanged,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeTap,
    required this.onEndTimeTap,
    required this.onRefresh,
    required this.data,
    this.isLoading = false,
    this.highAlarmThreshold,
    this.lowAlarmThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // 标题栏
          _buildHeader(),
          const SizedBox(height: 4),
          // 图表主体
          Expanded(
            child: isLoading
                ? _buildLoadingIndicator()
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader() {
    return Row(
      children: [
        // 标题
        Container(
          width: 2,
          height: 12,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 3),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: accentColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),

        // 水泵选择器
        if (showPumpSelector) ...[
          _buildPumpSelector(),
          const SizedBox(width: 8),
        ],

        // 时间范围选择
        _buildTimeSelector(),

        const SizedBox(width: 6),

        // 刷新按钮
        _buildRefreshButton(),
      ],
    );
  }

  /// 构建水泵选择器
  Widget _buildPumpSelector() {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: TechColors.bgMedium,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedPump,
          isDense: true,
          style: TextStyle(color: accentColor, fontSize: 10),
          dropdownColor: TechColors.bgDark,
          icon: Icon(Icons.arrow_drop_down, color: accentColor, size: 14),
          items: List.generate(6, (i) {
            final pumpId = i + 1;
            return DropdownMenuItem(
              value: pumpId,
              child: Text('泵$pumpId', style: const TextStyle(fontSize: 10)),
            );
          }),
          onChanged: (value) {
            if (value != null && onPumpChanged != null) {
              onPumpChanged!(value);
            }
          },
        ),
      ),
    );
  }

  /// 构建时间选择器
  Widget _buildTimeSelector() {
    final dateFormat = DateFormat('MM-dd');
    return Row(
      children: [
        _buildTimeButton(dateFormat.format(startTime), onStartTimeTap),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text('-', style: TextStyle(color: accentColor, fontSize: 10)),
        ),
        _buildTimeButton(dateFormat.format(endTime), onEndTimeTap),
      ],
    );
  }

  /// 构建时间按钮
  Widget _buildTimeButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: TechColors.bgMedium,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: accentColor, fontSize: 9),
          ),
        ),
      ),
    );
  }

  /// 构建刷新按钮
  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: onRefresh,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Icon(Icons.refresh, color: accentColor, size: 12),
      ),
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: accentColor,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '加载中...',
            style: TextStyle(color: accentColor.withOpacity(0.6), fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// 构建图表
  Widget _buildChart() {
    if (data.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: accentColor.withOpacity(0.4), fontSize: 12),
        ),
      );
    }

    // 计算Y轴范围
    final values = data.map((e) => e.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    final chartMinY = (minY - padding).clamp(0.0, double.infinity);
    final chartMaxY = maxY + padding;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 4),
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: accentColor,
              barWidth: 1.5,
              dotData: FlDotData(
                show: data.length <= 50,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 1.5,
                    color: accentColor,
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.2),
                    accentColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          // 高报警阈值线
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (highAlarmThreshold != null)
                HorizontalLine(
                  y: highAlarmThreshold!,
                  color: TechColors.statusAlarm.withOpacity(0.6),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: const TextStyle(
                      color: TechColors.statusAlarm,
                      fontSize: 8,
                    ),
                  ),
                ),
              if (lowAlarmThreshold != null)
                HorizontalLine(
                  y: lowAlarmThreshold!,
                  color: TechColors.statusWarning.withOpacity(0.6),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.bottomRight,
                    style: const TextStyle(
                      color: TechColors.statusWarning,
                      fontSize: 8,
                    ),
                  ),
                ),
            ],
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      color: TechColors.textSecondary,
                      fontSize: 8,
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  yAxisLabel,
                  style: TextStyle(color: accentColor, fontSize: 9),
                ),
              ),
              sideTitles: const SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                interval: data.length > 10 ? (data.length / 5).ceilToDouble() : 2,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: TechColors.textSecondary,
                        fontSize: 8,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (chartMaxY - chartMinY) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: TechColors.borderDark.withOpacity(0.3),
                strokeWidth: 0.5,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: TechColors.borderDark.withOpacity(0.2),
                strokeWidth: 0.5,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: accentColor.withOpacity(0.3), width: 0.5),
              bottom: BorderSide(color: accentColor.withOpacity(0.3), width: 0.5),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => TechColors.bgDark,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(2)} $yAxisLabel',
                    TextStyle(color: accentColor, fontSize: 9),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

