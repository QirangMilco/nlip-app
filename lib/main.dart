import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nlip_app/src/rust/frb_generated.dart';
import 'package:nlip_app/platform/desktop_app.dart';
import 'package:nlip_app/platform/mobile_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 然后初始化 Rust 库
  await RustLib.init();
  
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
      home: Platform.isAndroid || Platform.isIOS 
      ? const MobileApp() 
      : const DesktopApp(),
    );
  }
}