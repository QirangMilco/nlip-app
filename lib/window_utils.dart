import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

class WindowUtils {
  static Future<void> initWindowUtils(WindowListener listener) async {
    await addListener(listener);
    await windowManager.setPreventClose(true);
  }

  static Future<void> addListener(WindowListener listener) async {
    windowManager.addListener(listener);
  }

  static Future<void> removeListener(WindowListener listener) async {
    windowManager.removeListener(listener);
  }

  static Future<bool> isPreventClose() async {
    return await windowManager.isPreventClose();
  }

  static Future<void> setupWindow(bool silentStart) async {
    try {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await windowManager.ensureInitialized();

        WindowOptions windowOptions = const WindowOptions(
          size: Size(950, 750),
          minimumSize: Size(900, 700),
          title: 'Nlip',
          titleBarStyle: TitleBarStyle.hidden,
          center: true,
        );
      
        await windowManager.waitUntilReadyToShow(windowOptions, () async {
          if (!silentStart) {
            await windowManager.show();
            await windowManager.focus();
          }
        });
      }
    } catch (e) {
      debugPrint('Error ensuring window initialized: $e');
    }
  }

  static Future<void> startWindowDrag() async {
    try {
      await windowManager.startDragging();
    } catch (e) {
      debugPrint('Error starting window drag: $e');
    }
  }

  static Future<void> minimizeWindow() async {
    try {
      await windowManager.minimize();
    } catch (e) {
      debugPrint('Error minimizing window: $e');
    }
  }

  static Future<void> maximizeWindow() async {
    try {
      final isMaximized = await windowManager.isMaximized();
      if (isMaximized) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (e) {
      debugPrint('Error maximizing window: $e');
    }
  }

  static Future<void> closeWindow() async {
    try {
      await windowManager.close();
    } catch (e) {
      debugPrint('Error closing window: $e');
    }
  }

  static Future<bool> isAlwaysOnTop() async {
    return await windowManager.isAlwaysOnTop();
  }

  static Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    try {
      await windowManager.setAlwaysOnTop(alwaysOnTop);
    } catch (e) {
      debugPrint('Error setting always on top: $e');
    }
  }

  static Future<void> toggleAlwaysOnTop() async {
    try {
      final isAlwaysOnTop = await windowManager.isAlwaysOnTop();
      if (isAlwaysOnTop) {
        await windowManager.setAlwaysOnTop(false);
      } else {
        await windowManager.setAlwaysOnTop(true);
      }
    } catch (e) {
      debugPrint('Error toggling always on top: $e');
    }
  }

  static Future<void> hideWindow() async {
    try {
      await windowManager.hide();
    } catch (e) {
      debugPrint('Error hiding window: $e');
    }
  }

  static Future<void> showWindow() async {
    try {
      await windowManager.show();
    } catch (e) {
      debugPrint('Error showing window: $e');
    }
  }

  static Future<void> focusWindow() async {
    try {
      await windowManager.focus();
    } catch (e) {
      debugPrint('Error focusing window: $e');
    }
  }
}
