# 水泵房监控系统 - AI Coding Instructions

> **Reading Priority for AI:**
>
> 1. **[CRITICAL]** - Hard constraints, must strictly follow
> 2. **[IMPORTANT]** - Key specifications
> 3. Other content - Reference information

---

## 1. Project Overview

| Property          | Value                                                              |
| ----------------- | ------------------------------------------------------------------ |
| **Type**          | Windows Desktop Industrial Monitoring App                          |
| **Stack**         | Flutter 3.22.x + Dart 3.4.x                                        |
| **Backend**       | FastAPI (Python) + InfluxDB 2.7                                    |
| **Target**        | 工控机触摸屏 (1280×800)                                            |
| **Core Features** | 6 水泵电表监控、压力检测、振动幅值监控、历史数据查询、阈值报警设置 |

---

## 2. Project Structure

```
lib/
├── main.dart           # App entry point, window configuration
├── api/                # API client and endpoints
│   ├── api.dart        # API endpoint definitions
│   └── index.dart      # ApiClient singleton
├── pages/              # UI pages (Tab-based navigation)
│   ├── main_page.dart          # Main layout with tabs
│   ├── split_screen_page.dart  # Real-time monitoring (left: pumps, right: pressure)
│   ├── history_data_page.dart  # Historical data charts
│   └── settings_page.dart      # System settings & thresholds
├── widgets/            # Reusable UI components
│   ├── tech_line_widgets.dart  # Tech-style base widgets
│   ├── threshold_settings_widget.dart  # Threshold configuration
│   └── data_display/   # Chart components
├── models/             # Data models
├── providers/          # State management (ChangeNotifier)
│   └── threshold_config_provider.dart
├── services/           # Business logic & API services
│   └── history_service.dart    # History data with auto-aggregation
└── utils/              # Utility functions & helpers
```

---

## 3. Equipment Configuration

### 3.1 Water Pumps (6 units)

```yaml
Water Pumps:
  quantity: 6 units
  monitoring:
    - Voltage (V)
    - Current (A)
    - Power (kW)
    - Vibration amplitude
  features:
    - Real-time status display
    - Historical trend charts
    - Threshold alarms (high/low)
```

### 3.2 Pressure Sensor (1 unit)

```yaml
Pressure Sensor:
  quantity: 1 unit
  monitoring:
    - Pressure value (MPa)
  features:
    - Real-time display with gauge
    - High/Low pressure alarms
    - Historical pressure curves
```

---

## 4. [CRITICAL] UI/Navigation Requirements

### 4.1 Tab-Based Navigation

- **[CRITICAL]** All modules organized as Tabs
- Modules: 实时监控 | 历史数据 | 系统设置

### 4.2 Window Configuration

```dart
// [CRITICAL] Fixed window size, no resize
const fixedSize = Size(1280, 800);
await windowManager.setResizable(false);
titleBarStyle: TitleBarStyle.hidden
```

### 4.3 Layout Pattern (Split Screen Page)

```
┌─────────────────────────────────────────────────────────┐
│  Tab Bar: [实时监控] [历史数据] [系统设置]               │
├─────────────────────────────────────────────────────────┤
│  Left Panel (60%)        │  Right Panel (40%)           │
│  ┌─────────────────────┐ │  ┌─────────────────────────┐ │
│  │ 6 Water Pump Cards  │ │  │ Pressure Gauge          │ │
│  │ - Voltage           │ │  │ - Current value         │ │
│  │ - Current           │ │  │ - Status indicator      │ │
│  │ - Power             │ │  │ - High/Low thresholds   │ │
│  │ - Status            │ │  └─────────────────────────┘ │
│  └─────────────────────┘ │  ┌─────────────────────────┐ │
│                          │  │ Vibration Status        │ │
│                          │  │ - 6 pump amplitudes     │ │
│                          │  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 5. [CRITICAL] Data Specifications

### 5.1 Backend Configuration

```yaml
Backend:
  host: localhost
  port: 8081
  mode: mock (default) | production
  polling_interval: 5s
  batch_write: 30 polls (150s)
```

### 5.2 API Endpoints

```yaml
Realtime:
  GET /api/realtime/batch     # All 6 pumps + pressure
  GET /api/realtime/pressure  # Pressure only
  GET /api/realtime/{pump_id} # Single pump (1-6)

