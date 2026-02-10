import 'package:flutter/material.dart';
import 'dart:async';
import '../models/sensor_status_model.dart';
import '../services/sensor_status_service.dart';
import '../services/websocket_service.dart';
import '../widgets/tech_line_widgets.dart';

/// 设备状态位显示页面
/// 显示 DB1 和 DB3 的模块状态（合并显示）
class SensorStatusPage extends StatefulWidget {
  const SensorStatusPage({
    super.key,
  });

  @override
  State<SensorStatusPage> createState() => SensorStatusPageState();
}

/// 暴露State类,方便外部控制Timer
class SensorStatusPageState extends State<SensorStatusPage> {
  // 1, 设备状态服务
  final SensorStatusService _statusService = SensorStatusService();

  // 2, WebSocket 服务 (用于监听连接状态)
  final WebSocketService _wsService = WebSocketService();

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
    // 2, 确保服务被释放
    _statusService.dispose();
    super.dispose();
  }

  /// 6, 暂停轮询 (Tab 切出时调用)
  void pausePolling() {
    _isPollingActive = false;
    _statusService.pausePolling();
  }

  /// 6, 恢复轮询 (Tab 切入时调用)
  void resumePolling() {
    _isPollingActive = true;
    _statusService.resumePolling();
    _fetchData(); // 立即刷新一次
  }

  Future<void> _initData() async {
    // 设置 WebSocket 回调
    _statusService.onDataUpdate = (data) {
      if (mounted && _isPollingActive) {
        print('[SensorStatusPage] 收到设备状态更新: ${data.summary?.total ?? 0} 个设备');
        setState(() {
          if (data.success) {
            _response = data;
            _errorMessage = null;
          } else {
            _errorMessage = data.error ?? '获取状态失败';
          }
        });
      }
    };

    _statusService.onError = (error) {
      if (mounted && _isPollingActive) {
        print('[SensorStatusPage] 错误: $error');
        setState(() {
          _errorMessage = error;
        });
      }
    };

    // 启动 WebSocket 订阅
    _statusService.startPolling();

    // 同时通过 HTTP 获取一次初始数据
    await _fetchData();
  }

  /// 3, 获取设备状态数据 (HTTP 手动刷新)
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: _errorMessage != null
          ? _buildErrorWidget()
          : Column(
              children: [
                // 上半部分 - DB1
                Expanded(
                  child: _buildDbCard('DB1', _response?.getStatusByDb('db1') ?? []),
                ),
                const SizedBox(height: 2),
                // 下半部分 - DB3
                Expanded(
                  child: _buildDbCard('DB3', _response?.getStatusByDb('db3') ?? []),
                ),
              ],
            ),
    );
  }

  /// DB 卡片（包含标题栏和状态网格）
  Widget _buildDbCard(String dbKey, List<DeviceStatus> statusList) {
    final summary = _response?.getSummaryByDb(dbKey.toLowerCase());
    final totalCount = summary?.total ?? statusList.length;
    final normalCount =
        summary?.normal ?? statusList.where((item) => item.isNormal).length;
    final errorCount =
        summary?.error ?? statusList.where((item) => !item.isNormal).length;

    return TechPanel(
      accentColor: TechColors.glowCyan,
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TechColors.bgDark.withOpacity(0.5),
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
                Text(
                  dbKey,
                  style: const TextStyle(
                    color: TechColors.glowCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto Mono',
                  ),
                ),
                const Spacer(),
                // 统计信息
                _buildStatChip('总计', totalCount, TechColors.glowCyan),
                const SizedBox(width: 8),
                _buildStatChip('正常', normalCount, TechColors.glowCyan),
                const SizedBox(width: 8),
                _buildStatChip('异常', errorCount, TechColors.glowRed),
              ],
            ),
          ),
          // 状态网格
          Expanded(
            child: statusList.isEmpty
                ? const Center(
                    child: Text(
                      '暂无数据',
                      style: TextStyle(
                        color: TechColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                : _buildStatusGrid(statusList),
          ),
        ],
      ),
    );
  }

  /// 统计标签
  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
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

  /// 状态网格（每行3列，每条高度40px）
  Widget _buildStatusGrid(List<DeviceStatus> statusList) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 1, 计算可用宽度（减去 padding）
        final availableWidth = constraints.maxWidth - 8;
        
        // 2, 计算每个项目的宽度（一行3列，减去间距）
        final itemWidth = (availableWidth - 8) / 3;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(4),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: statusList
                .map((status) => _buildStatusItem(status, itemWidth))
                .toList(),
          ),
        );
      },
    );
  }

  /// 单个状态项（固定高度40px，宽度由父组件传入）
  Widget _buildStatusItem(DeviceStatus status, double itemWidth) {
    final hasError = !status.isNormal;
    final accentColor = hasError ? TechColors.glowRed : TechColors.glowGreen;

    return Container(
      width: itemWidth,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasError
              ? TechColors.glowRed.withOpacity(0.4)
              : TechColors.borderDark.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 状态灯
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // 设备名称（优先显示 plcName，否则显示 deviceName）
          Expanded(
            child: Text(
              status.plcName ?? status.deviceName,
              style: const TextStyle(
                color: TechColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          // Error 值
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: status.error
                  ? TechColors.glowRed.withOpacity(0.2)
                  : TechColors.bgMedium.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              status.error ? '1' : '0',
              style: TextStyle(
                color: status.error ? TechColors.glowRed : TechColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Status 值
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: hasError
                  ? TechColors.glowRed.withOpacity(0.2)
                  : TechColors.bgMedium.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              status.statusHex,
              style: TextStyle(
                color: hasError ? TechColors.glowRed : TechColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }


}
