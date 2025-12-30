import 'package:flutter/material.dart';
import 'tech_line_widgets.dart';
import 'icons/icons.dart';

/// ============================================================================
/// 水泵卡片组件 (Pump Card Widget)
/// L形水泵图片 + 右上角两列数据标签
/// 支持根据阈值配置显示三色状态（绿色正常、黄色警告、红色报警）
/// ============================================================================
class CustomCardWidget extends StatelessWidget {
  final String pumpNumber;
  final bool isRunning;

  // 电气参数
  final double power; // 功率 kW
  final double energy; // 累计能耗 kWh
  final double currentA; // A相电流 A
  final double currentB; // B相电流 A
  final double currentC; // C相电流 A

  // 扩展参数
  final double vibration; // 振动幅值 mm/s (所有水泵都有)
  final double? pressure; // 压力 MPa (仅1号水泵有)

  // 颜色参数 (根据阈值配置)
  final Color? powerColor;     // 功率颜色
  final Color? currentColor;   // 电流颜色
  final Color? vibrationColor; // 振动颜色
  final Color? pressureColor;  // 压力颜色

  const CustomCardWidget({
    super.key,
    required this.pumpNumber,
    this.isRunning = true,
    this.power = 0.0,
    this.energy = 0.0,
    this.currentA = 0.0,
    this.currentB = 0.0,
    this.currentC = 0.0,
    this.vibration = 0.0,
    this.pressure,
    this.powerColor,
    this.currentColor,
    this.vibrationColor,
    this.pressureColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.borderDark,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // 水泵图片 - 放大并占据主要区域
          Positioned.fill(
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0),
              child: Image.asset(
                'assets/images/waterpump.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomLeft,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    color: TechColors.textSecondary.withOpacity(0.5),
                    size: 58,
                  );
                },
              ),
            ),
          ),
          // 右上角数据标签区域 - 两列
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: TechColors.bgDeep.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: TechColors.glowCyan.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第1行：编号+状态 | A相电流
                  _buildDataRow(
                    leftWidget: _buildStatusLabel(),
                    rightWidget: _buildCurrentItem('A', currentA),
                  ),
                  const SizedBox(height: 6),
                  // 第2行：功率 | B相电流
                  _buildDataRow(
                    leftWidget: _buildPowerItem(),
                    rightWidget: _buildCurrentItem('B', currentB),
                  ),
                  const SizedBox(height: 6),
                  // 第3行：能耗 | C相电流
                  _buildDataRow(
                    leftWidget: _buildEnergyItem(),
                    rightWidget: _buildCurrentItem('C', currentC),
                  ),
                  const SizedBox(height: 6),
                  // 第4行：振动幅值 | 压力(仅1号有)
                  _buildDataRow(
                    leftWidget: _buildVibrationItem(),
                    rightWidget: pressure != null
                        ? _buildPressureItem()
                        : const SizedBox(width: 90),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建两列数据行
  Widget _buildDataRow({
    required Widget leftWidget,
    required Widget rightWidget,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 100, child: leftWidget),
        const SizedBox(width: 10),
        SizedBox(width: 90, child: rightWidget),
      ],
    );
  }

  /// 状态标签：编号 + 状态灯 + 状态文字
  Widget _buildStatusLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isRunning ? TechColors.statusNormal : TechColors.statusOffline,
            boxShadow: [
              BoxShadow(
                color: isRunning
                    ? TechColors.statusNormal.withOpacity(0.6)
                    : TechColors.statusOffline.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          pumpNumber,
          style: const TextStyle(
            color: TechColors.glowCyan,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isRunning ? '运行' : '停止',
          style: TextStyle(
            color:
                isRunning ? TechColors.statusNormal : TechColors.statusOffline,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  /// 功率数据项
  Widget _buildPowerItem() {
    final color = powerColor ?? TechColors.glowCyan;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PowerIcon(size: 17, color: color),
        const SizedBox(width: 4),
        Text(
          power.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto Mono',
          ),
        ),
        const Text(
          'kW',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 能耗数据项
  Widget _buildEnergyItem() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EnergyIcon(size: 17, color: TechColors.glowOrange),
        const SizedBox(width: 4),
        Text(
          energy.toStringAsFixed(1),
          style: const TextStyle(
            color: TechColors.glowOrange,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto Mono',
          ),
        ),
        const Text(
          'kWh',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 振动幅值数据项
  Widget _buildVibrationItem() {
    final color = vibrationColor ?? TechColors.glowGreen;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.vibration, size: 17, color: color),
        const SizedBox(width: 4),
        Text(
          vibration.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto Mono',
          ),
        ),
        const Text(
          'mm/s',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 压力数据项 (仅1号水泵)
  Widget _buildPressureItem() {
    final color = pressureColor ?? TechColors.glowOrange;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PressureIcon(size: 17, color: color),
        const SizedBox(width: 4),
        Text(
          (pressure ?? 0.0).toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto Mono',
          ),
        ),
        const Text(
          'MPa',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 电流数据项 - 根据阈值显示颜色，格式：图标 + A: 数值 + 单位
  Widget _buildCurrentItem(String phase, double value) {
    final color = currentColor ?? TechColors.glowCyan;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CurrentIcon(size: 15, color: color),
        const SizedBox(width: 3),
        Text(
          '$phase: ',
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto Mono',
          ),
        ),
        const Text(
          'A',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
