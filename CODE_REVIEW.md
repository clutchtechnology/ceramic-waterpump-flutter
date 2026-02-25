# 水泵房监控系统 - 代码审查报告

> **审查日期**: 2024-12-30
> **审查角色**: 资深PLC上位机开发工程师
> **项目**: ceramic-waterpump-flutter + ceramic-waterpump-backend

---

##  总体评价

| 维度 | 评分 | 说明 |
|-----|------|------|
| 架构设计 |  | 前后端分离，结构清晰 |
| 代码质量 |  | 模块化良好，可读性强 |
| 工业适用性 |  | 存在改进空间 |
| 异常处理 |  | 基础完善，需加强 |
| 安全性 |  | 需要加强 |

---

## 🔴 严重问题 (必须修复)

### 1. 实时监控页面使用硬编码数据

**位置**: [split_screen_page.dart](lib/pages/split_screen_page.dart#L39-L70)

```dart
// 当前问题：页面使用硬编码数据，没有使用 RealtimeService
_buildPumpCard('#1', 45.2, 320.5, 30.1, 29.8, 30.3, true, vibration: 0.85, pressure: 0.65),
```

**影响**: 实时监控页面显示的是固定值，不是后端实际数据！

**建议**:
```dart
// 应该使用 RealtimeService 获取的数据
final pump = _realtimeData?.getPump(1);
_buildPumpCard(
  '#1',
  pump?.power ?? 0.0,
  0.0, // energy 需要后端支持
  pump?.current ?? 0.0,
  pump?.current ?? 0.0,
  pump?.current ?? 0.0,
  pump?.isRunning ?? false,
  vibration: 0.0, // 待PLC接入
  pressure: _realtimeData?.pressure.value,
),
```

---

### 2. 缺少通信断连报警机制

**问题**: 当后端或PLC断连时，只有小图标变灰，没有明显的报警提示

**工业要求**: PLC通信中断是**严重故障**，必须有以下机制：

- [ ] 声音报警 (蜂鸣)
- [ ] 全屏闪烁报警横幅
- [ ] 报警历史记录
- [ ] 自动重连计数器

**建议实现**:
```dart
// 在 main_page.dart 中添加
if (!_plcHealthy && !_isHealthLoading) {
  _showCriticalAlarm('PLC通信中断！');
  _playAlarmSound();
  _logAlarmHistory('PLC_DISCONNECT', DateTime.now());
}
```

---

### 3. 密码明文存储

**位置**: [settings_page.dart](lib/pages/settings_page.dart#L25)

```dart
static const String _adminPassword = 'admin123';  // 硬编码明文
```

**问题**:
- 管理员密码硬编码在代码中
- 操作员密码明文存储在 SharedPreferences
- 反编译即可获取密码

**建议**:
```dart
// 1. 使用哈希存储
import 'package:crypto/crypto.dart';

String _hashPassword(String password) {
  final bytes = utf8.encode(password + 'salt_key');
  return sha256.convert(bytes).toString();
}

// 2. 管理员密码应从后端验证，不存本地
```

---

## 🟡 重要问题 (建议修复)

### 4. 缺少数据有效性校验

**位置**: [pump_data.dart](lib/models/pump_data.dart)

**问题**: 没有校验数据合理性

```dart
// 当前代码直接使用后端数据
voltage: (json['voltage'] as num?)?.toDouble() ?? 0.0,
```

**工业监控必须校验**:
- 电压范围: 0-500V
- 电流范围: 0-100A
- 功率范围: 0-100kW
- 压力范围: 0-2MPa

**建议**:
```dart
factory PumpData.fromJson(Map<String, dynamic> json) {
  final rawVoltage = (json['voltage'] as num?)?.toDouble() ?? 0.0;
  final rawCurrent = (json['current'] as num?)?.toDouble() ?? 0.0;
  
  // 数据有效性校验
  final voltage = rawVoltage.clamp(0.0, 500.0);
  final current = rawCurrent.clamp(0.0, 100.0);
  
  // 异常值标记
  final dataQuality = (rawVoltage == voltage && rawCurrent == current) 
      ? 'good' : 'bad';
  
  return PumpData(
    voltage: voltage,
    current: current,
    dataQuality: dataQuality,
    // ...
  );
}
```

---

### 5. 轮询间隔不同步

**前端**: 6秒轮询实时数据
**后端**: 5秒轮询PLC + 30批次写入 (150秒)

**问题**:
- 前端可能多次请求同一数据
- 历史数据有150秒延迟

**建议**:
- 前端轮询间隔改为 5秒 (与后端同步)
- 或使用 WebSocket 推送代替轮询
- 显示数据来源时间戳，让用户知道数据新鲜度

---

### 6. 缺少操作审计日志

**工业系统要求**: 所有关键操作必须记录

应记录的操作：
- [ ] 用户登录/登出
- [ ] 阈值参数修改
- [ ] 密码修改
- [ ] 系统设置变更

**建议添加**:
```dart
class AuditLog {
  final DateTime timestamp;
  final String operator;
  final String action;
  final String details;
  final String ipAddress;
}

// 修改阈值时记录
void _saveThreshold() {
  _auditService.log(
    action: 'THRESHOLD_CHANGE',
    details: 'pump1_current: 50.0 -> 55.0',
    operator: _currentUser,
  );
}
```

---

### 7. 历史数据页面缺少导出功能

**工业需求**: 历史数据必须可导出用于分析和存档

**建议添加**:
- [ ] 导出 CSV/Excel
- [ ] 导出 PDF 报表
- [ ] 打印功能
- [ ] 数据筛选后导出

---

### 8. 缺少设备运行统计

**工业需求**: 运维人员需要以下统计数据：

- [ ] 各泵运行时长累计
- [ ] 启停次数统计
- [ ] 故障次数统计
- [ ] 能耗统计 (日/月/年)

---

## 🟢 改进建议 (优化体验)

### 9. UI 触控优化不足

**目标设备**: 10.4寸触摸屏 (1280×800)

**当前问题**:
- 部分按钮太小 (工业触摸屏建议最小 48×48px)
- 输入框需要虚拟键盘支持
- 缺少手指误触防护

**建议**:
```dart
// 工业触摸按钮最小尺寸
const kIndustrialButtonMinSize = Size(48, 48);

// 按钮间距防误触
const kButtonSpacing = 16.0;
```

---

### 10. 缺少离线模式

**场景**: 网络中断时，上位机应该：
- [ ] 显示最后缓存数据 + 时间戳
- [ ] 本地缓存报警记录
- [ ] 网络恢复后自动重连
- [ ] 离线期间数据本地存储，恢复后同步

---

### 11. 缺少多语言支持框架

虽然当前是中文界面，但工业软件应预留多语言接口：

```dart
// 建议使用 flutter_localizations + arb 文件
// lib/l10n/app_zh.arb
{
  "pumpStatus": "水泵状态",
  "pressureAlarm": "压力报警"
}
```

---

### 12. 状态机设计缺失

水泵应有明确的状态机：

```
┌─────────┐   启动   ┌─────────┐   故障   ┌─────────┐
│  停止   │ ───────> │  运行   │ ───────> │  故障   │
│ STOPPED │ <─────── │ RUNNING │ <─────── │  FAULT  │
└─────────┘   停止   └─────────┘   复位   └─────────┘
     │                    │
     │       维护中       │
     └──────> MAINTENANCE <──────┘
```

当前代码只用 `isRunning` 布尔值，无法表达维护、故障等状态。

---

## 📋 后端问题

### 13. Mock 数据不够真实

**位置**: [mock_service.py](../ceramic-waterpump-backend/app/services/mock_service.py)

**问题**: 随机数据无法模拟真实场景

**建议**:
- 添加预设场景（正常运行、启动过程、故障模拟）
- 模拟真实的电机启动电流曲线
- 模拟渐变过程而非跳变

---

### 14. InfluxDB 数据保留策略

**问题**: 未配置数据保留策略，长期运行会占满磁盘

**建议**:
```python
# 配置数据保留策略
# 原始数据保留 7 天
# 1分钟聚合保留 30 天
# 1小时聚合保留 1 年
```

---

##  做得好的地方

1. **模块化设计**: Services、Providers、Widgets 分离清晰
2. **Docker 部署**: 便于部署和迁移
3. **阈值持久化**: SharedPreferences 存储阈值配置
4. **健康检查机制**: 定期检查后端状态
5. **批量写入优化**: 后端30批次写入减少IO
6. **PLC 长连接**: 避免频繁连接断开

---

##  优先级修复建议

| 优先级 | 问题 | 工作量 |
|-------|------|-------|
| P0 | 实时页面接入真实数据 | 2小时 |
| P0 | 通信断连报警 | 4小时 |
| P1 | 数据有效性校验 | 2小时 |
| P1 | 密码加密存储 | 3小时 |
| P2 | 操作审计日志 | 4小时 |
| P2 | 历史数据导出 | 6小时 |
| P3 | 触控优化 | 3小时 |
| P3 | 离线模式 | 8小时 |

---

##  总结

这是一个**架构合理、代码质量较好**的工业监控系统原型。主要问题集中在：

1. **实时数据未接入** - 页面显示硬编码数据
2. **工业级报警机制缺失** - 通信故障没有醒目提示
3. **安全性不足** - 密码明文存储

建议按优先级逐步完善，先确保核心监控功能正常工作，再补充安全和体验优化。

---

*审查人: GitHub Copilot (Claude Opus 4.5)*
*审查日期: 2024-12-30*
