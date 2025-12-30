import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../tech_line_widgets.dart';
import 'multi_select_dropdown.dart';

/// 可复用的技术风格柱状图组件（真正的柱状图）
/// 支持多选模式，带报警线
class TechBarChart extends StatelessWidget {
  final String title;
  final Color accentColor;
  final String yAxisLabel;
  final String xAxisLabel;
  final double? minY;
  final double? maxY;
  final double? yInterval;
  final double xInterval;
  final Map<int, List<FlSpot>> dataMap;
  final List<bool> selectedItems;
  final List<Color> itemColors;
  final int itemCount;
  final String Function(int index) getItemLabel;
  final String selectorLabel;
  final List<Widget>? headerActions;
  final void Function(int index) onItemToggle;
  final bool compact;
  final bool showSelector;

  /// 高报警阈值（红色虚线）
  final double? highAlarmThreshold;

  /// 低报警阈值（黄色虚线）
  final double? lowAlarmThreshold;

  const TechBarChart({
    super.key,
    required this.title,
    required this.accentColor,
    required this.yAxisLabel,
    required this.xAxisLabel,
    this.minY,
    this.maxY,
    this.yInterval,
    required this.xInterval,
    required this.dataMap,
    required this.selectedItems,
    required this.itemColors,
    required this.itemCount,
    required this.getItemLabel,
    required this.selectorLabel,
    this.headerActions,
    required this.onItemToggle,
    this.compact = false,
    this.showSelector = true,
    this.highAlarmThreshold,
    this.lowAlarmThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当showSelector为true时显示完整header，否则只显示headerActions
          if (showSelector) ...[
            _buildHeader(),
            SizedBox(height: compact ? 6 : 12),
          ] else if (headerActions != null && headerActions!.isNotEmpty) ...[
            _buildHeaderActionsOnly(),
            SizedBox(height: compact ? 6 : 12),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 4),
            child: Text(
              yAxisLabel,
              style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12),
            ),
          ),
          Expanded(child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MultiSelectDropdown(
                  label: selectorLabel,
                  itemCount: itemCount,
                  selectedItems: selectedItems,
                  itemColors: itemColors,
                  getItemLabel: getItemLabel,
                  accentColor: accentColor,
                  onItemToggle: onItemToggle,
                  compact: compact,
                ),
                if (headerActions != null) const SizedBox(width: 8),
                if (headerActions != null) ...headerActions!,
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 只显示headerActions（当showSelector为false时使用）
  Widget _buildHeaderActionsOnly() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (headerActions != null) ...headerActions!,
      ],
    );
  }

  ({double min, double max, double interval}) _calculateYAxisRange() {
    List<double> allYValues = [];

    for (int i = 0; i < itemCount; i++) {
      if (selectedItems[i] && dataMap.containsKey(i)) {
        allYValues.addAll(dataMap[i]!.map((spot) => spot.y));
      }
    }

    // 将报警阈值也纳入范围计算
    if (highAlarmThreshold != null) allYValues.add(highAlarmThreshold!);
    if (lowAlarmThreshold != null) allYValues.add(lowAlarmThreshold!);

    if (allYValues.isEmpty) {
      return (min: 0, max: 100, interval: 20);
    }

    double dataMin = allYValues.reduce((a, b) => a < b ? a : b);
    double dataMax = allYValues.reduce((a, b) => a > b ? a : b);

    double range = dataMax - dataMin;
    if (range < 0.01) range = dataMax * 0.2;
    if (range < 1) range = 10;

    double padding = range * 0.1;
    double calculatedMin = dataMin - padding;
    double calculatedMax = dataMax + padding;

    double rawInterval = range / 5;
    double magnitude = 1;
    while (rawInterval >= 10) {
      rawInterval /= 10;
      magnitude *= 10;
    }
    while (rawInterval < 1) {
      rawInterval *= 10;
      magnitude /= 10;
    }
    double niceInterval =
        (rawInterval <= 2 ? 2 : (rawInterval <= 5 ? 5 : 10)) * magnitude;

    calculatedMin = (calculatedMin / niceInterval).floor() * niceInterval;
    calculatedMax = (calculatedMax / niceInterval).ceil() * niceInterval;

    return (min: calculatedMin, max: calculatedMax, interval: niceInterval);
  }

  Widget _buildChart() {
    final yAxisRange = _calculateYAxisRange();
    final effectiveMinY = minY ?? yAxisRange.min;
    final effectiveMaxY = maxY ?? yAxisRange.max;
    final effectiveYInterval = yInterval ?? yAxisRange.interval;

    // 使用折线图来显示数据点+直线连接（与原app一致）
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                TechColors.bgMedium.withOpacity(0.9),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(1), // 保留1位小数
                  TextStyle(
                    color: itemColors[spot.barIndex % itemColors.length],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: effectiveYInterval,
          verticalInterval: xInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: TechColors.borderDark.withOpacity(0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: TechColors.borderDark.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: effectiveYInterval,
              getTitlesWidget: (value, meta) {
                if (value < effectiveMinY || value > effectiveMaxY) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
                  style:
                      const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 16,
              interval: xInterval,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(
                    color: TechColors.textSecondary, fontSize: 9),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: TechColors.borderDark.withOpacity(0.5)),
        ),
        lineBarsData: _getSelectedData(),
        extraLinesData: _buildAlarmLines(effectiveMinY, effectiveMaxY),
        minY: effectiveMinY,
        maxY: effectiveMaxY,
      ),
    );
  }

  /// 构建报警线
  ExtraLinesData _buildAlarmLines(double minY, double maxY) {
    List<HorizontalLine> horizontalLines = [];

    if (highAlarmThreshold != null &&
        highAlarmThreshold! >= minY &&
        highAlarmThreshold! <= maxY) {
      horizontalLines.add(
        HorizontalLine(
          y: highAlarmThreshold!,
          color: TechColors.statusAlarm.withOpacity(0.8),
          strokeWidth: 1.5,
          dashArray: [8, 4],
          label: HorizontalLineLabel(
            show: true,
            labelResolver: (line) =>
                '高报警 ${highAlarmThreshold!.toStringAsFixed(1)}',
            style: TextStyle(
              color: TechColors.statusAlarm,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (lowAlarmThreshold != null &&
        lowAlarmThreshold! >= minY &&
        lowAlarmThreshold! <= maxY) {
      horizontalLines.add(
        HorizontalLine(
          y: lowAlarmThreshold!,
          color: TechColors.statusWarning.withOpacity(0.8),
          strokeWidth: 1.5,
          dashArray: [8, 4],
          label: HorizontalLineLabel(
            show: true,
            labelResolver: (line) =>
                '低报警 ${lowAlarmThreshold!.toStringAsFixed(1)}',
            style: TextStyle(
              color: TechColors.statusWarning,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return ExtraLinesData(horizontalLines: horizontalLines);
  }

  List<LineChartBarData> _getSelectedData() {
    List<LineChartBarData> result = [];

    for (int i = 0; i < itemCount; i++) {
      if (selectedItems[i] && dataMap.containsKey(i)) {
        result.add(
          LineChartBarData(
            spots: dataMap[i]!,
            isCurved: false,
            color: itemColors[i],
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: itemColors[i],
                  strokeWidth: 1.5,
                  strokeColor: TechColors.bgDeep,
                );
              },
            ),
          ),
        );
      }
    }

    return result;
  }
}
