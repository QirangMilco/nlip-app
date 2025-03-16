import 'package:flutter/material.dart';
import 'package:nlip_app/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileApp extends StatefulWidget {
  const MobileApp({super.key});
  
  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  final _prefs = SharedPreferences.getInstance();
  final _apiService = ApiService();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService.init().then((_) {
      _apiService.setupMethodChannel();
      _initMobileApp();
      _refreshSpacesList();
      // 确保热键信息在UI初始化时已加载
      setState(() {});
    });
  }

  Future<void> _initMobileApp() async {
    setState(() {
      _serverUrlController.text = _apiService.serverUrl;
      _usernameController.text = _apiService.username;
      _tokenController.text = _apiService.token;
    });
    
    // 确保热键设置后UI更新
    if (mounted) {
      setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  // 标题栏
                  _buildLogo(),

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
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          const SizedBox(height: 50),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 64,
                  height: 64,
                ),
                const SizedBox(width: 15),
                const Text(
                  'Nlip',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
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
} 