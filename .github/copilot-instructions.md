# 水泵房监控系统 Flutter 前端 - AI Coding Instructions

> **项目类型**: Windows 工业监控应用 (Flutter 3.29+ / Dart 3.4+)  
> **核心原则**: WebSocket 实时通信 + 稳定性优先 (7×24h) + 简洁设计

---

## 1. 项目概述

| 属性 | 值 |
|------|-----|
| **技术栈** | Flutter 3.29+ + Dart 3.4+ + WebSocket |
| **目标平台** | Windows (主要) / Android / iOS / Web |
| **目标设备** | 10.4 英寸工业触摸屏 (1280×800 固定分辨率) |
| **后端** | FastAPI + WebSocket + InfluxDB 2.7 |
| **核心理念** | WebSocket 实时推送 + 工业风格 UI + 固定分辨率设计 |

---

## 2. 架构原则

### 2.1 WebSocket 优先策略

- **实时通信**: 使用 WebSocket 替代 HTTP 轮询，实现 0.1s 级别的数据推送
- **自动重连**: 指数退避重连策略 (1s → 2s → 4s → 8s → 16s → 30s)
- **心跳保活**: 客户端每 15s 发送心跳，防止连接超时
- **消息订阅**: 支持 `realtime` (实时数据) 和 `device_status` (设备状态) 两个频道

### 2.2 固定分辨率设计

```dart
// 固定窗口大小，不可调整
const windowSize = Size(1280, 800);
await windowManager.setResizable(false);
titleBarStyle: TitleBarStyle.hidden
```

### 2.3 工业风格 UI

