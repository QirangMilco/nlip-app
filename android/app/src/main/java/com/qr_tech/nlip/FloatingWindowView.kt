package com.qr_tech.nlip

import android.annotation.SuppressLint
import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.ViewConfiguration
import androidx.cardview.widget.CardView
import kotlin.math.abs

class FloatingWindowView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : CardView(context, attrs, defStyleAttr) {

    interface WindowPositionListener {
        fun onPositionChanged(deltaX: Int, deltaY: Int)
        fun onDragEnd()
    }

    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var initialWindowX = 0
    private var initialWindowY = 0
    private var isDragging = false
    private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop
    var positionListener: WindowPositionListener? = null
    private var lastX = 0f
    private var lastY = 0f

    init {
        setupViewBehavior()
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun setupViewBehavior() {
        isClickable = true
        isFocusable = true
        setOnTouchListener { _, event -> handleTouchEvent(event) }
    }

    private fun handleTouchEvent(event: MotionEvent): Boolean {
        return when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                handleActionDown(event)
                true
            }
            MotionEvent.ACTION_MOVE -> handleActionMove(event)
            MotionEvent.ACTION_UP -> handleActionUp()
            else -> false
        }
    }

    private fun handleActionDown(event: MotionEvent) {
        initialTouchX = event.rawX
        initialTouchY = event.rawY
        lastX = event.rawX
        lastY = event.rawY
        
        // 保存初始窗口位置
        val activity = context as? FloatingWindowActivity
        activity?.let {
            initialWindowX = it.window.attributes.x
            initialWindowY = it.window.attributes.y
        }
        
        isDragging = false
    }

    private fun handleActionMove(event: MotionEvent): Boolean {
        if (!isDragging) {
            val dx = abs(event.rawX - initialTouchX)
            val dy = abs(event.rawY - initialTouchY)
            isDragging = dx > touchSlop || dy > touchSlop
        }

        if (isDragging) {
            // 计算相对于初始触摸位置的偏移量
            val deltaX = (event.rawX - lastX).toInt()
            val deltaY = (event.rawY - lastY).toInt()
            lastX = event.rawX
            lastY = event.rawY
            
            positionListener?.onPositionChanged(deltaX, deltaY)
            return true
        }
        return false
    }

    private fun handleActionUp(): Boolean {
        if (isDragging) {
            positionListener?.onDragEnd()
        } else {
            performClick()
        }
        isDragging = false
        return true
    }

    override fun performClick(): Boolean {
        super.performClick()
        return true
    }
}