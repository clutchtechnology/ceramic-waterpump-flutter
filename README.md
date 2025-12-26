# 陶瓷水泵控制应用

基于 Flutter 开发的陶瓷水泵控制与监控应用，支持 Windows、Android、iOS 和 Web 多平台。

## 功能特性

- 🖥️ 分屏显示界面
- 📊 实时数据监控
- 🎨 自定义卡片组件
- 📈 技术参数展示

## 支持平台

- ✅ Windows（桌面应用）
- ✅ Android
- ✅ iOS
- ✅ Web

## 环境要求

- Flutter 3.29.3 或更高版本
- Dart 3.7.0 或更高版本

## 快速开始

### 安装依赖

```bash
flutter pub get
```

### 运行应用

#### Windows 平台
```bash
flutter run -d windows
```

#### Android 平台
```bash
flutter run -d android
```

#### iOS 平台（需要 macOS）
```bash
flutter run -d ios
```

#### Web 平台
```bash
flutter run -d chrome
```

### 构建发布版本

#### Windows
```bash
flutter build windows
```

#### Android APK
```bash
flutter build apk
```

#### iOS（需要 macOS）
```bash
flutter build ios
```

#### Web
```bash
flutter build web
```

## 项目结构

```
lib/
├── main.dart                      # 应用入口
├── pages/
│   └── split_screen_page.dart     # 分屏页面
└── widgets/
    ├── custom_card_widget.dart    # 自定义卡片组件
    └── tech_line_widgets.dart     # 技术参数组件
assets/
└── images/                        # 图片资源
```

## 开发说明

本项目使用 Flutter 框架开发，主要特点：
- 采用响应式布局，适配不同屏幕尺寸
- 使用自定义组件构建界面
- 支持多平台部署

## 技术栈

- Flutter 3.29.3
- Dart 3.7.2
- Material Design

## 许可证

私有项目，未发布到 pub.dev
