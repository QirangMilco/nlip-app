import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

typedef NlipHotKey = HotKey;
typedef NlipHotKeyRecorder = HotKeyRecorder;

class HotkeyUtils {
  static NlipHotKey? _uploadHotKey, _pasteHotKey;
  static Function(NlipHotKey)? _onUploadCallback;
  static Function(NlipHotKey)? _onPasteCallback;

  static Future<void> unregisterAllHotkeys() async {
    await hotKeyManager.unregisterAll();
  }

  static Future<void> initHotkey(onUpload, onPaste) async {
    await unregisterAllHotkeys();
    
    _onUploadCallback = onUpload;
    _onPasteCallback = onPaste;
    
    // 从 SharedPreferences 加载保存的快捷键
    final prefs = await SharedPreferences.getInstance();
    final uploadHotkeyJson = prefs.getString('uploadHotkey');
    final pasteHotkeyJson = prefs.getString('pasteHotkey');
    
    if (uploadHotkeyJson != null) {
      try {
        _uploadHotKey = _hotkeyFromJson(uploadHotkeyJson);
      } catch (e) {
        // 如果解析失败，使用默认快捷键
        _uploadHotKey = NlipHotKey(
          key: PhysicalKeyboardKey.keyC,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.system
        );
      }
    } else {
      // 默认快捷键
      _uploadHotKey = NlipHotKey(
        key: PhysicalKeyboardKey.keyC,
        modifiers: [HotKeyModifier.alt],
        scope: HotKeyScope.system
      );
    }
    
    if (pasteHotkeyJson != null) {
      try {
        _pasteHotKey = _hotkeyFromJson(pasteHotkeyJson);
      } catch (e) {
        // 如果解析失败，使用默认快捷键
        _pasteHotKey = NlipHotKey(
          key: PhysicalKeyboardKey.keyV,
          modifiers: [HotKeyModifier.alt],
          scope: HotKeyScope.system
        );
      }
    } else {
      // 默认快捷键
      _pasteHotKey = NlipHotKey(
        key: PhysicalKeyboardKey.keyV,
        modifiers: [HotKeyModifier.alt],
        scope: HotKeyScope.system
      );
    }
    
    // 注册快捷键
    await hotKeyManager.register(
      _uploadHotKey!,
      keyDownHandler: _onUploadCallback,
    );
    
    await hotKeyManager.register(
      _pasteHotKey!,
      keyDownHandler: _onPasteCallback,
    );
  }
  
  static NlipHotKey? getUploadHotKey() {
    return _uploadHotKey;
  }

  static String getUploadHotKeyString() {
    return formatHotkey(_uploadHotKey!);
  }
  
  static NlipHotKey? getPasteHotKey() {
    return _pasteHotKey;
  }

  static String getPasteHotKeyString() {
    return formatHotkey(_pasteHotKey!);
  }

  static Future<void> updateUploadHotkey(NlipHotKey hotKey) async {
    await hotKeyManager.unregister(_uploadHotKey!);
    
    _uploadHotKey = hotKey;
    
    await hotKeyManager.register(
      _uploadHotKey!,
      keyDownHandler: _onUploadCallback,
    );
    
    // 保存到 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uploadHotkey', _hotkeyToJson(hotKey));
  }
  
  static Future<void> updatePasteHotkey(NlipHotKey hotKey) async {
    await hotKeyManager.unregister(_pasteHotKey!);
    
    _pasteHotKey = hotKey;
    
    await hotKeyManager.register(
      _pasteHotKey!,
      keyDownHandler: _onPasteCallback,
    );
    
    // 保存到 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pasteHotkey', _hotkeyToJson(hotKey));
  }
  
  // 将 NlipHotKey 转换为 JSON 字符串
  static String _hotkeyToJson(NlipHotKey hotKey) {
    final Map<String, dynamic> json = hotKey.toJson();
    return jsonEncode(json);
  }
  
  // 从 JSON 字符串解析 NlipHotKey
  static NlipHotKey _hotkeyFromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    
    return NlipHotKey.fromJson(json);
  }

  static String formatHotkey(NlipHotKey hotkey) {
    final List<String> parts = [];
    
    if (hotkey.modifiers != null) {
      for (final modifier in hotkey.modifiers!) {
        switch (modifier) {
          case HotKeyModifier.alt:
            parts.add('Alt');
            break;
          case HotKeyModifier.control:
            parts.add('Ctrl');
            break;
          case HotKeyModifier.shift:
            parts.add('Shift');
            break;
          case HotKeyModifier.meta:
            parts.add(Platform.isMacOS ? 'Command' : 'Win');
            break;
          case HotKeyModifier.capsLock:
            parts.add('CapsLock');
            break;
          default:
            parts.add(modifier.toString().split('.').last);
            break;
        }
      }
    }
    
    // 添加主键
    parts.add(hotkey.key.keyLabel);
    
    return parts.join(' + ');
  }

  static Future<void> handleClickRegisterHotkey(BuildContext context, Function(NlipHotKey) onHotKeyRecorded) async {
    return showDialog<void>(
      context: context,
      builder: (context) => RecordHotKeyDialog(
        onHotKeyRecorded: onHotKeyRecorded,
      ),
    );
  }
}

class RecordHotKeyDialog extends StatefulWidget {
  const RecordHotKeyDialog({
    super.key,
    required this.onHotKeyRecorded,
  });

  final ValueChanged<NlipHotKey> onHotKeyRecorded;

  @override
  State<RecordHotKeyDialog> createState() => _RecordHotKeyDialogState();
}

class _RecordHotKeyDialogState extends State<RecordHotKeyDialog> {
  NlipHotKey? _hotKey;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        '设置快捷键',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '请按下您想要设置的快捷键组合',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hotKey != null 
                      ? const Color(0xFF007AFF) 
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  HotKeyRecorder(
                    onHotKeyRecorded: (hotKey) {
                      setState(() {
                        _hotKey = hotKey;
                      });
                    },
                  ),
                  if (_hotKey == null)
                    const Text(
                      '点击此处并按下快捷键',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (_hotKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF007AFF), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '已记录: ${HotkeyUtils.formatHotkey(_hotKey!)}',
                      style: const TextStyle(
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
                onPressed: _hotKey == null
                    ? null
                    : () {
                        widget.onHotKeyRecorded(_hotKey!);
                        Navigator.of(context).pop();
                      },
                child: const Text(
                  '确定',
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
  }
}