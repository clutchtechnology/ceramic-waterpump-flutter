# 水泵房监控系统 - AI Coding Instructions

> **Reading Priority for AI:**
>
> 1. **[CRITICAL]** - Hard constraints, must strictly follow
> 2. **[IMPORTANT]** - Key specifications
> 3. Other content - Reference information

---

## 1. Project Overview

| Property          | Value                                            |
| ----------------- | ------------------------------------------------ |
| **Type**          | Windows Desktop Industrial Monitoring App        |
| **Stack**         | Flutter 3.22.x + Dart 3.4.x                      |
| **Backend**       | FastAPI (Python) + InfluxDB 2.7                  |
| **Target**        | 工控机触摸屏 (1280×800)                          |
| **Key Principle** | **Stability (7x24h)** & **Simplicity (Occam's)** |

---

## 2. Project Structure

```
lib/
├── main.dart           # App entry point
├── api/                # ApiClient (Singleton, Timeouts)
├── pages/              # UI Pages (Tab-based navigation)
│   ├── main_page.dart          # Tab Controller
│   ├── split_screen_page.dart  # Real-time (Pumps + Pressure)
│   ├── history_data_page.dart  # History Charts
│   └── settings_page.dart      # Thresholds
├── widgets/            # Reusable UI components
├── models/             # Data models
├── providers/          # Global State (Settings)
└── services/           # Business Logic (No UI references)
```

---

## 3. Equipment Configuration (Waterpump Specific)

### 3.1 Water Pumps (6 units)

```yaml
Water Pumps:
  quantity: 6 units
  layout: 2 rows x 3 columns
  monitoring:
    - Voltage (V)
    - Current (A)
    - Power (kW)
    - Vibration (mm/s)
  features:
    - Real-time data display on cards
    - Historical trend curves
    - Alarm thresholds configuration
```

### 3.2 Pressure Sensor (1 unit)

```yaml
Pressure Sensor:
  quantity: 1 unit
  display: Gauge / Digital readout
  monitoring:
    - Pressure value (MPa)
  features:
    - High/Low alarm limits
    - Trend chart
    - Threshold configuration
```

---

## 4. [CRITICAL] UI/Navigation Requirements

### 4.1 Tab-Based Navigation

- **[CRITICAL]** All modules organized as Tabs
- Click tab title to switch modules
- Modules: [实时监控] | [历史数据] | [系统设置]

### 4.2 Window Configuration

```dart
// [CRITICAL] Fixed window size, no resize
const fixedSize = Size(1280, 800);
await windowManager.setResizable(false);
titleBarStyle: TitleBarStyle.hidden
```

### 4.3 Layout Pattern

```
┌─────────────────────────────────────────────────────────┐
│  Tab Bar: [实时监控] [历史数据] [系统设置]                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   Left Panel (Pumps)     │    Right Panel (Pressure)   │
│   ┌─────┐ ┌─────┐ ┌─────┐│                              │
│   │Pump1│ │Pump2│ │Pump3││    ┌─────────────┐          │
│   └─────┘ └─────┘ └─────┘│    │  Pressure   │          │
│   ┌─────┐ ┌─────┐ ┌─────┐│    │   Gauge     │          │
│   │Pump4│ │Pump5│ │Pump6││    └─────────────┘          │
│   └─────┘ └─────┘ └─────┘│                              │
│                          │    Trend Chart              │
└─────────────────────────────────────────────────────────┘
```

---

## 5. [CRITICAL] Data Specifications

### 5.1 Refresh Rates

| Data Type       | Refresh Rate | Sync Delay |
| --------------- | ------------ | ---------- |
| Voltage (V)     | ≤5 seconds   | ≤3 seconds |
| Current (A)     | ≤5 seconds   | -          |
| Power (kW)      | ≤5 seconds   | -          |
| Vibration       | ≤5 seconds   | -          |
| Pressure (MPa)  | ≤5 seconds   | -          |

### 5.2 Display Format

- **Text + Icon**: All real-time values shown with icon + numeric value
- **Units**: Always display units (V, A, kW, mm/s, MPa)
- **Status**: Running (green) / Stopped (gray) / Alarm (red blink) indicators

### 5.3 Historical Data Query

```yaml
Features:
  - Custom time range selection (start/end)
  - Multi-dimension: hour, day, week, month
  - Chart types: Line chart, Data table
  - Multi-device comparison support
  - Batch Handling: Skip recent few minutes if backend has batch write delay
```

---

## 6. [IMPORTANT] UI Design - Industrial HMI/SCADA Style

### 6.1 Design Principles

**Functionality > Clarity > Reliability > Aesthetics**

### 6.2 Color System (Tech/Sci-Fi Style)

```dart
class TechColors {
  // Backgrounds
  static const bgDeep = Color(0xFF0d1117);
  static const bgDark = Color(0xFF161b22);
  static const bgMedium = Color(0xFF21262d);

  // Glow effects
  static const glowCyan = Color(0xFF00d4ff);
  static const glowGreen = Color(0xFF00ff88);
  static const glowOrange = Color(0xFFff9500);
  static const glowRed = Color(0xFFff3b30);

  // Text
  static const textPrimary = Color(0xFFe6edf3);
  static const textSecondary = Color(0xFF8b949e);

  // Status (ISA-101 Standard)
  static const statusNormal = Color(0xFF00ff88);   // Green: Running
  static const statusWarning = Color(0xFFffcc00);  // Yellow: Warning
  static const statusAlarm = Color(0xFFff3b30);    // Red: Alarm (blink)
  static const statusOffline = Color(0xFF484f58);  // Gray: Stopped
}
```

### 6.3 Component Specs

| Component        | Size        | Font                        |
| ---------------- | ----------- | --------------------------- |
| Pump Card        | 200×120px   | Roboto Mono, 18-32px        |
| Value Display    | -           | 24-36px, weight 500-700     |
| Pressure Gauge   | 200×200px   | -                           |
| Status Indicator | 12-16px dot | Solid fill, pulse animation |
| Data Table       | 28-32px row | Label 12-14px               |

---

## 7. Settings Module Requirements

### 7.1 Configuration Options

```yaml
Server Config:
  - Backend IP address
  - Backend Port number

Threshold Config:
  - Pressure High/Low limits
  - Vibration alarm threshold
  - Power alarm threshold
```

### 7.2 Configuration Features

- **[IMPORTANT]** Auto connection test after modification
- **[IMPORTANT]** Save config persistently (survive restart)
- **[IMPORTANT]** Graceful handling when backend offline

---

## 8. Technical Conventions

### 8.1 Dependencies

```yaml
charts: fl_chart
state_management: StatefulWidget (current) / Provider (global state)
window_management: window_manager
http_client: http (with singleton pattern)
```

### 8.2 Code Style

- Use `const` constructors where possible (Performance)
- Strict typing (Avoid `dynamic`)
- Comments in English or Chinese (Be consistent)

---

## 9. Development Guidelines

### 9.1 Backend (Mock/Prod)

- Use `docker compose --profile mock up -d` for dev backend
- Frontend must handle "Backend Offline" state gracefully (Gray out UI, show Retry button), DO NOT crash

### 9.2 Development Commands

```powershell
# Run in development mode
flutter run -d windows

# Build release version
flutter build windows

# Analyze code
flutter analyze
```

---

## 10. [CRITICAL] Flutter 性能优化与内存泄漏防止 (奥卡姆剃刀原则)

> **核心原则**: 如无必要，勿增实体。代码越简单，bug 越少，内存泄漏风险越低。

### 10.1 Timer 生命周期管理 ⏱️

**问题根源**: Timer 是工控 App 卡死的**头号杀手**。未正确销毁的 Timer 会在后台持续运行，累积导致内存泄漏和 UI 卡死。

```dart
// ❌ 致命错误：Timer 未取消
class _MyPageState extends State<MyPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 5), (_) => _fetchData());
  }
  // 缺少 dispose() - Timer 永远不会停止！
}

// ✅ 正确做法：完整的生命周期管理
class _MyPageState extends State<MyPage> {
  Timer? _timer;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    if (_isPolling) return; // 防止重复启动
    _isPolling = true;
    _timer = Timer.periodic(Duration(seconds: 5), (_) {
      if (mounted) _fetchData(); // 检查 mounted 状态
    });
  }

  void pausePolling() {
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
  }

  void resumePolling() {
    if (!_isPolling) _startPolling();
  }

  @override
  void dispose() {
    pausePolling(); // 确保 Timer 被取消
    super.dispose();
  }
}
```

**[CRITICAL] Timer 检查清单**:

- [ ] 每个 Timer.periodic 必须有对应的 cancel()
- [ ] dispose() 中必须取消所有 Timer
- [ ] Timer 回调必须检查 `mounted` 状态
- [ ] Tab 切换时暂停非活跃页面的 Timer
- [ ] **禁止**使用 `Stream.periodic` 替代 Timer（更难控制生命周期）

### 10.2 HTTP Client 连接管理 🌐

**问题根源**: HTTP 连接池耗尽或连接卡死导致后续请求超时，最终 UI 无响应。

```dart
// ❌ 错误：每次请求创建新 Client
Future<void> fetchData() async {
  final client = http.Client();
  final response = await client.get(Uri.parse(url));
  // client 从未关闭，连接泄漏！
}

// ❌ 错误：static final 无重连机制
class ApiClient {
  static final _client = http.Client(); // 永不更新的连接
}

// ✅ 正确做法：单例 + 超时 + 重连机制
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  http.Client _client = http.Client();
  DateTime _lastRefresh = DateTime.now();
  static const _refreshInterval = Duration(minutes: 30);

  http.Client get client {
    if (DateTime.now().difference(_lastRefresh) > _refreshInterval) {
      _client.close();
      _client = http.Client();
      _lastRefresh = DateTime.now();
    }
    return _client;
  }

  Future<http.Response> get(String path) async {
    return client.get(Uri.parse('$baseUrl$path'))
        .timeout(const Duration(seconds: 10)); // 必须设置超时！
  }

  void dispose() {
    _client.close();
  }
}
```

**[CRITICAL] HTTP 检查清单**:

- [ ] 所有 HTTP 请求必须设置 `timeout`（建议 10-15 秒）
- [ ] 使用单例 ApiClient，避免创建多个 Client
- [ ] 定期刷新 HTTP Client（建议 30 分钟）
- [ ] 异常捕获必须包含 `TimeoutException` 和 `SocketException`

### 10.3 导航架构选择 🧭

**问题根源**: `IndexedStack` 会同时保持所有子页面存活，每个页面的 Timer 都在后台运行！

```dart
// ⚠️ 危险：IndexedStack 保持所有页面存活
IndexedStack(
  index: _currentIndex,
  children: [
    Page1(), // Timer 运行中
    Page2(), // Timer 运行中
    Page3(), // Timer 运行中
  ], // 3个页面的 Timer 同时运行！
)

// ✅ 正确做法：使用 GlobalKey 控制页面状态
final _page1Key = GlobalKey<_Page1State>();
final _page2Key = GlobalKey<_Page2State>();

void _onTabChanged(int index) {
  // 暂停所有页面的轮询
  _page1Key.currentState?.pausePolling();
  _page2Key.currentState?.pausePolling();

  // 只恢复当前页面的轮询
  switch (index) {
    case 0: _page1Key.currentState?.resumePolling(); break;
    case 1: _page2Key.currentState?.resumePolling(); break;
  }
}
```

**[CRITICAL] 导航检查清单**:

- [ ] IndexedStack 必须配合 GlobalKey + pausePolling/resumePolling
- [ ] Tab 切换必须调用 `pausePolling()` 暂停非活跃页
- [ ] **禁止**使用 `AutomaticKeepAliveClientMixin`（除非有明确理由）

### 10.4 State 生命周期与 dispose() ♻️

**问题根源**: Windows 桌面应用关闭时，进程被直接杀死，`dispose()` 可能**永远不会执行**！

```dart
// ❌ 错误假设：dispose() 总会被调用
class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    ApiClient().dispose(); // Windows 关闭时可能不执行！
    super.dispose();
  }
}

// ✅ 正确做法：使用 WidgetsBindingObserver 监听生命周期
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // 在这里清理资源
      _cleanupResources();
    }
  }

  void _cleanupResources() {
    // 取消所有 Timer
    // 关闭数据库连接
    // 关闭 HTTP Client
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }
}
```

### 10.5 奥卡姆剃刀代码审查清单 🔪

**每次代码审查必须检查以下项目**:

| 检查项    | 危险信号                        | 正确做法                             |
| --------- | ------------------------------- | ------------------------------------ |
| Timer     | `Timer.periodic` 无 `cancel()`  | 必须配对 `cancel()` + `mounted` 检查 |
| HTTP      | `http.get()` 无 `timeout`       | 所有请求设置 10-15s 超时             |
| Stream    | `Stream.periodic`               | 改用 `Timer.periodic`                |
| KeepAlive | `AutomaticKeepAliveClientMixin` | 删除，使用 GlobalKey 控制            |
| 导航      | `IndexedStack` 无暂停机制       | 添加 `pausePolling/resumePolling`    |
| 异常      | `try-catch` 吞掉异常            | 必须记录日志                         |
| 单例      | 多处 `new http.Client()`        | 使用 `ApiClient` 单例                |

### 10.6 工控机专用优化 🏭

```dart
// 工控机环境特点：
// - 长时间运行（7x24小时）
// - 内存有限（通常 4-8GB）
// - 触摸屏操作
// - 网络可能不稳定

// [CRITICAL] 必须实现的功能：
// 1. 定期 GC 强制回收
Timer.periodic(Duration(minutes: 10), (_) {
  // 手动触发 GC（仅限 Debug 模式分析）
  debugPrint('Memory cleanup triggered');
});

// 2. 网络重连机制
int _retryCount = 0;
Future<void> _fetchWithRetry() async {
  try {
    await _fetchData();
    _retryCount = 0;
  } catch (e) {
    _retryCount++;
    if (_retryCount < 3) {
      await Future.delayed(Duration(seconds: _retryCount * 2));
      return _fetchWithRetry();
    }
    // 3次失败后显示离线状态
  }
}

// 3. 心跳检测
Timer.periodic(Duration(seconds: 30), (_) {
  _checkConnection();
});
```

---

## 11. Anti-Patterns (Do NOT do this)

- ❌ **NO**: Nested `StreamBuilder`s causing multiple redraws
- ❌ **NO**: Uncontrolled `Isolate` spawning
- ❌ **NO**: Hardcoded IP addresses (Use Config/Env)
- ❌ **NO**: Ignoring `dispose()` methods
- ❌ **NO**: `Stream.periodic` replacing Timer (harder lifecycle control)
- ❌ **NO**: `AutomaticKeepAliveClientMixin` without clear reason

---

## 12. Troubleshooting

| Issue                 | Solution                                              |
| --------------------- | ----------------------------------------------------- |
| VS 2019 required      | Flutter 3.22.x needs VS 2019 Build Tools              |
| PLC connection failed | Check IP and backend service status                   |
| **App 卡死 (Freeze)** | **检查 10.1-10.4 的所有检查清单项**                   |
| **内存持续增长**      | **检查 Timer 累积、HTTP Client 泄漏、IndexedStack**   |
| **UI 无响应**         | **检查 HTTP 超时设置、异步操作阻塞主线程**            |

---

## 13. File Organization Guidelines

### 13.1 Pages (`lib/pages/`)

- One file per tab/module
- Naming: `{module_name}_page.dart`
- Example: `split_screen_page.dart`, `history_data_page.dart`, `settings_page.dart`

### 13.2 Widgets (`lib/widgets/`)

- Reusable UI components
- Naming: `{component_type}_widget.dart`
- Example: `pump_card.dart`, `pressure_gauge.dart`, `status_indicator.dart`

### 13.3 Models (`lib/models/`)

- Data structures and entities
- Naming: `{entity_name}_model.dart`
- Example: `pump_data.dart`, `pressure_data.dart`, `threshold_config.dart`

### 13.4 Services (`lib/services/`)

- Business logic and API calls
- Naming: `{service_name}_service.dart`
- Example: `data_service.dart`, `config_service.dart`

### 13.5 Utils (`lib/utils/`)

- Helper functions and constants
- Example: `constants.dart`, `formatters.dart`, `validators.dart`

---

**Summary for AI**: When modifying this project, prioritize **robustness**. If a fancy animation risks stability, discard it. If a complex pattern complicates reading config, simplify it. 工控机 7x24 稳定运行是第一优先级。
