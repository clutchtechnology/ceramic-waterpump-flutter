import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../widgets/tech_line_widgets.dart';
import '../widgets/threshold_settings_widget.dart';
import '../providers/threshold_config_provider.dart';

/// 设置页面
/// 类似磨料车间实现 - 点击登录按钮弹窗输入密码
/// 可修改操作员密码: water123 (默认)
class SettingsPage extends StatefulWidget {
  final ThresholdConfigProvider? thresholdProvider;
  
  const SettingsPage({super.key, this.thresholdProvider});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 登录状态 - 临时设置为直接进入 (跳过密码验证)
  bool _isLoggedIn = true; // TODO: 正式版改回 false

  // 固定管理员密码 (不可修改)
  static const String _adminPassword = 'admin123';
  // 可修改操作员密码的存储key
  static const String _operatorPasswordKey = 'operator_password';
  // 默认操作员密码
  static const String _defaultOperatorPassword = 'water123';

  // 当前操作员密码 (从存储加载)
  String _operatorPassword = _defaultOperatorPassword;

  // 当前选中的配置区
  int _selectedSection = 0; // 0: 系统信息, 1: 密码管理, 2: 阈值设置

  // 密码修改控制器
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // 阈值配置Provider
  late ThresholdConfigProvider _thresholdProvider;

