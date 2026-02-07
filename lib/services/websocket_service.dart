// WebSocket 连接服务 - 水泵房监控系统
// ============================================================
// 功能: 单例 WebSocket 连接管理，支持自动重连、心跳检测、消息分发
// 替代原有的 HTTP 轮询机制，实现实时数据推送
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../api/api.dart';
import '../models/pump_data.dart';
import '../models/sensor_status_model.dart';

// ============================================================
// 1, WebSocket 连接状态枚举
// ============================================================
enum WebSocketState {
  disconnected, // 未连接
  connecting, // 连接中
  connected, // 已连接
  reconnecting, // 重连中
}

// ============================================================
// 2, WebSocket 消息类型 (与后端协议对应)
// ============================================================
class WsMessageType {
  static const String realtimeData = 'realtime_data'; // 实时数据推送
  static const String deviceStatus = 'device_status'; // 设备状态推送
  static const String heartbeat = 'heartbeat'; // 心跳
  static const String subscribe = 'subscribe'; // 订阅消息
  static const String unsubscribe = 'unsubscribe'; // 取消订阅
  static const String error = 'error'; // 错误消息
}

// ============================================================
// 3, WebSocket 服务单例
// ============================================================
class WebSocketService {
  // ============================================================
  // 单例模式
  // ============================================================
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // ============================================================
  // 连接状态
  // ============================================================

  // 4, WebSocket 实例
  WebSocket? _socket;

  // 5, 当前连接状态
  WebSocketState _state = WebSocketState.disconnected;
  WebSocketState get state => _state;

  // 6, 是否已释放 (防止 dispose 后继续操作)
  bool _isDisposed = false;

  // 7, 重连定时器
  Timer? _reconnectTimer;

  // 8, 心跳定时器
  Timer? _heartbeatTimer;

  // 9, 重连次数计数
  int _reconnectAttempts = 0;

  // 10, 最大重连间隔 (秒)
  static const int _maxReconnectInterval = 30;

  // 11, 初始重连间隔 (秒)
  static const int _initialReconnectInterval = 1;

  // 12, 心跳间隔 (秒)
  static const int _heartbeatInterval = 15;

  // 13, WebSocket URL (可动态配置)
  String _wsUrl = Api.wsUrl;

  // 14, 消息接收计数器 (用于日志)
  int _messageReceivedCount = 0;
  DateTime? _lastMessageTime;

  // ============================================================
  // 回调函数
  // ============================================================

  // 14, 实时数据更新回调
  void Function(RealtimeBatchResponse)? onRealtimeDataUpdate;

  // 15, 设备状态更新回调
  void Function(DeviceStatusResponse)? onDeviceStatusUpdate;

  // 16, 连接状态变化回调
  void Function(WebSocketState)? onStateChanged;

  // 17, 错误回调
  void Function(String)? onError;

  // ============================================================
  // 公共方法
  // ============================================================

  /// 设置 WebSocket URL
  void setUrl(String url) {
    _wsUrl = url;
  }

  /// 获取当前 WebSocket URL
  String get wsUrl => _wsUrl;

  /// 18, 连接 WebSocket
  Future<void> connect() async {
    // 18.1, 防止重复连接和 dispose 后连接
    if (_isDisposed) return;
    if (_state == WebSocketState.connected ||
        _state == WebSocketState.connecting) {
      return;
    }

    _updateState(WebSocketState.connecting);

    try {
      // 18.2, 建立 WebSocket 连接
      _socket = await WebSocket.connect(_wsUrl).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('WebSocket 连接超时');
        },
      );

      // 18.3, 连接成功
      _reconnectAttempts = 0;
      _updateState(WebSocketState.connected);

      // 18.4, 启动心跳
      _startHeartbeat();

      // 18.5, 监听消息
      _socket!.listen(
        _onMessage,
        onError: _onSocketError,
        onDone: _onSocketDone,
        cancelOnError: false,
      );

