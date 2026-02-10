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

  // 电气参数 (字段名与 InfluxDB 一致)
  final double pt; // 总有功功率 kW
  final double impEp; // 正向有功电能 kWh
  final double i0; // A相电流 A
  final double i1; // B相电流 A
  final double i2; // C相电流 A
  final double ua0; // A相电压 V
  final double ua1; // B相电压 V
  final double ua2; // C相电压 V

  // 振动参数
  final double vibVelocityX; // X轴速度 mm/s
  final double vibVelocityY; // Y轴速度 mm/s
  final double vibVelocityZ; // Z轴速度 mm/s
  final double vibDisplacementX; // X轴位移 um
  final double vibDisplacementY; // Y轴位移 um
  final double vibDisplacementZ; // Z轴位移 um
  final double vibFrequencyX; // X轴频率 Hz
  final double vibFrequencyY; // Y轴频率 Hz
  final double vibFrequencyZ; // Z轴频率 Hz

  // 压力参数 (仅 #1 水泵显示)
  final double? pressure; // 压力 kPa

  // 颜色参数 (根据阈值配置)
  final Color? powerColor; // 功率颜色
  final Color? currentColor; // 电流颜色
  final Color? voltageColor; // 电压颜色
  final Color? speedColor; // 速度颜色
  final Color? displacementColor; // 位移颜色
  final Color? frequencyColor; // 频率颜色
  final Color? vibrationColor; // 振动颜色
  final Color? pressureColor; // 压力颜色

  const CustomCardWidget({
    super.key,
    required this.pumpNumber,
    this.isRunning = true,
    this.pt = 0.0,
    this.impEp = 0.0,
    this.i0 = 0.0,
    this.i1 = 0.0,
    this.i2 = 0.0,
    this.ua0 = 0.0,
    this.ua1 = 0.0,
    this.ua2 = 0.0,
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
    this.voltageColor,
    this.speedColor,
    this.displacementColor,
    this.frequencyColor,
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
            top: 0,
            left: 0,
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
      width: 112 + 32,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
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
          _buildEnergyItem(),
          _buildCurrentItem('A', i0),
          _buildCurrentItem('B', i1),
          _buildCurrentItem('C', i2),
          _buildVoltageItem('A', ua0),
          _buildVoltageItem('B', ua1),
          _buildVoltageItem('C', ua2),
          // 压力（仅 #1 水泵显示）
          if (pressure != null) ...[
            const SizedBox(height: 2),
            // 分割线
            Container(
              height: 1,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: TechColors.glowCyan.withOpacity(0.5),
            ),
            const SizedBox(height: 2),
            _buildPressureItem(),
          ],
        ],
      ),
    );
  }

  /// 右边标签：振动参数（9行）
  Widget _buildVibrationDataCard() {
    return Container(
      width: 112 + 32,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
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
          _buildVibVelocityItem('Y', vibVelocityY),
          _buildVibVelocityItem('Z', vibVelocityZ),
          _buildVibDisplacementItem('X', vibDisplacementX),
          _buildVibDisplacementItem('Y', vibDisplacementY),
          _buildVibDisplacementItem('Z', vibDisplacementZ),
          _buildVibFrequencyItem('X', vibFrequencyX),
          _buildVibFrequencyItem('Y', vibFrequencyY),
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
          PowerIcon(size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            pt.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'kW',
            style: TextStyle(
              color: Colors.white,
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
          EnergyIcon(size: 18, color: TechColors.glowOrange),
          const SizedBox(width: 4),
          Text(
            impEp.toStringAsFixed(1),
            style: const TextStyle(
              color: TechColors.glowOrange,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'kWh',
            style: TextStyle(
              color: Colors.white,
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
          CurrentIcon(size: 18, color: color),
          const SizedBox(width: 3),
          Text(
            '$phase:',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 电压数据项 - 格式：图标 + A: 数值 + 单位
  Widget _buildVoltageItem(String phase, double value) {
    final color = voltageColor ?? TechColors.glowCyan;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 18, color: color),
          const SizedBox(width: 3),
          Text(
            '$phase:',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'V',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 振动速度数据项 - 格式：轴 + 数值 + 单位
  Widget _buildVibVelocityItem(String axis, double value) {
    final color = speedColor ?? TechColors.glowGreen;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vibration, size: 18, color: color),
          const SizedBox(width: 3),
          Text(
            '$axis:',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'mm/s',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// 振动位移数据项 - 格式：轴 + 数值 + 单位
  Widget _buildVibDisplacementItem(String axis, double value) {
    final color = displacementColor ?? TechColors.glowGreen;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.straighten, size: 18, color: color),
          const SizedBox(width: 3),
          Text(
            '$axis:',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'μm',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// 振动频率数据项 - 格式：轴 + 数值 + 单位
  Widget _buildVibFrequencyItem(String axis, double value) {
    final color = frequencyColor ?? TechColors.glowGreen;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.graphic_eq, size: 18, color: color),
          const SizedBox(width: 3),
          Text(
            '$axis:',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Text(
            'Hz',
            style: TextStyle(
              color: Colors.white,
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
          PressureIcon(size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            (pressure ?? 0.0).toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const SizedBox(width: 2),
          const Text(
            'kPa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
