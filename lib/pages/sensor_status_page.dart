import 'package:flutter/material.dart';
import 'dart:async';
import '../models/sensor_status_model.dart';
import '../services/sensor_status_service.dart';
import '../widgets/tech_line_widgets.dart';

/// 设备状态位显示页面
/// 显示 DB3 (DataState) 的模块状态
class SensorStatusPage extends StatefulWidget {
  const SensorStatusPage({super.key});

  @override
  State<SensorStatusPage> createState() => SensorStatusPageState();
}

/// 暴露State类,方便外部控制Timer
class SensorStatusPageState extends State<SensorStatusPage> {
  // 1, 设备状态服务
  final SensorStatusService _statusService = SensorStatusService();

  // 2, 轮询定时器
  Timer? _timer;

  // 3, 设备状态响应数据
  DeviceStatusResponse? _response;

  // 4, 刷新状态标记
  bool _isRefreshing = false;

  // 5, 错误信息
  String? _errorMessage;

  // 6, 轮询激活状态 (控制轮询是否激活)
  bool _isPollingActive = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    // 2, 确保定时器被取消
    _stopTimer();
    super.dispose();
  }

  /// 2, 停止定时器
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 2, 启动定时器 (每 5 秒轮询)
  void _startTimer() {
    _stopTimer(); // 2.1, 先停止旧的
    // 6, 检查轮询是否激活
    if (!_isPollingActive) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      // 6, 检查 mounted 和轮询状态
      if (!mounted || !_isPollingActive) {
        _stopTimer(); // 使用统一方法停止，保持 _timer 引用一致
        return;
      }
      try {
        await _fetchData();
      } catch (e) {
        // 5, 记录异常但不中断定时器
        debugPrint('状态位定时器回调异常: $e');
      }
    });
  }

  /// 6, 暂停轮询 (Tab 切出时调用)
  void pausePolling() {
    _isPollingActive = false;
    _stopTimer();
  }

  /// 6, 恢复轮询 (Tab 切入时调用)
  void resumePolling() {
    _isPollingActive = true;
    _startTimer();
    _fetchData(); // 立即刷新一次
  }

  Future<void> _initData() async {
    await _fetchData();
    _startTimer();
  }

  /// 3, 获取设备状态数据
  Future<void> _fetchData() async {
    // 4, 防止重复刷新
    if (_isRefreshing || !mounted) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final response = await _statusService.getDeviceStatus();

      if (mounted) {
        setState(() {
          if (response.success) {
            _response = response;
          } else {
            // 5, 设置错误信息
            _errorMessage = response.error ?? '获取状态失败';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '网络错误: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      child: Column(
        children: [
          // 顶部状态栏
          _buildHeader(),
          // 列表内容
          Expanded(
            child: _errorMessage != null
                ? _buildErrorWidget()
                : _buildStatusList(_response?.db3Status ?? []),
          ),
        ],
      ),
    );
  }

  /// 顶部状态栏
  Widget _buildHeader() {
    final summary = _response?.summary;
    final totalCount = summary?.total ?? 0;
    final normalCount = summary?.normal ?? 0;
    final errorCount = summary?.error ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        border: Border(
          bottom: BorderSide(
            color: TechColors.borderDark.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标题
          const Text(
            '设备状态位监控 (DB3)',
            style: TextStyle(
              color: TechColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Spacer(),
          // 统计信息
          _buildStatChip('总计', totalCount, TechColors.glowCyan),
          const SizedBox(width: 12),
          _buildStatChip('正常', normalCount, TechColors.glowGreen),
          const SizedBox(width: 12),
          _buildStatChip('异常', errorCount, TechColors.glowRed),
          const SizedBox(width: 16),
          // 数据源标签
          if (_response?.source != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TechColors.glowCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: TechColors.glowCyan.withOpacity(0.3)),
              ),
              child: Text(
                _response!.source!.toUpperCase(),
                style: const TextStyle(
                  color: TechColors.glowCyan,
                  fontSize: 10,
                  fontFamily: 'Roboto Mono',
                ),
              ),
            ),
          const SizedBox(width: 12),
          // 刷新按钮
          IconButton(
            onPressed: _isRefreshing ? null : _fetchData,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TechColors.glowCyan,
                    ),
                  )
                : const Icon(
                    Icons.refresh,
                    color: TechColors.glowCyan,
                    size: 20,
                  ),
          ),
        ],
      ),
    );
  }

  /// 统计标签
  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }

  /// 错误提示
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: TechColors.glowRed,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '未知错误',
            style: const TextStyle(
              color: TechColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: TechColors.glowCyan.withOpacity(0.2),
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 状态列表（单列紧凑布局，适合水泵房较少的设备）
  Widget _buildStatusList(List<DeviceStatus> statusList) {
    if (statusList.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: statusList.asMap().entries.map((entry) {
          return _buildStatusCard(entry.value, entry.key);
        }).toList(),
      ),
    );
  }

  /// 单个状态卡片
  Widget _buildStatusCard(DeviceStatus status, int index) {
    final hasError = !status.isNormal;
    final accentColor = hasError ? TechColors.glowRed : TechColors.glowGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TechColors.bgDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError
              ? TechColors.glowRed.withOpacity(0.4)
              : TechColors.borderDark.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: hasError
            ? [
                BoxShadow(
                  color: TechColors.glowRed.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // 序号
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: TechColors.bgMedium,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: TechColors.textSecondary,
                fontSize: 12,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 状态灯
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 设备名称
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.deviceName,
                  style: const TextStyle(
                    color: TechColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.deviceId,
                  style: const TextStyle(
                    color: TechColors.textSecondary,
                    fontSize: 10,
                    fontFamily: 'Roboto Mono',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Error 值
          _buildValueCell('Error', status.error, TechColors.glowRed),
          const SizedBox(width: 16),
          // Status 值
          _buildStatusCell(status.statusCode, status.statusHex),
          const SizedBox(width: 16),
          // 状态文字
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Text(
              status.isNormal ? '正常' : '异常',
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Error 值单元格
  Widget _buildValueCell(String label, bool value, Color activeColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: TechColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: value
                ? activeColor.withOpacity(0.2)
                : TechColors.bgMedium.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: value
                  ? activeColor.withOpacity(0.5)
                  : TechColors.borderDark.withOpacity(0.3),
            ),
          ),
          child: Text(
            value ? '1' : '0',
            style: TextStyle(
              color: value ? activeColor : TechColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ),
      ],
    );
  }

  /// Status 值单元格
  Widget _buildStatusCell(int statusCode, String statusHex) {
    final hasError = statusCode != 0;
    final color = hasError ? TechColors.glowRed : TechColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Status:',
          style: TextStyle(
            color: TechColors.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: hasError
                ? TechColors.glowRed.withOpacity(0.2)
                : TechColors.bgMedium.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: hasError
                  ? TechColors.glowRed.withOpacity(0.5)
                  : TechColors.borderDark.withOpacity(0.3),
            ),
          ),
          child: Text(
            statusHex,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ),
      ],
    );
  }
}
