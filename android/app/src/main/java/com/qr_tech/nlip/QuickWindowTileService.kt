package com.qr_tech.nlip

import android.service.quicksettings.TileService
import android.content.Intent
import android.util.Log
import android.app.PendingIntent
import android.os.Build
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)

class QuickWindowTileService: TileService() {
    override fun onTileAdded() {
        super.onTileAdded()
        Log.d("WindowTile", "磁贴已添加")
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onStartListening() {
        super.onStartListening()
        Log.d("WindowTile", "磁贴已开始监听")
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    override fun onClick() {
        super.onClick()
        try {
            val intent = Intent(applicationContext, FloatingWindowActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_LAUNCH_ADJACENT or
                        Intent.FLAG_ACTIVITY_MULTIPLE_TASK
            }

            // 创建符合要求的PendingIntent
            val pendingIntent =
                PendingIntent.getActivity(
                    applicationContext,
                    6236,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                )

            // 使用正确的方法启动
            startActivityAndCollapse(pendingIntent)
            Log.d("QuickTile", "已启动小窗模式")

        } catch (e: Exception) {
            Log.e("QuickTile", "操作失败", e)
        }
    }
}