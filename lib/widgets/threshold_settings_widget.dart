import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/threshold_config_provider.dart';
import '../widgets/tech_line_widgets.dart';

/// 阈值设置Widget
/// 用于在设置页面中配置报警阈值
class ThresholdSettingsWidget extends StatefulWidget {
  final ThresholdConfigProvider provider;

  const ThresholdSettingsWidget({
    super.key,
    required this.provider,
  });

  @override
  State<ThresholdSettingsWidget> createState() =>
      _ThresholdSettingsWidgetState();
}

class _ThresholdSettingsWidgetState extends State<ThresholdSettingsWidget> {
  // 当前选中的类别
  int _selectedCategory = 0; // 0: 电流, 1: 功率, 2: 压力, 3: 振动

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 类别选择器
        _buildCategorySelector(),
        const SizedBox(height: 16),
        // 配置内容
        Expanded(
          child: SingleChildScrollView(
            child: _buildCategoryContent(),
          ),
        ),
        // 底部操作按钮
        _buildActionButtons(),
      ],
    );
  }

  /// 类别选择器
  Widget _buildCategorySelector() {
    final categories = [
      {
        'icon': Icons.electrical_services,
        'label': '电流阈值',
        'color': TechColors.glowCyan
      },
      {'icon': Icons.power, 'label': '功率阈值', 'color': TechColors.glowGreen},
      {'icon': Icons.speed, 'label': '压力阈值', 'color': TechColors.glowOrange},
      {
        'icon': Icons.vibration,
        'label': '振动阈值',
        'color': const Color(0xFFaf52de)
      },
    ];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Row(
        children: List.generate(categories.length, (index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == index;
          final color = cat['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color:
                      isSelected ? color.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected
                      ? Border.all(color: color.withOpacity(0.5))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 16,
                      color: isSelected ? color : TechColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        color: isSelected ? color : TechColors.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 配置内容
  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 0:
        return _buildCurrentConfig();
      case 1:
        return _buildPowerConfig();
      case 2:
        return _buildPressureConfig();
      case 3:
        return _buildVibrationConfig();
      default:
        return const SizedBox();
    }
  }

  /// 电流阈值配置
  Widget _buildCurrentConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(
          '电流阈值配置',
          '设置各水泵电流的正常和警告上限，超过警告值将显示红色报警',
          TechColors.glowCyan,
        ),
        const SizedBox(height: 16),
        ...List.generate(6, (index) {
          final config = widget.provider.currentConfigs[index];
          return _buildThresholdRow(
            label: config.displayName,
            normalMax: config.normalMax,
            warningMax: config.warningMax,
            unit: 'A',
            color: TechColors.glowCyan,
            onNormalChanged: (value) {
              widget.provider.updateCurrentConfig(index, normalMax: value);
            },
            onWarningChanged: (value) {
              widget.provider.updateCurrentConfig(index, warningMax: value);
            },
          );
        }),
      ],
    );
  }

  /// 功率阈值配置
  Widget _buildPowerConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(
          '功率阈值配置',
          '设置各水泵功率的正常和警告上限，超过警告值将显示红色报警',
          TechColors.glowGreen,
        ),
        const SizedBox(height: 16),
        ...List.generate(6, (index) {
          final config = widget.provider.powerConfigs[index];
          return _buildThresholdRow(
            label: config.displayName,
            normalMax: config.normalMax,
            warningMax: config.warningMax,
            unit: 'kW',
            color: TechColors.glowGreen,
            onNormalChanged: (value) {
              widget.provider.updatePowerConfig(index, normalMax: value);
            },
            onWarningChanged: (value) {
              widget.provider.updatePowerConfig(index, warningMax: value);
            },
          );
        }),
      ],
    );
  }

  /// 压力阈值配置
  Widget _buildPressureConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(
          '压力阈值配置 (仅1号泵)',
          '设置压力的高低报警阈值，低于低限或高于高限将显示红色报警',
          TechColors.glowOrange,
        ),
        const SizedBox(height: 16),
        _buildPressureRow(),
      ],
    );
  }

  /// 压力配置行
  Widget _buildPressureRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Column(
        children: [
          // 高压报警
          Row(
            children: [
              SizedBox(
                width: 120,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ThresholdColors.alarm,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '高压报警',
                      style: TextStyle(
                          color: TechColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberInput(
                  value: widget.provider.pressureHighAlarm,
                  onChanged: (value) {
                    setState(() {
                      widget.provider.updatePressureConfig(highAlarm: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('MPa',
                  style:
                      TextStyle(color: TechColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          // 低压报警
          Row(
            children: [
              SizedBox(
                width: 120,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ThresholdColors.alarm,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '低压报警',
                      style: TextStyle(
                          color: TechColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberInput(
                  value: widget.provider.pressureLowAlarm,
                  onChanged: (value) {
                    setState(() {
                      widget.provider.updatePressureConfig(lowAlarm: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('MPa',
                  style:
                      TextStyle(color: TechColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          // 说明
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TechColors.glowOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: TechColors.glowOrange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: TechColors.glowOrange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '压力低于 ${widget.provider.pressureLowAlarm} MPa 或高于 ${widget.provider.pressureHighAlarm} MPa 时显示红色报警',
                    style:
                        TextStyle(color: TechColors.glowOrange, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 振动阈值配置
  Widget _buildVibrationConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(
          '振动阈值配置',
          '设置各水泵振动幅度的正常和警告上限，超过警告值将显示红色报警',
          const Color(0xFFaf52de),
        ),
        const SizedBox(height: 16),
        ...List.generate(6, (index) {
          final config = widget.provider.vibrationConfigs[index];
          return _buildThresholdRow(
            label: config.displayName,
            normalMax: config.normalMax,
            warningMax: config.warningMax,
            unit: 'mm/s',
            color: const Color(0xFFaf52de),
            onNormalChanged: (value) {
              widget.provider.updateVibrationConfig(index, normalMax: value);
            },
            onWarningChanged: (value) {
              widget.provider.updateVibrationConfig(index, warningMax: value);
            },
          );
        }),
      ],
    );
  }

  /// 信息横幅
  Widget _buildInfoBanner(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: TechColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          // 颜色说明
          Row(
            children: [
              _buildColorLegend('正常 (绿)', ThresholdColors.normal),
              const SizedBox(width: 16),
              _buildColorLegend('警告 (黄)', ThresholdColors.warning),
              const SizedBox(width: 16),
              _buildColorLegend('报警 (红)', ThresholdColors.alarm),
            ],
          ),
        ],
      ),
    );
  }

  /// 颜色图例
  Widget _buildColorLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(color: TechColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  /// 阈值配置行
  Widget _buildThresholdRow({
    required String label,
    required double normalMax,
    required double warningMax,
    required String unit,
    required Color color,
    required ValueChanged<double> onNormalChanged,
    required ValueChanged<double> onWarningChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Row(
        children: [
          // 标签
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        color: TechColors.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // 正常上限
          const SizedBox(width: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ThresholdColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('正常上限',
                  style:
                      TextStyle(color: TechColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: _buildNumberInput(
              value: normalMax,
              onChanged: onNormalChanged,
            ),
          ),
          // 警告上限
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ThresholdColors.alarm,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('警告上限',
                  style:
                      TextStyle(color: TechColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: _buildNumberInput(
              value: warningMax,
              onChanged: onWarningChanged,
            ),
          ),
          const SizedBox(width: 8),
          Text(unit,
              style: const TextStyle(
                  color: TechColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  /// 数字输入框
  Widget _buildNumberInput({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return _NumberInputField(
      value: value,
      onChanged: onChanged,
    );
  }

  /// 底部操作按钮
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: TechColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                widget.provider.resetToDefault();
              });
            },
            icon: const Icon(Icons.restore, size: 16),
            label: const Text('恢复默认'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TechColors.statusWarning,
              side:
                  BorderSide(color: TechColors.statusWarning.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final success = await widget.provider.saveConfig();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '阈值配置已保存' : '保存失败'),
                    backgroundColor:
                        success ? TechColors.glowGreen : TechColors.statusAlarm,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.save, size: 16),
            label: const Text('保存配置'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TechColors.glowCyan.withOpacity(0.2),
              foregroundColor: TechColors.glowCyan,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 独立的数字输入框 StatefulWidget
/// 解决 TextEditingController 在父组件 setState 时被重建的问题
class _NumberInputField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _NumberInputField({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<_NumberInputField> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_NumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有在非编辑状态下，且外部值变化时才更新
    if (!_isEditing && oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: const TextStyle(
        color: TechColors.textPrimary,
        fontSize: 12,
        fontFamily: 'Roboto Mono',
      ),
      textAlign: TextAlign.center,
      onTap: () {
        _isEditing = true;
      },
      onChanged: (text) {
        final newValue = double.tryParse(text);
        if (newValue != null) {
          widget.onChanged(newValue);
        }
      },
      onEditingComplete: () {
        _isEditing = false;
        FocusScope.of(context).unfocus();
      },
      onSubmitted: (_) {
        _isEditing = false;
      },
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: TechColors.bgDeep,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: TechColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: TechColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: TechColors.glowCyan),
        ),
      ),
    );
  }
}
