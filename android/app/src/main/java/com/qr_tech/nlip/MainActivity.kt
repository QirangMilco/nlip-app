package com.qr_tech.nlip

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.content.ComponentName
import android.provider.Settings
import androidx.appcompat.app.AlertDialog
import android.content.Intent
import android.content.ClipboardManager
import android.util.Log

class MainActivity : FlutterActivity() {
    private lateinit var apiUtils: ApiUtils

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            //获取剪切板文字逻辑写到这里。
            Log.d("NlipClipoard", "已获取焦点")
            val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
            val clip = clipboard.getPrimaryClip()
            if (clip != null && clip.getItemCount() > 0) {
                val text = clip.getItemAt(0).text.toString()
                Log.d("NlipClipboard", "当前剪贴板内容: $text")
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        apiUtils = ApiUtils(flutterEngine)
        apiUtils.setupMethodCallHandler()
    }


    private fun checkAccessibilityService() {
        val serviceName = ComponentName(this, TextSelectionService::class.java)
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )

        if (enabledServices == null || !enabledServices.contains(serviceName.flattenToString())) {
            AlertDialog.Builder(this)
                .setTitle("需要无障碍权限")
                .setMessage("请开启文本获取服务以使用选中文本功能")
                .setPositiveButton("去开启") { _, _ ->
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                }
                .setCancelable(false)
                .show()
        }
    }
} 