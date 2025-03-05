import 'package:flutter/services.dart';
import 'package:nlip_app/src/rust/api/nlip_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';


class ApiService {
  // 单例实例
  static final ApiService _instance = ApiService._internal();
  
  // 工厂构造函数返回单例实例
  factory ApiService() {
    return _instance;
  }
  
  // 私有构造函数
  ApiService._internal();
  
  // 方法通道
  static const MethodChannel _channel = MethodChannel('ApiChannel');
  
  // 私有成员变量
  String _serverUrl = "";
  String _token = "";
  String _selectedSpaceId = "";
  String _username = "";
  String _jwtToken = "";
  bool _isLoggedIn = false;
  List<Space> _spacesList = [];
  final _prefs = SharedPreferences.getInstance();
  
  // Getter方法
  String get serverUrl => _serverUrl;
  String get token => _token;
  String get selectedSpaceId => _selectedSpaceId;
  String get username => _username;
  String get jwtToken => _jwtToken;
  bool get isLoggedIn => _isLoggedIn;
  List<Space> get spacesList => _spacesList;

  // setter方法
  void setServerUrl(String serverUrl) {
    _serverUrl = serverUrl;
  }

  void setToken(String token) {
    _token = token;
  }

  void setSelectedSpaceId(String selectedSpaceId) {
    _selectedSpaceId = selectedSpaceId;
  } 

  void setUsername(String username) {
    _username = username;
  }

  void setJwtToken(String jwtToken) {
    _jwtToken = jwtToken;
    _isLoggedIn = jwtToken.isNotEmpty;
  }



  void setSpacesList(List<Space> spacesList) {
    _spacesList = spacesList;
  }

  // 初始化方法
  Future<void> init() async {
    final prefs = await _prefs;
    _serverUrl = prefs.getString('serverUrl') ?? "";
    _token = prefs.getString('token') ?? "";
    _selectedSpaceId = prefs.getString('selectedSpaceId') ?? "";
    _username = prefs.getString('username') ?? "";
    _jwtToken = prefs.getString('jwtToken') ?? "";
    _isLoggedIn = _jwtToken.isNotEmpty;
    
    debugPrint('初始化 ApiService: isLoggedIn=$_isLoggedIn, serverUrl=$_serverUrl, username=$_username');
    
    if (_isLoggedIn) {
      try {
        await apiGetSpacesList();
        debugPrint('初始化后空间列表数量: ${_spacesList.length}');

        if (_selectedSpaceId.isNotEmpty) {
          bool spaceExists = _spacesList.any((space) => space.id == _selectedSpaceId);
          if (!spaceExists && _spacesList.isNotEmpty) {
            debugPrint('所选空间不存在，选择第一个可用空间');
            setSelectedSpaceId(_spacesList.first.id);
            final prefs = await _prefs;
            await prefs.setString('selectedSpaceId', _spacesList.first.id);
          } else if (!spaceExists) {
            debugPrint('所选空间不存在，重置选择');
            setSelectedSpaceId("");
          }
        } else if (_spacesList.isNotEmpty) {
          // 如果没有选择空间但有可用空间，选择第一个
          debugPrint('未选择空间，选择第一个可用空间');
          setSelectedSpaceId(_spacesList.first.id);
          final prefs = await _prefs;
          await prefs.setString('selectedSpaceId', _spacesList.first.id);
        }
      } catch (e) {
        debugPrint('初始化获取空间列表失败: $e');
      }
    }
  }

  // 设置方法通道处理器
  Future<void> setupMethodChannel() async {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'getLastClip':
          final content = await apiGetLastClip();
          return content;
        case 'uploadTextClip':
          final content = call.arguments['content'] as String;
          final result = await apiUploadClip(content);
          return result;
        default:
          throw PlatformException(
            code: 'NOT_IMPLEMENTED',
            message: '未实现的方法: ${call.method}',
          );
      }
    });
  }
  
  // API方法封装
  Future<bool> apiLogin() async {
    if (_serverUrl == "" || _username == "" || _token == "") {
      return false;
    }

    try {
      final result = await login(
        serverUrl: _serverUrl,
        username: _username,
        token: _token,
      );
       debugPrint('Connection result: $result');

       
      final prefs = await _prefs;
      await prefs.setString('jwtToken', result.jwtToken);
      setJwtToken(result.jwtToken);

      if (_isLoggedIn) {
        await apiGetSpacesList();
      }
      return _isLoggedIn;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  String solveUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'http://$url';
    }
    return url;
  }

  Future<bool> testConnection(String serverUrl, String username, String token) async {
    final prefs = await _prefs;
    serverUrl = solveUrl(serverUrl);
    await prefs.setString('serverUrl', serverUrl);
    await prefs.setString('username', username);
    await prefs.setString('token', token);
    setServerUrl(serverUrl);
    setUsername(username);
    setToken(token);

    final result = await apiLogin();
    return result;
  }

  Future<void> apiGetSpacesList() async {
    if (!_isLoggedIn) {
      return;
    }

    try {
      final response = await getSpacesList(
        serverUrl: _serverUrl,
        token: _jwtToken,
      );

      debugPrint('获取到空间列表: ${response.spaces.length}个空间');
      for (var space in response.spaces) {
        debugPrint('空间: ${space.id} - ${space.name}');
      }
      
      setSpacesList(response.spaces);
      
    } catch (e, stack) {
      debugPrint('Load spaces error: $e\n$stack');
    }
  }

  Future<bool> apiCreateSpace(String spaceName) async {
    if (!_isLoggedIn) {
      return false;
    }

    try {
      final response = await createSpace(
        serverUrl: _serverUrl,
        token: _jwtToken,
        name: spaceName,
      );
      await apiGetSpacesList();
      setSelectedSpaceId(response.space.id);
      final prefs = await _prefs;
      await prefs.setString('selectedSpaceId', response.space.id);
    } catch (e) {
      debugPrint('Create space error: $e');
      return false;
    }
    return true;
  }

  Future<bool> apiUploadClip(String content) async {
    if (!_isLoggedIn) {
      return false;
    }
    
    try {
      final response = await uploadTextClip(
        serverUrl: _serverUrl,
        token: _jwtToken,
        spaceId: _selectedSpaceId,
        content: content,
      );
      return response.clip.id != "";
    } catch (e) {
      debugPrint('Upload clip error: $e');
      return false;
    }
  }

  Future<String> apiGetLastClip() async {
    if (!_isLoggedIn) {
      return "";
    }
    
    try {
      final response = await getLastClip(
        serverUrl: _serverUrl,
        token: _jwtToken,
        spaceId: _selectedSpaceId,
      );
      if (response.clip.contentType != "text/plain") {
        return "";
      }
      return response.clip.content;
    } catch (e) {
      debugPrint('Get last clip error: $e');
      return "";
    }
  }

  Future<void> apiPasteTextFromNlip() async {
    if (!_isLoggedIn) {
      return;
    }
    try {
      await pasteTextFromNlip(
        serverUrl: _serverUrl,
        token: _jwtToken,
        spaceId: _selectedSpaceId,
      );
    } catch (e) {
      debugPrint('Paste text from nlip error: $e');
    }
  }

  Future<void> apiUploadSelectedTextToNlip() async {
    if (!_isLoggedIn) {
      return;
    }
    try {
      await uploadSelectedTextToNlip(
        serverUrl: _serverUrl,
        token: _jwtToken,
        spaceId: _selectedSpaceId,
      );
    } catch (e) {
      debugPrint('Upload selected text to nlip error: $e');
    }
  }
}
