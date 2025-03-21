package com.qr_tech.nlip

import android.content.ClipboardManager
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity
import com.qr_tech.nlip.NlipFxManager.apiUtils
import com.qr_tech.nlip.NlipFxManager.context
import kotlinx.coroutines.launch
import android.animation.ValueAnimator
import android.content.ClipData
import android.view.animation.DecelerateInterpolator
import android.widget.Toast
import com.qr_tech.nlip.NlipFxManager.hide
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job

class FloatingWindowActivity : AppCompatActivity() {
    private val edgeThreshold = 0.5f // 吸附阈值（屏幕宽度的20%）
    private val topSafetyMargin = 120 // 上边缘安全距离（单位：像素）
    private val bottomSafetyMargin = 50 // 下边缘安全距离（单位：像素）
    private var windowWidth = 0
    private var windowHeight = 0
    private val animationDuration = 300L // 吸附动画持续时间，单位毫秒
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_floating_window)

        val rootView = findViewById<FloatingWindowView>(R.id.root_view)
        
        // 在布局完成后获取正确的窗口宽度
        rootView.post {
            windowWidth = rootView.width
            windowHeight = rootView.height
            Log.d("NlipFloatingWindow", "初始化窗口宽度: $windowWidth")
        }
        
        
        rootView.positionListener = object : FloatingWindowView.WindowPositionListener {
            override fun onPositionChanged(deltaX: Int, deltaY: Int) {
                // 直接更新整个窗口的位置
                val params = window.attributes
                params.x += deltaX
                params.y += deltaY
                
                // 确保不会超出屏幕边界
                val screenWidth = resources.displayMetrics.widthPixels
                val screenHeight = resources.displayMetrics.heightPixels

                // 使用保存的窗口宽度，如果还未初始化则使用decorView.width作为后备
                val actualWindowWidth = if (windowWidth > 0) windowWidth else window.decorView.width
                
                // 仅检查边界，不进行吸附
                if (params.x < 0) params.x = 0
                if (params.x > screenWidth - actualWindowWidth)
                    params.x = screenWidth - actualWindowWidth
                    
                if (params.y < topSafetyMargin) params.y = topSafetyMargin
                val actualWindowHeight = if (windowHeight > 0) windowHeight else window.decorView.height
                if (params.y > screenHeight - actualWindowHeight - bottomSafetyMargin)
                    params.y = screenHeight - actualWindowHeight - bottomSafetyMargin
                    
                window.attributes = params
            }

            override fun onDragEnd() {
                // 仅在拖动结束时执行吸附
                autoSnapToEdge()
            }
        }

        setupClickListeners()
        setupWindowParams()
    }

    private fun setupClickListeners() {
        findViewById<Button>(R.id.upload_btn).setOnClickListener {
            handleUploadClick()
        }

        findViewById<Button>(R.id.download_btn).setOnClickListener {
            handleDownloadClick()
        }
        
        findViewById<Button>(R.id.close_btn).setOnClickListener {
            finish()
        }
    }

    private fun handleUploadClick() {
        val clipboard = context.getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        if (clip != null && clip.itemCount > 0) {
            val text = clip.getItemAt(0).text.toString()
            coroutineScope.launch {
                val result = apiUtils.uploadTextClip(text)
                Log.d("NlipFloatingWindow", "上传剪贴板内容: $text")
                if (result) {
                    Log.d("NlipFloatingWindow", "上传成功")
                    Toast.makeText(context, "上传成功", Toast.LENGTH_SHORT).show()
                } else {
                    Log.d("NlipFloatingWindow", "上传失败")
                    Toast.makeText(context, "上传失败", Toast.LENGTH_SHORT).show()
                }
                finish()
            }

        } else {
            Log.d("NlipFloatingWindow", "剪贴板为空")
            Toast.makeText(context, "剪贴板为空", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    private fun handleDownloadClick() {
        val clipboard = context.getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
        coroutineScope.launch {
            val lastClip = apiUtils.getLastClip()
            Log.d("NlipFloatingWindow", "获取Nlip剪贴板内容: $lastClip")
            if (lastClip.isEmpty()) {
                Log.d("NlipFloatingWindow", "获取Nlip剪贴板为空")
                Toast.makeText(context, "获取失败，Nlip剪贴板为空", Toast.LENGTH_SHORT).show()
            }
            else {
                Log.d("NlipFloatingWindow", "获取成功，Nlip剪贴板内容: $lastClip")
                Toast.makeText(context, "获取成功", Toast.LENGTH_SHORT).show()
            }
            clipboard.setPrimaryClip(ClipData.newPlainText(null, lastClip))
            finish()
        }
    }

    override fun onTouchEvent(event: MotionEvent?): Boolean {
        Log.d("NlipFloatingWindow", "onTouchEvent: $event")
        if (event?.actionMasked == MotionEvent.ACTION_OUTSIDE) {
            finish()
            return true
        }
        return super.onTouchEvent(event)
    }

    private fun setupWindowParams() {
        val params = window.attributes.apply {
            width = WindowManager.LayoutParams.WRAP_CONTENT
            height = WindowManager.LayoutParams.WRAP_CONTENT
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 120
            flags = flags or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            flags = flags or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
            flags = flags or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
        }
        window.attributes = params
    }

    private fun updateViewPosition(x: Int, y: Int) {
        val params = window.attributes
        params.x = x
        params.y = y
        window.attributes = params
    }

    private fun autoSnapToEdge() {
        val screenWidth = resources.displayMetrics.widthPixels
        val screenHeight = resources.displayMetrics.heightPixels
        var currentX = window.attributes.x
        val currentY = window.attributes.y

        // 使用保存的窗口宽度
        val actualWindowWidth = if (windowWidth > 0) windowWidth else window.decorView.width

        currentX += actualWindowWidth / 2

        // 判断吸附方向
        val targetX = if (currentX < screenWidth * edgeThreshold) {
            0  // 吸附左边缘
        } else if (currentX > screenWidth * (1 - edgeThreshold)) {
            screenWidth - actualWindowWidth  // 吸附右边缘
        } else {
            window.attributes.x  // 保持当前位置
        }
        
        val actualWindowHeight = if (windowHeight > 0) windowHeight else window.decorView.height

        // 确保Y坐标在安全范围内
        var targetY = currentY
        if (targetY < topSafetyMargin) {
            targetY = topSafetyMargin  // 顶部安全距离
        } else if (targetY > screenHeight - actualWindowHeight - bottomSafetyMargin) {
            targetY = screenHeight - actualWindowHeight - bottomSafetyMargin  // 底部安全距离
        }

        // 创建并执行位置动画
        animateWindowPosition(window.attributes.x, targetX, currentY, targetY)
    }
    
    private fun animateWindowPosition(startX: Int, endX: Int, startY: Int, endY: Int) {
        val animator = ValueAnimator.ofFloat(0f, 1f)
        animator.duration = animationDuration
        animator.interpolator = DecelerateInterpolator()
        
        animator.addUpdateListener { animation ->
            val fraction = animation.animatedValue as Float
            val currentX = startX + ((endX - startX) * fraction).toInt()
            val currentY = startY + ((endY - startY) * fraction).toInt()
            updateViewPosition(currentX, currentY)
        }
        
        animator.start()
    }
} 