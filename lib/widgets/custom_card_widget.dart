import 'package:flutter/material.dart';
import 'tech_line_widgets.dart';

/// ============================================================================
/// 自定义卡片组件 (Custom Card Widget)
/// ============================================================================
class CustomCardWidget extends StatelessWidget {
  final String pumpNumber;
  final String flowRate;
  final String pressure;
  final String power; // 功率
  final bool isRunning; // 水泵运行状态

  const CustomCardWidget({
    super.key,
    required this.pumpNumber,
    required this.flowRate,
    required this.pressure,
    required this.power,
    this.isRunning = true, // 默认运行中
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.borderDark,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 根据容器大小动态计算尺寸
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final fontSize = height * 0.04; // 字体大小为高度的4%
          final numberFontSize = height * 0.05; // 编号字体为高度的5%
          final dataFontSize = height * 0.055; // 数据字体为高度的5.5%
          final cardPadding = width * 0.02; // 卡片内边距为宽度的2%
          final topMargin = height * 0.025; // 顶部边距为高度的2.5%
          final indicatorSize = height * 0.035; // 指示灯大小为高度的3.5%
          final iconSize = height * 0.045; // 图标大小为高度的4.5%

          return Stack(
            children: [
              // 水泵图片（居中）
              Center(
                child: Image.asset(
                  'assets/images/waterpump.png',
                  fit: BoxFit.contain,
                ),
              ),
              // 左上角编号（带状态指示灯）
              Positioned(
                top: topMargin,
                left: topMargin,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: cardPadding * 1.5,
                    vertical: cardPadding * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: TechColors.glowCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: TechColors.glowCyan.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 状态指示灯
                      Container(
                        width: indicatorSize,
                        height: indicatorSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRunning
                              ? TechColors.statusNormal
                              : TechColors.statusOffline,
                          boxShadow: isRunning
                              ? [
                                  BoxShadow(
                                    color: TechColors.statusNormal
                                        .withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      SizedBox(width: cardPadding),
                      Text(
                        pumpNumber,
                        style: TextStyle(
                          color: TechColors.glowCyan,
                          fontSize: numberFontSize,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: TechColors.glowCyan.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 右上角数据卡片
              Positioned(
                top: topMargin,
                right: topMargin,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: cardPadding * 2,
                    vertical: cardPadding * 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: TechColors.bgDark.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: TechColors.borderDark,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TechColors.bgDeep.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 流量
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            color: TechColors.glowCyan,
                            size: iconSize,
                          ),
                          SizedBox(width: cardPadding * 0.5),
                          Text(
                            '流量: ',
                            style: TextStyle(
                              color: TechColors.textSecondary,
                              fontSize: fontSize,
                            ),
                          ),
                          Text(
                            flowRate,
                            style: TextStyle(
                              color: TechColors.glowCyan,
                              fontSize: dataFontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto Mono',
                              shadows: [
                                Shadow(
                                  color: TechColors.glowCyan.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: cardPadding * 0.5),
                          Text(
                            'm³/h',
                            style: TextStyle(
                              color: TechColors.textSecondary,
                              fontSize: fontSize,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: cardPadding),
                      // 压力
                      Row(
                        children: [
                          Icon(
                            Icons.speed,
                            color: TechColors.glowGreen,
                            size: iconSize,
                          ),
                          SizedBox(width: cardPadding * 0.5),
                          Text(
                            '压力: ',
                            style: TextStyle(
                              color: TechColors.textSecondary,
                              fontSize: fontSize,
                            ),
                          ),
                          Text(
                            pressure,
                            style: TextStyle(
                              color: TechColors.glowGreen,
                              fontSize: dataFontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto Mono',
                              shadows: [
                                Shadow(
                                  color: TechColors.glowGreen.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: cardPadding * 0.5),
                          Text(
                            'MPa',
                            style: TextStyle(
                              color: TechColors.textSecondary,
                              fontSize: fontSize,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: cardPadding),
                      // 功率
                      Row(
                        children: [
                          Icon(
                            Icons.electric_bolt,
                            color: TechColors.glowOrange,
                            size: iconSize,
                          ),
                          SizedBox(width: cardPadding * 0.5),
                          Text(
                            '功率: ',
                            style: TextStyle(
                              color: TechColors.textSecondary,
                              fontSize: fontSize,
                            ),
                          ),
                          Text(
                            power,
                            style: TextStyle(
                              color: TechColors.glowOrange,
                              fontSize: dataFontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto Mono',
                              shadows: [
                                Shadow(
                                  color: TechColors.glowOrange.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: cardPadding * 0.5),
                          Text(
                            'kW',
                            style: TextStyle(
                              color: TechColors.textSecondary,
                              fontSize: fontSize,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
