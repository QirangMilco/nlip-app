package com.qr_tech.nlip

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.os.Handler
import android.content.Context
import kotlin.math.sqrt
import kotlin.math.pow
import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo

class TextSelectionService : AccessibilityService() {
    private var startX = 0f
    private var startY = 0f
    private val triggerDistance by lazy { 120.dpToPx() } // 使用懒加载初始化
    
    override fun onServiceConnected() {
        val config: AccessibilityServiceInfo = serviceInfo.apply {
            eventTypes = AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED or 
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
        serviceInfo = config
    }
    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED -> {
                event.source?.let { source: AccessibilityNodeInfo ->
                    // 获取选中的文本
                    val selectedText = source.text?.toString()
                        ?: event.text?.joinToString("") 
                        ?: return@let
                    
                    // 获取应用包名
                    val packageName = event.packageName?.toString() ?: "未知应用"
                    
                    // 保存选中文本到 SharedPreferences
                    saveSelectedText(selectedText, packageName)
                    
                    // 处理位置相关逻辑
                    val bounds = Rect().also { source.getBoundsInScreen(it) }
                    val currentX = (bounds.left + bounds.right) / 2f
                    val currentY = (bounds.top + bounds.bottom) / 2f

//                    if (startX == 0f) {
//                        startX = currentX
//                        startY = currentY
//                    }

//                    val distance = calculateDistance(startX, startY, currentX, currentY)
//                    android.util.Log.d("TextSelectionService", "距离: $distance, 起点: $startX, $startY, 当前: $currentX, $currentY")
                    
//                    val selectionStart = source.getTextSelectionStart()
//                    val selectionEnd = source.getTextSelectionEnd()
//                    android.util.Log.d("TextSelectionService", "选区: $selectionStart, $selectionEnd")

                    when {
                        // 初次记录起点
                        startX == 0f -> {
                            startX = currentX
                            startY = currentY
                        }
                        
                        // 计算滑动距离
                        calculateDistance(startX, startY, currentX, currentY) > triggerDistance -> {
                            // 再次保存选中文本
                            saveSelectedText(selectedText, packageName)
                            resetPosition()
                        }
                    }
                }
            }
            else -> resetPosition()
        }
    }

    private fun resetPosition() {
        startX = 0f
        startY = 0f
    }

    private fun Int.dpToPx(): Float {
        // 使用已初始化的applicationContext
        return this * applicationContext.resources.displayMetrics.density
    }

    private fun saveSelectedText(text: String, packageName: String) {
        // 添加日志输出帮助调试
        android.util.Log.d("TextSelectionService", "已保存文本: $text 来自: $packageName")
    }

    private fun calculateDistance(x1: Float, y1: Float, x2: Float, y2: Float): Float {
        return sqrt(
            (x2 - x1).toDouble().pow(2) + 
            (y2 - y1).toDouble().pow(2)
        ).toFloat()
    }

    override fun onInterrupt() {}
}