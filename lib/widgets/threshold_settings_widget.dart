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
  int _selectedCategory =
      0; // 0: 电流, 1: 电压, 2: 水压, 3: 速度, 4: 位移, 5: 频率, 6: 运行判断

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算可用高度
        final availableHeight = constraints.maxHeight;
        final categoryHeight = 40.0;
        final actionButtonsHeight = 60.0;
        final spacing = 32.0;
        final contentHeight =
            availableHeight - categoryHeight - actionButtonsHeight - spacing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类别选择器
            _buildCategorySelector(),
            const SizedBox(height: 16),
            // 配置内容 - 使用固定高度而不是 Expanded
            SizedBox(
              height: contentHeight > 0 ? contentHeight : 300,
              child: SingleChildScrollView(
                child: _buildCategoryContent(),
              ),
            ),
            const SizedBox(height: 16),
            // 底部操作按钮
            _buildActionButtons(),
          ],
        );
      },
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
      {'icon': Icons.bolt, 'label': '电压阈值', 'color': TechColors.glowCyan},
      {'icon': Icons.water_drop, 'label': '水压阈值', 'color': TechColors.glowCyan},
      {'icon': Icons.speed, 'label': '速度阈值', 'color': TechColors.glowCyan},
      {'icon': Icons.straighten, 'label': '位移阈值', 'color': TechColors.glowCyan},
      {'icon': Icons.graphic_eq, 'label': '频率阈值', 'color': TechColors.glowCyan},
      {
        'icon': Icons.power_settings_new,
        'label': '运行判断',
        'color': TechColors.glowCyan
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
        return _buildIConfig();
      case 1:
        return _buildUaConfig();
      case 2:
        return _buildPressureConfig();
      case 3:
        return _buildSpeedConfig();
      case 4:
        return _buildDisplacementConfig();
      case 5:
        return _buildFrequencyConfig();
      case 6:
        return _buildRunningPowerConfig();
      default:
        return const SizedBox();
    }
  }

  /// 电流阈值配置
  Widget _buildIConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(6, (index) {
          final config = widget.provider.iConfigs[index];
          return _buildThresholdRow(
            label: config.displayName,
            normalMax: config.normalMax,
            warningMax: config.warningMax,
            unit: 'A',
            color: TechColors.glowCyan,
            onNormalChanged: (value) {
              widget.provider.updateIConfig(index, normalMax: value);
            },
            onWarningChanged: (value) {
              widget.provider.updateIConfig(index, warningMax: value);
            },
          );
        }),
      ],
    );
  }

  /// 电压阈值配置
  Widget _buildUaConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(6, (index) {
          final config = widget.provider.uaConfigs[index];
          return _buildThresholdRow(
            label: config.displayName,
            normalMax: config.normalMax,
            warningMax: config.warningMax,
            unit: 'V',
            color: TechColors.glowCyan,
            onNormalChanged: (value) {
              widget.provider.updateUaConfig(index, normalMax: value);
            },
            onWarningChanged: (value) {
              widget.provider.updateUaConfig(index, warningMax: value);
            },
          );
        }),
      ],
    );
  }

  /// 速度阈值配置
  Widget _buildSpeedConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(6, (index) {
          final config = widget.provider.speedConfigs[index];
          return _buildThresholdRow(
            label: config.displayName,
            normalMax: config.normalMax,
            warningMax: config.warningMax,
            unit: 'r/min',
            color: TechColors.glowCyan,
            onNormalChanged: (value) {
              widget.provider.updateSpeedConfig(index, normalMax: value);
            },
            onWarningChanged: (value) {
              widget.provider.updateSpeedConfig(index, warningMax: value);
            },
          );
        }),
      ],
    );
  }

  /// 位移阈值配置
  Widget _buildDisplacementConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(6, (index) {
          final config = widget.provider.displacementConfigs[index];
          return _buildThresholdRow(
            label: config.displayName,
            normalMax: config.normalMax,
            warningMax: config.warningMax,
            unit: 'mm',
            color: TechColors.glowCyan,
            onNormalChanged: (value) {
              widget.provider.updateDisplacementConfig(index, normalMax: value);
            },
            onWarningChanged: (value) {
              widget.provider
                  .updateDisplacementConfig(index, warningMax: value);
            },
          );
        }),
      ],
    );
  }

  /// 频率阈值配置
  Widget _buildFrequencyConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(6, (index) {
          final config = widget.provider.frequencyConfigs[index];
          return _buildThresholdRow(
            label: config.displayName,
            normalMax: config.normalMax,
            warningMax: config.warningMax,
            unit: 'Hz',
            color: TechColors.glowCyan,
            onNormalChanged: (value) {
              widget.provider.updateFrequencyConfig(index, normalMax: value);
            },
            onWarningChanged: (value) {
              widget.provider.updateFrequencyConfig(index, warningMax: value);
            },
          );
        }),
      ],
    );
  }

  /// 运行功率阈值配置
  /// 功率 >= 此阈值判定为"运行中"，否则为"停止"
  Widget _buildRunningPowerConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 说明信息
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: TechColors.glowCyan.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: TechColors.glowCyan.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: TechColors.glowCyan, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '当水泵功率 >= 设定阈值时判定为"运行中"，低于阈值判定为"停止"',
                  style: TextStyle(
                    color: TechColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(6, (index) {
          return _buildRunningPowerRow(
            label: '${index + 1}号泵',
            value: widget.provider.runningPowerThresholds[index],
            onChanged: (value) {
              setState(() {
                widget.provider.updateRunningPowerThreshold(index, value);
              });
            },
          );
        }),
      ],
    );
  }

  /// 运行功率阈值配置行 (单值)
  Widget _buildRunningPowerRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
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
                    color: TechColors.glowCyan,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        color: TechColors.textPrimary, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 运行阈值标识
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00ff88),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('运行功率阈值',
                  style:
                      TextStyle(color: TechColors.textSecondary, fontSize: 16)),
            ],
          ),
          const SizedBox(width: 8),
          // 输入框
          _buildNumberInput(
            value: value,
            onChanged: onChanged,
          ),
          const SizedBox(width: 8),
          const Text('kW',
              style: TextStyle(color: TechColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  /// 压力阈值配置
  Widget _buildPressureConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPressureThresholdRow(
          label: '高压报警',
          value: widget.provider.pressureHighAlarm,
          unit: 'MPa',
          color: TechColors.glowCyan,
          onChanged: (value) {
            widget.provider.updatePressureConfig(highAlarm: value);
          },
        ),
        _buildPressureThresholdRow(
          label: '低压报警',
          value: widget.provider.pressureLowAlarm,
          unit: 'MPa',
          color: TechColors.glowCyan,
          onChanged: (value) {
            widget.provider.updatePressureConfig(lowAlarm: value);
          },
        ),
      ],
    );
  }

  /// 压力阈值配置行（统一样式）
  Widget _buildPressureThresholdRow({
    required String label,
    required double value,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
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
                        color: TechColors.textPrimary, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 报警阈值标识
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
              const Text('报警阈值',
                  style:
                      TextStyle(color: TechColors.textSecondary, fontSize: 16)),
            ],
          ),
          const SizedBox(width: 8),
          // 输入框（使用Expanded动态适应）
          Expanded(
            child: _buildNumberInputDynamic(
              value: value,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          Text(unit,
              style: const TextStyle(
                  color: TechColors.textSecondary, fontSize: 16)),
        ],
      ),
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
                        color: TechColors.textPrimary, fontSize: 16),
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
                      TextStyle(color: TechColors.textSecondary, fontSize: 16)),
            ],
          ),
          const SizedBox(width: 8),
          _buildNumberInput(
            value: normalMax,
            onChanged: onNormalChanged,
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
                      TextStyle(color: TechColors.textSecondary, fontSize: 16)),
            ],
          ),
          const SizedBox(width: 8),
          _buildNumberInput(
            value: warningMax,
            onChanged: onWarningChanged,
          ),
          const SizedBox(width: 8),
          Text(unit,
              style: const TextStyle(
                  color: TechColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  /// 数字输入框（带增减按钮 - 固定宽度）
  Widget _buildNumberInput({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 减少按钮
        SizedBox(
          width: 44,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final newValue = value - 1;
                if (newValue >= 0) {
                  onChanged(newValue);
                }
              },
              borderRadius: BorderRadius.circular(2),
              child: Container(
                decoration: BoxDecoration(
                  color: TechColors.bgMedium,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: TechColors.borderDark),
                ),
                child: const Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: TechColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // 输入框
        SizedBox(
          width: 64,
          child: _NumberInputField(
            value: value,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        // 增加按钮
        SizedBox(
          width: 44,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final newValue = value + 1;
                onChanged(newValue);
              },
              borderRadius: BorderRadius.circular(2),
              child: Container(
                decoration: BoxDecoration(
                  color: TechColors.bgMedium,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: TechColors.borderDark),
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: TechColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 数字输入框（带增减按钮 - 动态宽度，用于压力配置）
  Widget _buildNumberInputDynamic({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        // 减少按钮
        SizedBox(
          width: 50,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final newValue = value - 1;
                if (newValue >= 0) {
                  onChanged(newValue);
                }
              },
              borderRadius: BorderRadius.circular(2),
              child: Container(
                decoration: BoxDecoration(
                  color: TechColors.bgMedium,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: TechColors.borderDark),
                ),
                child: const Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: TechColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 输入框（动态宽度）
        Expanded(
          child: _NumberInputField(
            value: value,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 6),
        // 增加按钮
        SizedBox(
          width: 50,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final newValue = value + 1;
                onChanged(newValue);
              },
              borderRadius: BorderRadius.circular(2),
              child: Container(
                decoration: BoxDecoration(
                  color: TechColors.bgMedium,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: TechColors.borderDark),
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: TechColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
        fontSize: 16,
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