  @override
  void initState() {
    super.initState();
    _loadOperatorPassword();
    // 使用传入的provider或创建新实例
    _thresholdProvider = widget.thresholdProvider ?? ThresholdConfigProvider();
    if (widget.thresholdProvider == null) {
      _thresholdProvider.loadConfig();
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 从本地存储加载操作员密码
  Future<void> _loadOperatorPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(_operatorPasswordKey);
    if (savedPassword != null && savedPassword.isNotEmpty) {
      setState(() {
        _operatorPassword = savedPassword;
      });
    }
  }

  /// 保存操作员密码到本地存储
  Future<bool> _saveOperatorPassword(String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_operatorPasswordKey, newPassword);
      setState(() {
        _operatorPassword = newPassword;
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 显示登录弹窗 (类似磨料车间实现)
  Future<void> _showLoginDialog() async {
    final passwordController = TextEditingController();
    bool showPassword = false;
    String? error;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: TechColors.bgDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TechColors.glowCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: TechColors.glowCyan.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.lock_outline,
                      color: TechColors.glowCyan, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '登录验证',
                  style: TextStyle(color: TechColors.textPrimary, fontSize: 16),
                ),
              ],
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '请输入管理员或操作员密码',
                    style: TextStyle(
                        color: TechColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    autofocus: true,
                    onSubmitted: (_) {
                      final password = passwordController.text;
                      if (password == _adminPassword ||
                          password == _operatorPassword) {
                        Navigator.of(context).pop(true);
                      } else {
                        setDialogState(() => error = '密码错误');
                      }
                    },
                    style:
                        TextStyle(color: TechColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '输入密码',
                      hintStyle:
                          TextStyle(color: TechColors.textMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.lock_outline,
                          color: TechColors.textSecondary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: TechColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setDialogState(() => showPassword = !showPassword),
                      ),
                      filled: true,
                      fillColor: TechColors.bgMedium,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: TechColors.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: TechColors.borderDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide:
                            BorderSide(color: TechColors.glowCyan, width: 1.5),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: TechColors.statusAlarm, size: 16),
                        const SizedBox(width: 6),
                        Text(error!,
                            style: TextStyle(
                                color: TechColors.statusAlarm, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('取消',
                    style: TextStyle(color: TechColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  final password = passwordController.text;
                  if (password.isEmpty) {
                    setDialogState(() => error = '请输入密码');
                    return;
                  }
                  if (password == _adminPassword ||
                      password == _operatorPassword) {
                    Navigator.of(context).pop(true);
                  } else {
                    setDialogState(() => error = '密码错误');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TechColors.glowCyan.withOpacity(0.2),
                  foregroundColor: TechColors.glowCyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side:
                        BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
                  ),
                ),
                child: const Text('登录'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      setState(() => _isLoggedIn = true);
    }
  }

  /// 退出登录
  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _selectedSection = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return _buildLoginScreen();
    }
    return _buildSettingsScreen();
  }

  /// 登录提示界面 (点击按钮弹窗登录)
  Widget _buildLoginScreen() {
    return Container(
      color: TechColors.bgDeep,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TechColors.glowCyan.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: TechColors.glowCyan.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.settings,
                size: 48,
                color: TechColors.glowCyan,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '系统设置',
              style: TextStyle(
                color: TechColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '需要登录才能访问设置页面',
              style: TextStyle(
                color: TechColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            // 点击登录按钮
            ElevatedButton.icon(
              onPressed: _showLoginDialog,
              icon: const Icon(Icons.login, size: 20),
              label: const Text('点击登录'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TechColors.glowCyan.withOpacity(0.2),
                foregroundColor: TechColors.glowCyan,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 密码提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TechColors.bgMedium.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: TechColors.borderDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      color: TechColors.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '管理员密码或操作员密码均可登录',
                    style: TextStyle(
                        color: TechColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 设置主界面
  Widget _buildSettingsScreen() {
    return Container(
      color: TechColors.bgDeep,
      child: Row(
        children: [
          // 左侧导航菜单
          _buildNavigationMenu(),
          // 右侧配置内容
          Expanded(
            child: _buildConfigContent(),
          ),
        ],
      ),
    );
  }

  /// 左侧导航菜单
  Widget _buildNavigationMenu() {
    final sections = [
      {'icon': Icons.info_outline, 'label': '系统信息'},
      {'icon': Icons.lock_outline, 'label': '密码管理'},
      {'icon': Icons.tune, 'label': '阈值设置'},
    ];

    return Container(
      width: 200,
      margin: const EdgeInsets.all(12),
      child: TechPanel(
        title: '设置菜单',
        accentColor: TechColors.glowCyan,
        child: Column(
          children: [
            // 菜单项列表
            ...List.generate(sections.length, (index) {
              final section = sections[index];
              final isSelected = _selectedSection == index;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSection = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TechColors.glowCyan.withOpacity(0.15)
                            : TechColors.bgMedium.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected
                              ? TechColors.glowCyan.withOpacity(0.5)
                              : TechColors.borderDark,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            section['icon'] as IconData,
                            size: 18,
                            color: isSelected
                                ? TechColors.glowCyan
                                : TechColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              section['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? TechColors.glowCyan
                                    : TechColors.textPrimary,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: TechColors.glowCyan,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            // 弹性空间
            const Spacer(),
            // 分隔线
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 1,
              color: TechColors.borderDark,
            ),
            // 退出登录按钮
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TechColors.statusAlarm.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: TechColors.statusAlarm.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        size: 18,
                        color: TechColors.statusAlarm,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '退出登录',
                          style: TextStyle(
                            color: TechColors.statusAlarm,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 退出程序按钮
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showExitConfirmDialog(),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TechColors.bgMedium.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: TechColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.close,
                        size: 18,
                        color: TechColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '退出程序',
                          style: TextStyle(
                            color: TechColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 退出程序确认对话框
  Future<void> _showExitConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TechColors.bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: TechColors.statusAlarm.withOpacity(0.5)),
        ),
        title: Text(
          '确认关闭',
          style: TextStyle(color: TechColors.textPrimary),
        ),
        content: Text(
          '确定要关闭应用程序吗？',
          style: TextStyle(color: TechColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '取消',
              style: TextStyle(color: TechColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TechColors.statusAlarm.withOpacity(0.2),
              foregroundColor: TechColors.statusAlarm,
            ),
            child: const Text('确认关闭'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await windowManager.close();
    }
  }

  /// 右侧配置内容区域
  Widget _buildConfigContent() {
    // 阈值设置需要特殊处理（使用 ThresholdSettingsWidget）
    if (_selectedSection == 2) {
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
        child: TechPanel(
          title: '阈值设置',
          accentColor: TechColors.glowOrange,
          child: ThresholdSettingsWidget(provider: _thresholdProvider),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: TechPanel(
        title: _getSectionTitle(),
        accentColor: TechColors.glowCyan,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildSectionContent(),
        ),
      ),
    );
  }

  String _getSectionTitle() {
    switch (_selectedSection) {
      case 0:
        return '系统信息';
      case 1:
        return '密码管理';
      case 2:
        return '阈值设置';
      default:
        return '系统设置';
    }
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 0:
        return _buildSystemInfo();
      case 1:
        return _buildPasswordManagement();
      default:
        return const SizedBox();
    }
  }

  /// 系统信息区域
  Widget _buildSystemInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          title: '应用信息',
          icon: Icons.apps,
          children: [
            _buildInfoRow('应用名称', '水泵房监控系统', Icons.label_outline),
            _buildInfoRow('版本', '1.0.0', Icons.tag),
            _buildInfoRow('运行平台', 'Windows', Icons.computer),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: '后端服务',
          icon: Icons.dns,
          children: [
            _buildInfoRow('服务地址', 'localhost', Icons.router),
            _buildInfoRow('端口', '8081', Icons.settings_ethernet),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: '密码状态',
          icon: Icons.security,
          children: [
            _buildInfoRow('管理员密码', '****** (不可修改)', Icons.admin_panel_settings),
            _buildInfoRow(
                '操作员密码',
                _operatorPassword == _defaultOperatorPassword ? '默认密码' : '已修改',
                Icons.person),
          ],
        ),
      ],
    );
  }

  /// 密码管理区域
  Widget _buildPasswordManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 说明信息
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TechColors.glowCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: TechColors.glowCyan.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: TechColors.glowCyan, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '管理员密码为固定密码，不可修改。\n操作员密码可在此处修改，用于日常登录。',
                  style: TextStyle(
                    color: TechColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 修改操作员密码
        Text(
          '修改操作员密码',
          style: TextStyle(
            color: TechColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: '当前密码',
          controller: _oldPasswordController,
          showPassword: _showOldPassword,
          onVisibilityToggle: () {
            setState(() => _showOldPassword = !_showOldPassword);
          },
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: '新密码',
          controller: _newPasswordController,
          showPassword: _showNewPassword,
          onVisibilityToggle: () {
            setState(() => _showNewPassword = !_showNewPassword);
          },
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          label: '确认新密码',
          controller: _confirmPasswordController,
          showPassword: _showConfirmPassword,
          onVisibilityToggle: () {
            setState(() => _showConfirmPassword = !_showConfirmPassword);
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _changePassword,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('确认修改'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TechColors.glowCyan.withOpacity(0.2),
                foregroundColor: TechColors.glowCyan,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _clearPasswordFields,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重置'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TechColors.textSecondary,
                side: BorderSide(color: TechColors.borderDark),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _resetToDefaultPassword,
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('恢复默认密码'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TechColors.statusWarning,
                side: BorderSide(
                    color: TechColors.statusWarning.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 修改密码逻辑
  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 验证输入
    if (oldPassword.isEmpty) {
      _showSnackBar('请输入当前密码', isError: true);
      return;
    }

    // 验证旧密码是否正确 (操作员密码或管理员密码)
    if (oldPassword != _operatorPassword && oldPassword != _adminPassword) {
      _showSnackBar('当前密码错误', isError: true);
      return;
    }

    if (newPassword.isEmpty) {
      _showSnackBar('请输入新密码', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('新密码长度至少6位', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('两次输入的新密码不一致', isError: true);
      return;
    }

    if (newPassword == _adminPassword) {
      _showSnackBar('新密码不能与管理员密码相同', isError: true);
      return;
    }

    // 保存新密码
    final success = await _saveOperatorPassword(newPassword);
    if (success) {
      _clearPasswordFields();
      _showSnackBar('密码修改成功', isError: false);
    } else {
      _showSnackBar('密码保存失败', isError: true);
    }
  }

  /// 恢复默认密码
  Future<void> _resetToDefaultPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TechColors.bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: TechColors.statusWarning.withOpacity(0.5)),
        ),
        title: Text(
          '恢复默认密码',
          style: TextStyle(color: TechColors.textPrimary),
        ),
        content: Text(
          '确定要将操作员密码恢复为默认密码 (water123) 吗？',
          style: TextStyle(color: TechColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '取消',
              style: TextStyle(color: TechColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TechColors.statusWarning.withOpacity(0.2),
              foregroundColor: TechColors.statusWarning,
            ),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _saveOperatorPassword(_defaultOperatorPassword);
      if (success) {
        _showSnackBar('已恢复默认密码', isError: false);
      }
    }
  }

  /// 清空密码输入框
  void _clearPasswordFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  /// 显示提示消息
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? TechColors.statusAlarm : TechColors.glowGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 信息卡片
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TechColors.glowCyan),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: TechColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// 信息行
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TechColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: TechColors.textPrimary,
              fontSize: 13,
              fontFamily: 'Roboto Mono',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 密码输入字段
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool showPassword,
    required VoidCallback onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock, size: 16, color: TechColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: TechColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !showPassword,
          style: TextStyle(
            color: TechColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Roboto Mono',
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: TechColors.bgMedium,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: TechColors.textSecondary,
              ),
              onPressed: onVisibilityToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.glowCyan, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
