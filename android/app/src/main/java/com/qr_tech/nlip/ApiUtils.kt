package com.qr_tech.nlip

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import android.util.Log

/**
 * 用于与 Flutter/Rust 层通信的工具类
 */
class ApiUtils(flutterEngine: FlutterEngine) {
    private val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ApiChannel")
    private val tag = "ApiUtils"

    /**
     * 获取最近的 Clip
     * @return 返回最近的 Clip 内容，如果出错则返回空字符串
     */
    suspend fun getLastClip(): String = withContext(Dispatchers.IO) {
        try {
            val result = methodChannel.invokeMethod<String>("getLastClip", null)
            Log.d(tag, "获取最近 Clip 成功: $result")
            return@withContext result ?: ""
        } catch (e: Exception) {
            Log.e(tag, "获取最近 Clip 失败", e)
            return@withContext ""
        }
    }

    /**
     * 上传文本类型的 Clip
     * @param content 要上传的文本内容
     * @return 上传是否成功
     */
    suspend fun uploadTextClip(content: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val result = methodChannel.invokeMethod<Boolean>("uploadTextClip", mapOf("content" to content))
            Log.d(tag, "上传文本 Clip ${if (result == true) "成功" else "失败"}")
            return@withContext result ?: false
        } catch (e: Exception) {
            Log.e(tag, "上传文本 Clip 失败", e)
            return@withContext false
        }
    }

    /**
     * 设置 MethodChannel 的处理器
     * 这个方法应该在 MainActivity 中调用，用于处理来自 Flutter 的调用
     */
    fun setupMethodCallHandler() {
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAndroid" -> {
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

