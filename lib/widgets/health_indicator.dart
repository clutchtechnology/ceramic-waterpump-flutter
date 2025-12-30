import 'package:flutter/material.dart';
import 'tech_line_widgets.dart';

/// 健康状态指示器组件
/// 用于显示服务、PLC、数据库的连接状态
class HealthIndicator extends StatelessWidget {
  final String label;
  final bool isHealthy;
  final bool isLoading;
  final VoidCallback? onTap;

  const HealthIndicator({
    super.key,
    required this.label,
    required this.isHealthy,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    if (isLoading) {
      statusColor = TechColors.statusWarning;
      statusIcon = Icons.sync;
    } else if (isHealthy) {
      statusColor = TechColors.statusNormal;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = TechColors.statusAlarm;
      statusIcon = Icons.error;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 状态图标
            isLoading
                ? SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  )
                : Icon(
                    statusIcon,
                    size: 12,
                    color: statusColor,
                  ),
            const SizedBox(width: 4),
            // 标签
            Text(
              label,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 健康状态栏组件
/// 显示服务、PLC、数据库三个健康状态指示器
class HealthStatusBar extends StatelessWidget {
  final bool serverHealthy;
  final bool plcHealthy;
  final bool dbHealthy;
  final bool serverLoading;
  final bool plcLoading;
  final bool dbLoading;
  final VoidCallback? onRefresh;

  const HealthStatusBar({
    super.key,
    this.serverHealthy = false,
    this.plcHealthy = false,
    this.dbHealthy = false,
    this.serverLoading = true,
    this.plcLoading = true,
    this.dbLoading = true,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HealthIndicator(
          label: '服务',
          isHealthy: serverHealthy,
          isLoading: serverLoading,
        ),
        const SizedBox(width: 6),
        HealthIndicator(
          label: 'PLC',
          isHealthy: plcHealthy,
          isLoading: plcLoading,
        ),
        const SizedBox(width: 6),
        HealthIndicator(
          label: '数据库',
          isHealthy: dbHealthy,
          isLoading: dbLoading,
        ),
        if (onRefresh != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: TechColors.glowCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.refresh,
                size: 14,
                color: TechColors.glowCyan,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
