package com.qr_tech.nlip

import android.service.quicksettings.TileService
import android.content.Intent
import android.util.Log
import android.app.PendingIntent
import android.os.Build

class QuickTileService : TileService() {
    override fun onTileAdded() {
        super.onTileAdded()
        Log.d("QuickTile", "磁贴已添加")
    }

    override fun onClick() {
        super.onClick()
        try {
            // 将当前时间写入剪贴板
            val currentTime = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault()).format(java.util.Date())
            val clipboardManager = getSystemService(CLIPBOARD_SERVICE) as android.content.ClipboardManager
            val clipData = android.content.ClipData.newPlainText("当前时间", currentTime)
            clipboardManager.setPrimaryClip(clipData)
            
            // 创建显式 Intent
            val intent = Intent(this, MainActivity::class.java).apply {
                // 修改启动标志，避免清除任务栈
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                // 添加额外标志以确保正确恢复
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                // 可选：如果应用已在后台运行，尝试将其带到前台
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                // 使用系统弹窗方式启动
                val pendingIntent = PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
                
                // 通过PendingIntent启动
                startActivityAndCollapse(pendingIntent)
            }
            else {
                startActivityAndCollapse(intent)
            }
        } catch (e: Exception) {
            Log.e("QuickTile", "启动失败", e)
        }
    }
}