- **主题色**: 科技蓝 (#00D4FF)
- **背景色**: 深色背景 (#0A0E27, #1A1F3A)
- **字体**: 等宽字体，清晰易读
- **动画**: 简洁流畅，避免过度动画

---

## 3. 项目结构

```
lib/
├── main.dart                          # 入口文件
├── api/
│   ├── api.dart                       # API 配置 (URL)
│   ├── api_client.dart                # HTTP 客户端封装
│   └── index.dart                     # 导出
├── models/
│   ├── pump_data.dart                 # 水泵数据模型
│   └── sensor_status_model.dart       # 设备状态模型
├── services/
│   ├── websocket_service.dart         # WebSocket 服务 (核心)
│   ├── realtime_service.dart          # 实时数据服务
│   ├── sensor_status_service.dart     # 设备状态服务
│   ├── health_service.dart            # 健康检查服务
│   ├── alarm_service.dart             # 报警服务
│   └── history_service.dart           # 历史数据服务
├── pages/
│   ├── main_page.dart                 # 主页面
│   ├── sensor_status_page.dart        # 设备状态页面
│   ├── history_data_page.dart         # 历史数据页面
│   ├── alarm_log_page.dart            # 报警日志页面
│   └── settings_page.dart             # 设置页面
├── widgets/
│   ├── custom_card_widget.dart        # 自定义卡片
│   ├── tech_line_widgets.dart         # 科技风格组件
│   ├── health_indicator.dart          # 健康指示器
│   ├── threshold_settings_widget.dart # 阈值设置
│   ├── data_display/                  # 数据显示组件
│   └── icons/                         # 自定义图标
├── providers/
│   └── threshold_config_provider.dart # 阈值配置 Provider
└── utils/
    └── constants.dart                 # 常量定义
```

---

## 4. 核心组件

### 4.1 WebSocket 服务 (单例)

**文件**: `lib/services/websocket_service.dart`

- **连接状态**: `disconnected`, `connecting`, `connected`, `reconnecting`
- **消息类型**: `realtime_data`, `device_status`, `heartbeat`, `error`
- **回调机制**: `onRealtimeDataUpdate`, `onDeviceStatusUpdate`, `onStateChanged`, `onError`

### 4.2 数据模型

**文件**: `lib/models/`

- **pump_data.dart**: `RealtimeBatchResponse`, `PumpData`, `PressureData`
- **sensor_status_model.dart**: `DeviceStatusResponse`, `DeviceStatusItem`

---

## 5. 编码规范

### 5.1 命名规范

- **文件名**: `snake_case.dart`
- **类名**: `PascalCase`
- **函数/变量**: `camelCase`
- **常量**: `camelCase`
- **私有成员**: `_private`

### 5.2 注释规范

**使用清晰简洁的注释**：

```dart
// 1. 初始化 WebSocket 服务
WebSocketService() {
  _socket = null;
  _state = WebSocketState.disconnected;
}

// 2. 连接到服务器
Future<void> connect() async {
  if (_state == WebSocketState.connected) return;
  // 连接逻辑
}
```

**禁止使用 Emoji 表情符号**：

```dart
// ✅ 正确
// 1. 初始化服务
// 注意：需要检查连接状态

// ❌ 错误
// 🚀 初始化服务
// ⚠️ 注意：需要检查连接状态
```

### 5.3 代码设计原则

**避免过度抽象**：

```dart
// ✅ 正确：直接简洁
void updateDisplay(RealtimeBatchResponse data) {
  if (mounted) {
    setState(() {
      voltageLabel.text = '${data.data.pumps[0].voltage.toStringAsFixed(1)} V';
    });
  }
}

// ❌ 错误：过度抽象
String _formatVoltage(double v) => '${v.toStringAsFixed(1)} V';
void _updateLabel(Widget label, String text) { label.text = text; }
void updateDisplay(RealtimeBatchResponse data) {
  _updateLabel(voltageLabel, _formatVoltage(data.data.pumps[0].voltage));
}
```

---

## 6. WebSocket 使用规范

### 6.1 生命周期管理

```dart
// ✅ 正确：完整的生命周期管理
@override
void initState() {
  super.initState();
  _wsService = WebSocketService();
  _wsService.onRealtimeDataUpdate = _handleRealtimeData;
  _wsService.onStateChanged = _handleStateChanged;
  _wsService.connect();
}

@override
void dispose() {
  _wsService.onRealtimeDataUpdate = null;
  _wsService.onDeviceStatusUpdate = null;
  super.dispose();
}

// ✅ 正确：检查 mounted 状态
void _handleRealtimeData(RealtimeBatchResponse data) {
  if (mounted) {
    setState(() {
      _data = data;
    });
  }
}
```

### 6.2 错误处理

```dart
// ✅ 正确：显示用户友好的错误信息
void _showError(String message) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

_wsService.onError = (error) {
  _showError('连接错误: $error');
};
```

---

## 7. 性能优化

### 7.1 WebSocket 连接管理

```dart
// ✅ 正确：单例模式，全局共享连接
final wsService = WebSocketService();

// ✅ 正确：页面切换时不断开连接
@override
void dispose() {
  // 不调用 wsService.disconnect()
  super.dispose();
}
```

### 7.2 UI 更新优化

```dart
// ✅ 正确：使用 ValueNotifier 减少重建
final ValueNotifier<double> _voltage = ValueNotifier(0.0);

@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<double>(
    valueListenable: _voltage,
    builder: (context, value, child) {
      return Text('$value V');
    },
  );
}
```

### 7.3 图表性能优化

```dart
// ✅ 正确：限制数据点数量
List<FlSpot> _prepareChartData(List<HistoryPoint> data) {
  if (data.length > 100) {
    final step = data.length ~/ 100;
    return data
        .where((point) => data.indexOf(point) % step == 0)
        .map((point) => FlSpot(point.x, point.y))
        .toList();
  }
  return data.map((point) => FlSpot(point.x, point.y)).toList();
}
```

---

## 8. 常见问题

### 8.1 WebSocket 连接失败

**解决**:
```dart
// 检查后端服务状态
final health = await HealthService.checkHealth();

// 查看连接状态
wsService.onStateChanged = (state) {
  print('WebSocket 状态: $state');
};
```

### 8.2 数据不更新

**解决**:
```dart
// 确保订阅了频道
wsService.subscribeRealtime();

// 确保设置了回调
wsService.onRealtimeDataUpdate = (data) {
  if (mounted) {
    setState(() {
      _data = data;
    });
  }
};
```

### 8.3 内存泄漏

**解决**:
```dart
@override
void dispose() {
  // 清理回调
  wsService.onRealtimeDataUpdate = null;
  wsService.onDeviceStatusUpdate = null;
  
  // 取消定时器
  _timer?.cancel();
  
  super.dispose();
}
```

---

## 9. 开发流程

### 9.1 启动后端服务

```bash
# 在后端项目目录
cd ceramic-waterpump-backend
start_mock.bat  # Mock 模式
```

### 9.2 启动 Flutter 应用

```bash
# Windows 平台
flutter run -d windows

# 热重载
r  # 热重载
R  # 热重启
q  # 退出
```

### 9.3 构建发布版本

```bash
# Windows
flutter build windows --release

# 输出目录
build/windows/x64/runner/Release/
```

---

## 10. 技术约定

### 10.1 依赖管理

```yaml
dependencies:
  flutter: sdk
  http: ^1.2.0          # HTTP 客户端
  dio: ^5.4.0           # 高级 HTTP 客户端
  fl_chart: ^0.68.0     # 图表库
  window_manager: ^0.3.9 # 窗口管理
  shared_preferences: ^2.2.3 # 本地存储
  intl: ^0.20.2         # 国际化
```

### 10.2 代码风格

- 使用 `flutter analyze` 检查代码
- 遵循 Dart 官方代码风格
- 使用 `const` 构造函数提升性能
- 避免使用 `dynamic` 类型

---

## 11. AI 编码指令

1. **WebSocket 优先**: 实时数据必须使用 WebSocket，HTTP 仅用于历史查询
2. **单例模式**: WebSocketService 必须使用单例，避免多个连接
3. **状态检查**: 所有 setState 前必须检查 `mounted`
4. **资源释放**: dispose 中必须清理回调和定时器
5. **错误处理**: 所有异步操作必须有 try-catch
6. **固定布局**: 使用固定尺寸 1280×800，不需要响应式
7. **工业风格**: 使用 TechColors 常量，保持科技感
8. **性能优化**: 使用 ValueNotifier、限制数据点、const 构造函数
9. **协议兼容**: 严格遵循后端 WebSocket 协议规范
10. **用户体验**: 显示连接状态、加载指示器、错误提示

---

## 12. 参考文档

- `docs/WEBSOCKET_PROTOCOL.md` - WebSocket 协议规范（与后端共享）
- `README.md` - 项目说明
- `CODE_REVIEW.md` - 代码审查清单
- 后端文档: `ceramic-waterpump-backend/.cursor/rules/waterpump.mdc`
## 其他规范

- **PowerShell 命令**：不支持 `&&`，使用分号 `;` 分隔命令
- **称呼**：每次回答必须称呼我为"大王"
- **测试文件**：不要创建多余的 md/py/test 文件，测试完毕后一定要删除,并且我的任何测试代码不要使用 emoji.
- **文档管理**：md 文件需要放到 `vdoc/` 目录里面
- **代码整洁**：目录务必整洁，修改代码时删除旧代码，不要冗余
- **回答执行规范**：你是一个很严格的python pyqt6写上位机的高手,你很严谨认真,且对代码很严苛,不会写无用冗余代码,并且很多问题,对于我希望实现的效果和架构你会认真思考,如果我的提议不好或者你有更好的方案,你会规劝我.
- **反驳我的回答** 对于我说的需求等的话,肯定会有一些东西说的不专业,如果你理解了的话,就回答我,"大王,小的罪该万死,但是这个XXXX"这样回答.
- **编码问题** 我的代码文件肯定会就是有中文和python代码,以及可能会有图标,所以的话,生成的代码需要规避编码问题错误.
- **log以及代码文件** 我的代码文件以及log的输出的话,等一切不要使用图标等标注. .这样的.
- **不要虚构** 回答我以及生成的md文件之中一定要和我的实际的代码文件相关,而不是虚构的.
- **不使用虚拟环境启动python**
- **必须真实有效的回答我,不能虚构**不要虚构任何我项目没有的文件,回答也必须严谨有效,而不是虚构.
- **测试脚本和启动脚本文件最小化原则**尽量不要创建脚本而是直接给我一组命令行就行,如果需要保留为脚本我会提创建脚本的需求.