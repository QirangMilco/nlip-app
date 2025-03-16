import 'package:flutter/material.dart';
import 'package:nlip_app/api_service.dart';
import 'package:nlip_app/hotkey_utils.dart';
import 'package:nlip_app/window_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DesktopApp extends StatefulWidget {
  const DesktopApp({super.key});
  
  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> with TrayListener {
  final _prefs = SharedPreferences.getInstance();
  final _apiService = ApiService();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();

  bool _autoStart = false;
  bool _silentStart = false;
  bool _hideOnClose = false;
  bool _isAlwaysOnTop = false;
  
  @override
  void initState() {
    super.initState();
    _apiService.init().then((_) {
      _apiService.setupMethodChannel();
      _initDesktopApp();
      _initTray();
      _refreshSpacesList();
      _checkAlwaysOnTopStatus();
      // 确保热键信息在UI初始化时已加载
      setState(() {});
    });
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() {
    WindowUtils.showWindow();
    WindowUtils.focusWindow();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'exit')
     {
      WindowUtils.closeWindow();
    }
    if (menuItem.key == 'silentStart') {
      setState(() {
        _silentStart = menuItem.checked ?? false;
      });
      final prefs = await _prefs;
      await prefs.setBool('silentStart', _silentStart);
    }
    if (menuItem.key == 'autoStart') {
      setState(() {
        _autoStart = menuItem.checked ?? false;
      });
      final prefs = await _prefs;
      await prefs.setBool('autoStart', _autoStart);
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        if (_autoStart) {
          await launchAtStartup.enable();
        }
        else {
          await launchAtStartup.disable();
        }
      }
    }
  }
  
  Future<void> _initDesktopApp() async {
    final prefs = await _prefs;
    setState(() {
      _serverUrlController.text = _apiService.serverUrl;
      _usernameController.text = _apiService.username;
      _tokenController.text = _apiService.token;
      _autoStart = prefs.getBool('autoStart') ?? false;
      _silentStart = prefs.getBool('silentStart') ?? false;
      _hideOnClose = prefs.getBool('hideOnClose') ?? false;
    });
    // 初始化桌面端特有功能
    await WindowUtils.setupWindow(_silentStart);
    await HotkeyUtils.initHotkey(_onUploadHotkey, _onPasteHotkey);
    
    await _initLaunchAtStartup(_autoStart);
    
    // 确保热键设置后UI更新
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initLaunchAtStartup(_autoStart) async {
    final packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
      packageName: 'com.qr_tech.nlip',
    );
    if (_autoStart) {
      launchAtStartup.enable();
    }
    else {
      launchAtStartup.disable();
    }
  }
  
  Future<void> _refreshSpacesList() async {
    if (_apiService.isLoggedIn) {
      await _apiService.apiGetSpacesList();
      if (mounted) {
        setState(() {
          // 强制刷新UI以显示更新的空间列表
        });
      }
    }
  }

  void _onUploadHotkey(NlipHotKey hotkey) async {
    await _apiService.apiUploadSelectedTextToNlip();
    // 可能需要更新UI以反映操作结果
    if (mounted) {
      setState(() {});
    }
  }
  
  void _onPasteHotkey(NlipHotKey hotkey) async {
    await _apiService.apiPasteTextFromNlip();
    // 可能需要更新UI以反映操作结果
    if (mounted) {
      setState(() {});
    }
  }

  void _initTray() async {
    await trayManager.setIcon(
      Platform.isWindows 
      ? 'assets/favicon.ico' 
      : 'assets/logo.png'
    );
    await trayManager.setToolTip('Nlip');
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'autoStart',
          checked: _autoStart,
          label: '开机自启',
          type: 'checkbox',
          onClick: (menuItem) {
            menuItem.checked = !(menuItem.checked ?? false);
          },
        ),
        MenuItem(
          key: 'silentStart',
          checked: _silentStart,
          label: '静默启动',
          type: 'checkbox',
          onClick: (menuItem) {
            menuItem.checked = !(menuItem.checked ?? false);
          },
        ),
        MenuItem(
          key: 'exit',
          label: '退出',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
  }

  Future<void> _testConnection() async {
    final result = await _apiService.testConnection(
      _serverUrlController.text,
      _usernameController.text,
      _tokenController.text,
    );
    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接成功')),
        );
        // 连接成功后刷新空间列表
        await _refreshSpacesList();
        // 确保UI更新以显示登录状态变化
        setState(() {});
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败')),
        );
      }
    }
  }

  Future<void> _showCreateSpaceDialog() async {
    final TextEditingController spaceNameController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('新建空间', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: spaceNameController,
                  decoration: const InputDecoration(
                    labelText: '空间名称',
                    prefixIcon: Icon(Icons.drive_file_rename_outline),
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (spaceNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('空间名称不能为空')),
                        );
                        return;
                      }
                      
                      Navigator.of(context).pop();
                      await _createNewSpace(spaceNameController.text);
                    },
                    child: const Text(
                      '确定创建',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewSpace(String spaceName) async {
    final result = await _apiService.apiCreateSpace(spaceName);
    if (mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('空间"$spaceName"创建成功')),
        );
        // 创建成功后刷新空间列表
        await _refreshSpacesList();
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('空间"$spaceName"创建失败')),
        );
      }
    }
  }

  Future<void> _toggleAutoStart(bool value) async {
    final prefs = await _prefs;
    setState(() {
      _autoStart = value;
    });
    await prefs.setBool('autoStart', value);
    
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        if (value) {
          await launchAtStartup.enable();
        }
        else {
          await launchAtStartup.disable();
        }
      }
    } catch (e) {
      debugPrint('Error setting auto launch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置开机自启失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleSilentStart(bool value) async {
    final prefs = await _prefs;
    setState(() {
      _silentStart = value;
    });
    await prefs.setBool('silentStart', value);
  }

  Future<void> _toggleHideOnClose(bool value) async {
    final prefs = await _prefs;
    setState(() {
      _hideOnClose = value;
    });
    await prefs.setBool('hideOnClose', value);
  }
  
  Future<void> _checkAlwaysOnTopStatus() async {
    try {
      final isOnTop = await WindowUtils.isAlwaysOnTop();
      if (mounted) {
        setState(() {
          _isAlwaysOnTop = isOnTop;
        });
      }
    } catch (e) {
      debugPrint('Error checking always on top status: $e');
    }
  }

  Future<void> _toggleAlwaysOnTop() async {
    try {
      final newState = !_isAlwaysOnTop;
      await WindowUtils.setAlwaysOnTop(newState);
      if (mounted) {
        setState(() {
          _isAlwaysOnTop = newState;
        });
      }
    } catch (e) {
      debugPrint('Error toggling always on top: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isWindows = Theme.of(context).platform == TargetPlatform.windows;
    
    return Scaffold(
      appBar: isWindows ? null : AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        toolbarHeight: 0, // 移除标准标题栏
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isWindows)
              _buildCustomTitleBar(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 双栏布局的最小宽度
                  const double minWidthForTwoColumns = 900;
                  bool useTwoColumns = constraints.maxWidth >= minWidthForTwoColumns;
                  
                  return Center(
                    child: Container(
                      width: useTwoColumns ? 900 : constraints.maxWidth,
                      padding: const EdgeInsets.all(24.0),
                      child: useTwoColumns
                          ? _buildTwoColumnLayout()
                          : _buildSingleColumnLayout(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧栏 - 服务器连接和空间选择
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 服务器连接区域
                _buildServerConnectionSection(),
                
                // 空间选择区域
                if (_apiService.isLoggedIn)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      _buildSpaceManagementSection(),
                    ],
                  ),
              ],
            ),
          ),
        ),
        
        // 中间间隔
        const SizedBox(width: 24),
        
        // 右侧栏 - 应用设置和快捷键设置
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 应用设置区域
                _buildAppSettingsSection(),
                
                // 快捷键设置区域
                const SizedBox(height: 32),
                _buildHotkeySettingsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 服务器连接区域
          _buildServerConnectionSection(),
          
          // 空间选择区域
          if (_apiService.isLoggedIn)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                _buildSpaceManagementSection(),
              ],
            ),
            
          // 应用设置区域
          const SizedBox(height: 32),
          _buildAppSettingsSection(),
          
          // 快捷键设置区域
          const SizedBox(height: 32),
          _buildHotkeySettingsSection(),
        ],
      ),
    );
  }

  Widget _buildServerConnectionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '服务器连接',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _serverUrlController,
            decoration: const InputDecoration(
              labelText: '服务器URL',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Token',
              prefixIcon: Icon(Icons.vpn_key),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _testConnection,
            child: const Text('测试连接'),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: _apiService.isLoggedIn ? const Color(0xFFE3F2FD) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _apiService.isLoggedIn ? Icons.check_circle : Icons.error_outline,
                    color: _apiService.isLoggedIn ? const Color(0xFF007AFF) : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _apiService.isLoggedIn ? '已登录' : '未登录',
                    style: TextStyle(
                      color: _apiService.isLoggedIn ? const Color(0xFF007AFF) : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceManagementSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '空间管理',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF007AFF)),
                tooltip: '新建空间',
                onPressed: _showCreateSpaceDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_apiService.spacesList.isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '选择空间',
                prefixIcon: Icon(Icons.folder),
              ),
              value: _apiService.selectedSpaceId.isNotEmpty && 
                    _apiService.spacesList.any((space) => space.id == _apiService.selectedSpaceId) 
                    ? _apiService.selectedSpaceId 
                    : null,
              hint: const Text('请选择一个空间'),
              items: _apiService.spacesList.map((space) {
                return DropdownMenuItem<String>(
                  value: space.id,
                  child: Text(space.name),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  setState(() {
                    _apiService.setSelectedSpaceId(value);
                  });
                  final prefs = await _prefs;
                  await prefs.setString('selectedSpaceId', value);
                }
              },
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '暂无可用空间，请点击右上角"+"创建',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '应用设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('开机自启'),
            subtitle: const Text('应用将在系统启动时自动运行'),
            value: _autoStart,
            activeColor: const Color(0xFF007AFF),
            onChanged: _toggleAutoStart,
            secondary: const Icon(Icons.power_settings_new),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('静默启动'),
            subtitle: const Text('应用启动时不显示主窗口'),
            value: _silentStart,
            activeColor: const Color(0xFF007AFF),
            onChanged: _toggleSilentStart,
            secondary: const Icon(Icons.visibility_off),
          ),
          const Divider(),
           SwitchListTile(
            title: const Text('最小化到托盘'),
            subtitle: const Text('应用退出时最小化到托盘'),
            value: _hideOnClose,
            activeColor: const Color(0xFF007AFF),
            onChanged: _toggleHideOnClose,
            secondary: const Icon(Icons.visibility_off),
          ),
        ],
      ),
    );
  }

  Widget _buildHotkeySettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷键设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHotkeyRow(
            label: '上传',
            description: '将选中的文本上传到Nlip',
            icon: Icons.upload_file,
            hotkey: HotkeyUtils.getUploadHotKey(),
            onHotkeyRecorded: (hotkey) {
              HotkeyUtils.updateUploadHotkey(hotkey);
            },
          ),
          const Divider(),
          _buildHotkeyRow(
            label: '粘贴',
            description: '从Nlip粘贴内容',
            icon: Icons.content_paste,
            hotkey: HotkeyUtils.getPasteHotKey(),
            onHotkeyRecorded: (hotkey) {
              HotkeyUtils.updatePasteHotkey(hotkey);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTitleBar(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        WindowUtils.startWindowDrag();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // 标题栏
            SizedBox(
              height: 90,
              child: Row(
                children: [
                  // 左侧Logo和标题
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: 48,
                          height: 48,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Nlip',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 中间空白区域，用于拖拽
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                  Column(
                    children: [
                      // 窗口控制按钮
                      Row(
                        children: [
                          _buildWindowButton(
                            icon: _isAlwaysOnTop ? PhosphorIcons.pushPin(PhosphorIconsStyle.fill) : PhosphorIcons.pushPin(PhosphorIconsStyle.regular),
                            onPressed: () => _toggleAlwaysOnTop(),
                            tooltip: '置顶',
                          ),
                          _buildWindowButton(
                            icon: Icons.remove,
                            onPressed: () => WindowUtils.minimizeWindow(),
                            tooltip: '最小化',
                          ),
                          _buildWindowButton(
                            icon: Icons.crop_square_outlined,
                            onPressed: () => WindowUtils.maximizeWindow(),
                            tooltip: '最大化',
                          ),
                          _buildWindowButton(
                          icon: Icons.close,
                          onPressed: () => _hideOnClose ? WindowUtils.hideWindow() : WindowUtils.closeWindow(),
                          tooltip: '关闭',
                          isClose: true,
                          ),
                        ],
                      ),
                      // 链接图标行
                      Row(               
                        children: [
                          _buildLinkButton(
                            icon: Icons.language,
                            onPressed: () => _launchUrl(_apiService.serverUrl),
                            tooltip: '进入网页端',
                          ),
                          _buildLinkButton(
                            icon: FontAwesomeIcons.github,
                            onPressed: () => _launchUrl('https://github.com/QirangMilco/nlip'),
                            tooltip: '打开Nlip项目',
                          ),
                          _buildLinkButton(
                            icon: Icons.app_shortcut,
                            onPressed: () => _launchUrl('https://github.com/QirangMilco/nlip-app'),
                            tooltip: '打开nlip_app项目',
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isClose = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: isClose ? Colors.red.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
          child: SizedBox(
            width: 40,
            height: 48,
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF007AFF),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: Colors.black.withValues(alpha: 0.03),
          child: SizedBox(
            width: 40,
            height: 36,
            child: Icon(
              icon,
              size: 22,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接: $url')),
        );
      }
    }
  }

  Widget _buildHotkeyRow({
    required String label,
    required String description,
    required IconData icon,
    required NlipHotKey? hotkey,
    required Function(NlipHotKey) onHotkeyRecorded,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (hotkey != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                HotkeyUtils.formatHotkey(hotkey),
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),

            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await HotkeyUtils.handleClickRegisterHotkey(context, (newHotkey) {
                // Call the original callback
                onHotkeyRecorded(newHotkey);
                // Force UI refresh to show the updated hotkey
                setState(() {});
              });
            },
            child: const Text(
              '修改',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 