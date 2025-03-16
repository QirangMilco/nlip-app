package com.qr_tech.nlip

import android.service.quicksettings.TileService
import android.content.Intent
import android.util.Log
import android.app.PendingIntent
import android.os.Build
import android.service.quicksettings.Tile
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class QuickTileService : TileService() {
    override fun onTileAdded() {
        super.onTileAdded()
        Log.d("QuickTile", "磁贴已添加")
    }

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onStartListening() {
        super.onStartListening()
        Log.d("QuickTile", "磁贴已开始监听")
        qsTile?.state = if (NlipFxManager.isShow()) {
            Tile.STATE_ACTIVE
        } else {
            Tile.STATE_INACTIVE
        }
        qsTile?.updateTile()
    }

    override fun onClick() {
        super.onClick()
        try {
            if (NlipFxManager.isShow()) {
                NlipFxManager.hide()
                qsTile?.state = Tile.STATE_INACTIVE
                qsTile?.updateTile()
            } else {
                NlipFxManager.show()
                qsTile?.state = Tile.STATE_ACTIVE
                qsTile?.updateTile()
            }
        } catch (e: Exception) {
            Log.e("QuickTile", "操作失败", e)
        }
    }
}