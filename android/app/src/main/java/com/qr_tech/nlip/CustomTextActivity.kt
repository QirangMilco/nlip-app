package com.qr_tech.nlip

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class CustomTextActivity : AppCompatActivity() {
    @SuppressLint("SetTextI18n")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 获取选中的文本
        val selectedText = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            intent?.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString() ?: ""
        } else ""
        
        // 处理文本并显示结果
        Toast.makeText(
            this, 
            "你好！原文本：$selectedText",
            Toast.LENGTH_LONG
        ).show()
        
        finish()
    }
} 