import 'package:flutter/services.dart';
import 'package:nlip_app/src/rust/api/nlip_api.dart';

class ApiService {
  static const MethodChannel _channel = MethodChannel('ApiChannel');
  
  static String serverUrl = "";
  static String token = "";
  static String spaceId = "";

  static Future<void> setupMethodChannel() async {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'getLastClip':
          try {
            // 调用 Rust 函数获取最近的 Clip
            final clipContent = await getLastClip(
              serverUrl: serverUrl,
              token: token,
              spaceId: spaceId,
            );
            return clipContent;
          } catch (e) {
            throw PlatformException(
              code: 'GET_LAST_CLIP_ERROR',
              message: e.toString(),
            );
          }
        case 'uploadTextClip':
          try {
            final content = call.arguments['content'] as String;
            // 调用 Rust 函数上传文本 Clip
            final success = await uploadTextClip(
              serverUrl: serverUrl,
              token: token,
              spaceId: spaceId,
              content: content,
            );
            return success;
          } catch (e) {
            throw PlatformException(
              code: 'UPLOAD_TEXT_CLIP_ERROR',
              message: e.toString(),
            );
          }
        default:
          throw PlatformException(
            code: 'NOT_IMPLEMENTED',
            message: '未实现的方法: ${call.method}',
          );
      }
    });
  }
}