History:
  GET /api/history            # Historical data query
    params:
      - pump_id: int (1-6, null for pressure)
      - parameter: string (voltage/current/power/pressure)
      - start: ISO 8601 datetime
      - end: ISO 8601 datetime
      - interval: string (5s/1m/5m/1h/1d)

Health:
  GET /api/health             # System health check
```

### 5.3 History Data Aggregation

```dart
// [IMPORTANT] Auto-calculate aggregation interval
// Target: ~50 data points regardless of time range

static const int _targetPoints = 50;
static const int _minPoints = 30;
static const int _maxPoints = 80;

// Examples:
// - 1 minute  → 5s interval  → ~12 points
// - 5 minutes → 5s interval  → ~60 points
// - 1 hour    → 1m interval  → 60 points
// - 24 hours  → 30m interval → 48 points
// - 7 days    → 4h interval  → 42 points
```

### 5.4 Batch Write Delay

```dart
// [IMPORTANT] Backend uses batch write (30 polls × 5s = 150s delay)
// Query historical data should skip recent 4-5 minutes

final now = DateTime.now();
final end = now.subtract(const Duration(minutes: 4));
final start = now.subtract(const Duration(minutes: 5));
```

---

## 6. [IMPORTANT] UI Design - Industrial HMI Style

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

---

## 7. Threshold Configuration

### 7.1 Pressure Thresholds

```dart
// Stored in ThresholdConfigProvider
double pressureHighAlarm = 1.0;  // MPa
double pressureLowAlarm = 0.3;   // MPa
```

### 7.2 Vibration Thresholds (per pump)

```dart
// 6 pumps, each with individual thresholds
List<VibrationConfig> vibrationConfigs = [
  VibrationConfig(pumpId: 1, warningMax: 1.5, alarmMax: 2.0),
  // ... pump 2-6
];
```

### 7.3 Settings Page Password

```dart
// [IMPORTANT] Currently bypassed for development
// Default: _isLoggedIn = true (no password required)
// Production: implement password verification
```

---

## 8. Docker Deployment

### 8.1 Start Backend (Mock Mode)

```powershell
cd ceramic-waterpump-backend
docker compose --profile mock up -d --build
```

### 8.2 Container Services

| Container          | Port | Description             |
| ------------------ | ---- | ----------------------- |
| waterpump-backend  | 8081 | FastAPI backend         |
| waterpump-influxdb | 8087 | InfluxDB time-series DB |

### 8.3 Verify Services

```powershell
docker compose ps
curl http://localhost:8081/api/health
```

---

## 9. Development Commands

```powershell
# Run Flutter app in development mode
cd ceramic-waterpump-flutter
flutter run -d windows

# Hot reload: press 'r' in terminal
# Hot restart: press 'R' in terminal

# Build release version
flutter build windows

# Analyze code
flutter analyze
```

---

## 10. Troubleshooting

| Issue                         | Solution                                                       |
| ----------------------------- | -------------------------------------------------------------- |
| Backend not starting          | Use `docker compose --profile mock up -d`                      |
| History data returns 2 points | Restart backend: `docker compose --profile mock up -d --build` |
| Window size wrong             | Check window_manager configuration in main.dart                |
| API connection failed         | Verify backend is running on localhost:8081                    |
| Date picker not in Chinese    | Ensure flutter_localizations is configured                     |

---

## 11. Key Files Reference

| File                                           | Purpose                                       |
| ---------------------------------------------- | --------------------------------------------- |
| `lib/main.dart`                                | App entry, window setup, localization         |
| `lib/api/index.dart`                           | ApiClient singleton (baseUrl: localhost:8081) |
| `lib/services/history_service.dart`            | History API with auto-aggregation             |
| `lib/providers/threshold_config_provider.dart` | Threshold state management                    |
| `lib/pages/split_screen_page.dart`             | Real-time monitoring layout                   |
| `lib/pages/history_data_page.dart`             | Historical charts with time range             |
| `lib/pages/settings_page.dart`                 | System settings and thresholds                |

---

中文回答我。
命令行使用 `flutter run --debug` 启动应用。
后端使用 `docker compose --profile mock up -d` 启动。
确保历史数据查询时跳过最近 4-5 分钟的数据以避免批量写入延迟影响。
我的振动等数据目前是 mock 的，暂时还不会真实采集数据,只是先在 app 中占位显示而已.
