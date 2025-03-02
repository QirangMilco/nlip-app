import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nlip_app/src/rust/api/nlip_api.dart';
import 'package:nlip_app/src/rust/frb_generated.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nlip_app/api_service.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:nlip_app/window_utils.dart';
import 'package:nlip_app/hotkey_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 获取设置
  final prefs = await SharedPreferences.getInstance();
  final silentStart = prefs.getBool('silentStart') ?? false;
  
  // 设置窗口大小
  WindowUtils.setupWindow(silentStart);
  
  // 然后初始化 Rust 库
  await RustLib.init();

  await HotkeyUtils.initHotkey((hotkey) {
    debugPrint('upload hotkey pressed');
  }, (hotkey) {
    debugPrint('paste hotkey pressed');
  });
  
  // 设置 MethodChannel 处理器
  await ApiService.setupMethodChannel();
  
  runApp(const NlipApp());
}

class NlipApp extends StatelessWidget {
  const NlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF), // Apple 蓝色
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display', // Apple 字体
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF007AFF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        ),
      ),
      home: const SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TrayListener {
  final _prefs = SharedPreferences.getInstance();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();

  bool _isLoggedIn = false;
  String? _jwtToken;
  List<Map<String, dynamic>> _spacesList = [];
  String? _selectedSpaceId;
  bool _autoStart = false;
  bool _silentStart = false;
  bool _hideOnClose = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initTray();
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
          key: 'silentStart',
          checked: _silentStart,
          label: '静默启动',
          type: 'checkbox',
          onClick: (menuItem) {
            // setState(() {
            //   _silentStart = !_silentStart;
            // });
            // final prefs = await _prefs;
            // await prefs.setBool('silentStart', _silentStart);
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

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefs;
    setState(() {
      _serverUrlController.text = prefs.getString('serverUrl') ?? '';
      _usernameController.text = prefs.getString('username') ?? '';
      _tokenController.text = prefs.getString('token') ?? '';
      _jwtToken = prefs.getString('jwtToken') ?? '';
      _isLoggedIn = _jwtToken != null && _jwtToken!.isNotEmpty;
      _selectedSpaceId = prefs.getString('selectedSpaceId');
      _autoStart = prefs.getBool('autoStart') ?? false;
      _silentStart = prefs.getBool('silentStart') ?? false;
      _hideOnClose = prefs.getBool('hideOnClose') ?? false;
    });

    if (_isLoggedIn) {
      await _loadSpacesList();
      
      if (_selectedSpaceId != null) {
        bool spaceExists = _spacesList.any((space) => space['id'] == _selectedSpaceId);
        if (!spaceExists) {
          setState(() {
            _selectedSpaceId = null;
          });
        }
      }
    }
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
  }

  String solveUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'http://$url';
    }
    return url;
  }

  Future<void> _testConnection() async {
    try {
      final prefs = await _prefs;
      String serverUrl = _serverUrlController.text;
      serverUrl = solveUrl(serverUrl);
      
      await prefs.setString('serverUrl', serverUrl);
      await prefs.setString('username', _usernameController.text);
      await prefs.setString('token', _tokenController.text);

      final result = await login(
        serverUrl: serverUrl,
        username: _usernameController.text,
        token: _tokenController.text,
      );

      debugPrint('Connection result: $result');

      await prefs.setString('jwtToken', result.jwtToken);

      setState(() {
        _jwtToken = result.jwtToken;
        _isLoggedIn = _jwtToken != null && _jwtToken!.isNotEmpty;
      });

      if (_isLoggedIn) {
        await _loadSpacesList();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接成功')),
        );
      }
    } catch (e, stack) {
      debugPrint('Connection error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接异常: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadSpacesList() async {
    if (!_isLoggedIn) {
      return;
    }

    try {
      final prefs = await _prefs;
      final serverUrl = prefs.getString('serverUrl') ?? '';
      
      final response = await getSpacesList(
        serverUrl: serverUrl,
        token: _jwtToken!,
      );
      
      setState(() {
        _spacesList = response.spaces.map((space) => {
          'id': space.id,
          'name': space.name,
        }).toList();
      });
      
    } catch (e, stack) {
      debugPrint('Load spaces error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载空间列表失败: ${e.toString()}')),
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
    try {
      final prefs = await _prefs;
      final serverUrl = prefs.getString('serverUrl') ?? '';
      
      final response = await createSpace(
        serverUrl: serverUrl,
        token: _jwtToken!,
        name: spaceName,
      );
      
      // 创建成功后重新加载空间列表
      await _loadSpacesList();
      
      // 自动选择新创建的空间
      setState(() {
        _selectedSpaceId = response.space.id;
      });
      
      // 保存选择
      await prefs.setString('selectedSpaceId', response.space.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('空间"$spaceName"创建成功')),
        );
      }
    } catch (e, stack) {
      debugPrint('Create space error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建空间失败: ${e.toString()}')),
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
        // await windowManager.setAutoLaunch(value);
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
                  // 根据屏幕宽度调整布局
                  bool isWideScreen = constraints.maxWidth > 600;
                  
                  return Center(
                    child: Container(
                      width: isWideScreen ? 600 : constraints.maxWidth,
                      padding: const EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 服务器连接区域
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
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
                                        color: _isLoggedIn ? const Color(0xFFE3F2FD) : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isLoggedIn ? Icons.check_circle : Icons.error_outline,
                                            color: _isLoggedIn ? const Color(0xFF007AFF) : Colors.grey,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isLoggedIn ? '已登录' : '未登录',
                                            style: TextStyle(
                                              color: _isLoggedIn ? const Color(0xFF007AFF) : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // 空间选择区域
                            if (_isLoggedIn)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 32),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
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
                                        if (_spacesList.isNotEmpty)
                                          DropdownButtonFormField<String>(
                                            decoration: const InputDecoration(
                                              labelText: '选择空间',
                                              prefixIcon: Icon(Icons.folder),
                                            ),
                                            value: _selectedSpaceId,
                                            hint: const Text('请选择一个空间'),
                                            items: _spacesList.map((space) {
                                              return DropdownMenuItem<String>(
                                                value: space['id'],
                                                child: Text(space['name']),
                                              );
                                            }).toList(),
                                            onChanged: (value) async {
                                              if (value != null) {
                                                setState(() {
                                                  _selectedSpaceId = value;
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
                                  ),
                                ],
                              ),
                              
                            // 应用设置区域
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
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
                                    onChanged: (Platform.isWindows || Platform.isLinux || Platform.isMacOS) 
                                      ? _toggleAutoStart 
                                      : null,
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
                            ),
                            
                            // 快捷键设置区域
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
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
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildCustomTitleBar(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        WindowUtils.startWindowDrag();
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            // 左侧空白区域，用于拖拽
            Expanded(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            // 窗口控制按钮
            Row(
              children: [
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
          hoverColor: isClose ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.03),
          child: SizedBox(
            width: 40,
            height: 32,
            child: Icon(
              icon,
              size: 14, // 更小的图标
              color: isClose ? Colors.black54 : Colors.black45,
            ),
          ),
        ),
      ),
    );
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