      // 18.6, 发送初始订阅消息
      _sendSubscribe();
    } catch (e) {
      _logError('连接失败: $e');
      _updateState(WebSocketState.disconnected);
      _scheduleReconnect();
    }
  }

  /// 19, 断开连接 (手动断开，不触发重连)
  void disconnect() {
    _stopReconnectTimer();
    _stopHeartbeat();
    _closeSocket();
    _updateState(WebSocketState.disconnected);
  }

  /// 20, 发送消息到服务器
  void send(Map<String, dynamic> message) {
    if (_state != WebSocketState.connected || _socket == null) {
      _logError('发送失败: WebSocket 未连接');
      return;
    }

    try {
      _socket!.add(jsonEncode(message));
    } catch (e) {
      _logError('发送消息失败: $e');
    }
  }

  /// 21, 订阅实时数据
  void subscribeRealtime() {
    send({
      'type': WsMessageType.subscribe,
      'channel': 'realtime',
    });
  }

  /// 22, 订阅设备状态
  void subscribeDeviceStatus() {
    send({
      'type': WsMessageType.subscribe,
      'channel': 'device_status',
    });
  }

  /// 23, 取消订阅实时数据
  void unsubscribeRealtime() {
    send({
      'type': WsMessageType.unsubscribe,
      'channel': 'realtime',
    });
  }

  /// 24, 取消订阅设备状态
  void unsubscribeDeviceStatus() {
    send({
      'type': WsMessageType.unsubscribe,
      'channel': 'device_status',
    });
  }

  /// 25, 释放资源
  void dispose() {
    _isDisposed = true;
    disconnect();
    onRealtimeDataUpdate = null;
    onDeviceStatusUpdate = null;
    onStateChanged = null;
    onError = null;
  }

  /// 26, 重置状态 (用于重新初始化)
  void reset() {
    _isDisposed = false;
    _reconnectAttempts = 0;
  }

  // ============================================================
  // 私有方法
  // ============================================================

  /// 27, 处理接收到的消息
  void _onMessage(dynamic data) {
    if (_isDisposed) return;

    try {
      _messageReceivedCount++;
      final now = DateTime.now();
      final interval = _lastMessageTime != null 
          ? now.difference(_lastMessageTime!).inMilliseconds 
          : 0;
      _lastMessageTime = now;

      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String?;

      // 每 10 条消息打印一次日志
      if (_messageReceivedCount % 10 == 0) {
        print('[WebSocket] 收到第 $_messageReceivedCount 条消息 (类型: $type)，间隔: ${interval}ms');
      }

      switch (type) {
        case WsMessageType.realtimeData:
          _handleRealtimeData(message);
          break;
        case WsMessageType.deviceStatus:
          _handleDeviceStatus(message);
          break;
        case WsMessageType.heartbeat:
          // 心跳响应，无需处理
          break;
        case WsMessageType.error:
          final errorMsg = message['message'] as String? ?? '未知错误';
          onError?.call(errorMsg);
          break;
        default:
          _logError('未知消息类型: $type');
      }
    } catch (e) {
      _logError('消息解析失败: $e');
    }
  }

  /// 28, 处理实时数据
  void _handleRealtimeData(Map<String, dynamic> message) {
    try {
      // 28.1, 检查回调是否设置
      if (onRealtimeDataUpdate == null) {
        print('[WebSocket] 警告: onRealtimeDataUpdate 回调未设置！');
        return;
      }
      
      // 28.2, 从 message 中提取 data 字段，构造与 HTTP 响应兼容的格式
      final response = RealtimeBatchResponse.fromJson(message);
      
      // 28.3, 调用回调
      onRealtimeDataUpdate?.call(response);
    } catch (e, stackTrace) {
      // 强制打印错误，不受频率控制
      print('[WebSocket] 实时数据解析失败: $e');
      print('[WebSocket] 消息内容: $message');
      print('[WebSocket] 堆栈跟踪: $stackTrace');
    }
  }

  /// 29, 处理设备状态
  void _handleDeviceStatus(Map<String, dynamic> message) {
    try {
      final response = DeviceStatusResponse.fromJson(message);
      
      // 检查回调是否设置
      if (onDeviceStatusUpdate == null) {
        // device_status 回调未设置是正常的，不打印警告
        return;
      }
      
      onDeviceStatusUpdate?.call(response);
    } catch (e, stackTrace) {
      _logError('设备状态解析失败: $e');
      print('[WebSocket] 堆栈跟踪: $stackTrace');
    }
  }

  /// 30, WebSocket 错误回调
  void _onSocketError(dynamic error) {
    _logError('WebSocket 错误: $error');
    _handleDisconnect();
  }

  /// 31, WebSocket 关闭回调
  void _onSocketDone() {
    _handleDisconnect();
  }

  /// 32, 处理断开连接 (自动重连)
  void _handleDisconnect() {
    if (_isDisposed) return;

    _stopHeartbeat();
    _closeSocket();
    _updateState(WebSocketState.disconnected);
    _scheduleReconnect();
  }

  /// 33, 关闭 Socket 连接
  void _closeSocket() {
    try {
      _socket?.close();
    } catch (e) {
      // 忽略关闭时的错误
    }
    _socket = null;
  }

  /// 34, 安排重连 (指数退避策略)
  void _scheduleReconnect() {
    if (_isDisposed) return;
    _stopReconnectTimer();

    _updateState(WebSocketState.reconnecting);

    // 34.1, 计算重连间隔 (指数退避: 1s, 2s, 4s, 8s, ... 最大 30s)
    final interval = _calculateReconnectInterval();
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: interval), () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  /// 35, 计算重连间隔
  int _calculateReconnectInterval() {
    final interval = _initialReconnectInterval * (1 << _reconnectAttempts);
    return interval > _maxReconnectInterval ? _maxReconnectInterval : interval;
  }

  /// 36, 停止重连定时器
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 37, 启动心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: _heartbeatInterval),
      (_) {
        if (_state == WebSocketState.connected) {
          send({
            'type': WsMessageType.heartbeat,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      },
    );
  }

  /// 38, 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 39, 发送初始订阅
  void _sendSubscribe() {
    subscribeRealtime();
    subscribeDeviceStatus();
  }

  /// 40, 更新连接状态
  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChanged?.call(newState);
    }
  }

  /// 41, 日志输出 (频率控制)
  static int _errorCount = 0;
  void _logError(String message) {
    _errorCount++;
    // 前 3 次 + 每 10 次打印
    if (_errorCount <= 3 || _errorCount % 10 == 0) {
      // ignore: avoid_print
      print('[WebSocket] $_errorCount: $message');
    }
    onError?.call(message);
  }
}
