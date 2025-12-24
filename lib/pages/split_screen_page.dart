import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/tech_line_widgets.dart';
import '../widgets/custom_card_widget.dart';

/// 21寸横屏分屏页面
class SplitScreenPage extends StatefulWidget {
  const SplitScreenPage({super.key});

  @override
  State<SplitScreenPage> createState() => _SplitScreenPageState();
}

class _SplitScreenPageState extends State<SplitScreenPage> {
  @override
  void initState() {
    super.initState();
    // 强制横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 全屏模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // 恢复默认方向
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 21寸显示器尺寸 (16:9 横屏比例)
    const screenWidth = 1920.0;
    const screenHeight = 1080.0;

    return Scaffold(
      backgroundColor: TechColors.bgDeep,
      body: Center(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 上半部分 - 使用 TechPanel 科技风面板（无标题）
                Expanded(
                  child: TechPanel(
                    accentColor: TechColors.glowCyan,
                    child: Row(
                      children: [
                        // 第一列
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomCardWidget(
                              pumpNumber: '#1',
                              flowRate: '125.6',
                              pressure: '0.85',
                              power: '45.2',
                              isRunning: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 第二列
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomCardWidget(
                              pumpNumber: '#2',
                              flowRate: '142.3',
                              pressure: '0.92',
                              power: '52.8',
                              isRunning: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 第三列
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomCardWidget(
                              pumpNumber: '#3',
                              flowRate: '138.9',
                              pressure: '0.88',
                              power: '48.5',
                              isRunning: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 下半部分 - 使用 TechPanel 科技风面板（无标题）
                Expanded(
                  child: TechPanel(
                    accentColor: TechColors.glowCyan,
                    child: Row(
                      children: [
                        // 第一列
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomCardWidget(
                              pumpNumber: '#4',
                              flowRate: '115.2',
                              pressure: '0.78',
                              power: '41.3',
                              isRunning: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 第二列
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomCardWidget(
                              pumpNumber: '#5',
                              flowRate: '156.7',
                              pressure: '0.96',
                              power: '58.9',
                              isRunning: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 第三列
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomCardWidget(
                              pumpNumber: '#6',
                              flowRate: '149.5',
                              pressure: '0.91',
                              power: '54.6',
                              isRunning: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
