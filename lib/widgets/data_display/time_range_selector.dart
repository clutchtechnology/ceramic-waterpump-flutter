import 'package:flutter/material.dart';
import '../tech_line_widgets.dart';

/// 时间范围选择器组件
class TimeRangeSelector extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;
  final VoidCallback onStartTimeTap;
  final VoidCallback onEndTimeTap;
  final VoidCallback? onCancel;
  final Color accentColor;
  final bool compact;

  const TimeRangeSelector({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeTap,
    required this.onEndTimeTap,
    this.onCancel,
    this.accentColor = TechColors.glowOrange,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeButton(startTime, onStartTimeTap),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
          child: Text(
            '-',
            style: TextStyle(
              color: accentColor.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildTimeButton(endTime, onEndTimeTap),
        if (onCancel != null) ...[
          SizedBox(width: compact ? 3 : 6),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(Icons.refresh, size: 14, color: accentColor),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeButton(DateTime time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        ),
        child: Text(
          compact ? _formatDateTimeCompact(time) : _formatDateTime(time),
          style: TextStyle(
            color: accentColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto Mono',
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTimeCompact(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
