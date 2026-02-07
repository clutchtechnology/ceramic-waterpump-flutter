import 'package:flutter/material.dart';
import 'tech_line_widgets.dart';
import 'icons/icons.dart';

/// ============================================================================
/// 水泵卡片组件 (Pump Card Widget)
/// L形水泵图片 + 右上角两列数据标签 (2列4行 + #1水泵额外显示压力)
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
  final double voltageA; // A相电压 V
  final double voltageB; // B相电压 V
  final double voltageC; // C相电压 V

  // 振动参数
  final double vibVelocityX; // X轴速度 mm/s
  final double vibVelocityY; // Y轴速度 mm/s
  final double vibVelocityZ; // Z轴速度 mm/s
  final double vibDisplacementX; // X轴位移 μm
  final double vibDisplacementY; // Y轴位移 μm
  final double vibDisplacementZ; // Z轴位移 μm
  final double vibFrequencyX; // X轴频率 Hz
  final double vibFrequencyY; // Y轴频率 Hz
  final double vibFrequencyZ; // Z轴频率 Hz

  // 压力参数 (仅 #1 水泵显示)
  final double? pressure; // 压力 MPa

  // 颜色参数 (根据阈值配置)
  final Color? powerColor; // 功率颜色
  final Color? currentColor; // 电流颜色
  final Color? vibrationColor; // 振动颜色
  final Color? pressureColor; // 压力颜色

  const CustomCardWidget({
    super.key,
    required this.pumpNumber,
    this.isRunning = true,
    this.power = 0.0,
    this.energy = 0.0,
    this.currentA = 0.0,
    this.currentB = 0.0,
    this.currentC = 0.0,
    this.voltageA = 0.0,
    this.voltageB = 0.0,
    this.voltageC = 0.0,
    this.vibVelocityX = 0.0,
    this.vibVelocityY = 0.0,
    this.vibVelocityZ = 0.0,
    this.vibDisplacementX = 0.0,
    this.vibDisplacementY = 0.0,
    this.vibDisplacementZ = 0.0,
    this.vibFrequencyX = 0.0,
    this.vibFrequencyY = 0.0,
    this.vibFrequencyZ = 0.0,
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
          // 左上角：编号 + 状态指示灯
          Positioned(
            top: 8,
            left: 8,
            child: _buildStatusIndicator(),
          ),
          // 右上角：两个数据标签（左边电气参数，右边振动参数）
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左边标签：电气参数
                _buildElectricalDataCard(),
                const SizedBox(width: 4),
                // 右边标签：振动参数
                _buildVibrationDataCard(),
              ],
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
        SizedBox(width: 100, child: rightWidget),
      ],
    );
  }

  /// 左边标签：电气参数（8行，#1水泵为9行）
  Widget _buildElectricalDataCard() {
    return Container(
      width: 112 + 12,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: TechColors.bgDeep.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(
          color: TechColors.glowCyan.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPowerItem(),
          const SizedBox(height: 6),
          _buildEnergyItem(),
          const SizedBox(height: 6),
          _buildCurrentItem('A', currentA),
          const SizedBox(height: 6),
          _buildCurrentItem('B', currentB),
          const SizedBox(height: 6),
          _buildCurrentItem('C', currentC),
          const SizedBox(height: 6),
          _buildVoltageItem('A', voltageA),
          const SizedBox(height: 6),
          _buildVoltageItem('B', voltageB),
          const SizedBox(height: 6),
          _buildVoltageItem('C', voltageC),
          // 压力（仅 #1 水泵显示）
          if (pressure != null) ...[
            const SizedBox(height: 4),
            // 分割线
            Container(
              height: 1,
              color: TechColors.glowCyan.withOpacity(0.4),
            ),
            const SizedBox(height: 4),
            _buildPressureItem(),
          ],
        ],
      ),
    );
  }

  /// 右边标签：振动参数（9行）
  Widget _buildVibrationDataCard() {
    return Container(
      width: 112 + 12,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: TechColors.bgDeep.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(
          color: TechColors.glowCyan.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVibVelocityItem('X', vibVelocityX),
          const SizedBox(height: 6),
          _buildVibVelocityItem('Y', vibVelocityY),
          const SizedBox(height: 6),
          _buildVibVelocityItem('Z', vibVelocityZ),
          const SizedBox(height: 6),
          _buildVibDisplacementItem('X', vibDisplacementX),
          const SizedBox(height: 6),
          _buildVibDisplacementItem('Y', vibDisplacementY),
          const SizedBox(height: 6),
          _buildVibDisplacementItem('Z', vibDisplacementZ),
          const SizedBox(height: 6),
          _buildVibFrequencyItem('X', vibFrequencyX),
          const SizedBox(height: 6),
          _buildVibFrequencyItem('Y', vibFrequencyY),
          const SizedBox(height: 6),
          _buildVibFrequencyItem('Z', vibFrequencyZ),
        ],
      ),
    );
  }

  /// 左上角状态指示器：编号 + 状态灯 + 状态文字
  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgDeep.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.glowCyan.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pumpNumber,
            style: const TextStyle(
              color: TechColors.glowCyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning
                  ? TechColors.statusNormal
                  : TechColors.statusOffline,
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
            isRunning ? '运行' : '停止',
            style: TextStyle(
              color: isRunning
                  ? TechColors.statusNormal
                  : TechColors.statusOffline,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 功率数据项
  Widget _buildPowerItem() {
    final color = powerColor ?? TechColors.glowCyan;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PowerIcon(size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            power.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'kW',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 能耗数据项
  Widget _buildEnergyItem() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EnergyIcon(size: 15, color: TechColors.glowOrange),
          const SizedBox(width: 4),
          Text(
            energy.toStringAsFixed(0),
            style: const TextStyle(
              color: TechColors.glowOrange,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'kWh',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 电流数据项 - 格式：图标 + A: 数值 + 单位
  Widget _buildCurrentItem(String phase, double value) {
    final color = currentColor ?? TechColors.glowCyan;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrentIcon(size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            '$phase:',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'A',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 电压数据项 - 格式：图标 + A: 数值 + 单位
  Widget _buildVoltageItem(String phase, double value) {
    final color = powerColor ?? TechColors.glowCyan;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            '$phase:',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'V',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 振动速度数据项 - 格式：轴 + 数值 + 单位
  Widget _buildVibVelocityItem(String axis, double value) {
    final color = vibrationColor ?? TechColors.glowGreen;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vibration, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            '$axis:',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'mm/s',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// 振动位移数据项 - 格式：轴 + 数值 + 单位
  Widget _buildVibDisplacementItem(String axis, double value) {
    final color = vibrationColor ?? TechColors.glowGreen;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.straighten, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            '$axis:',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'μm',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// 振动频率数据项 - 格式：轴 + 数值 + 单位
  Widget _buildVibFrequencyItem(String axis, double value) {
    final color = vibrationColor ?? TechColors.glowGreen;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.graphic_eq, size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            '$axis:',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'Hz',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 压力数据项 (仅 #1 水泵显示)
  Widget _buildPressureItem() {
    final color = pressureColor ?? TechColors.glowOrange;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PressureIcon(size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            (pressure ?? 0.0).toStringAsFixed(3),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const SizedBox(width: 2),
          const Text(
            'MPa',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
