package com.qr_tech.nlip

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.content.ComponentName
import android.provider.Settings
import androidx.appcompat.app.AlertDialog
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import android.view.Gravity
import android.os.Build
import android.app.PictureInPictureParams
import android.util.Rational
import android.os.Build.VERSION_CODES
import android.media.projection.MediaProjectionManager
import android.view.WindowManager
import android.view.View

class MainActivity : FlutterActivity() {
    private lateinit var apiUtils: ApiUtils

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        apiUtils = ApiUtils(flutterEngine)
        apiUtils.setupMethodCallHandler()
        NlipFxManager.install(application, apiUtils)
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