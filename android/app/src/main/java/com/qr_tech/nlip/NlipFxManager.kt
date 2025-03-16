package com.qr_tech.nlip
import android.app.Application
import android.content.ClipData
import android.content.ClipboardManager
import androidx.appcompat.app.AlertDialog
import com.petterp.floatingx.FloatingX
import com.petterp.floatingx.assist.FxScopeType
import com.petterp.floatingx.assist.FxDisplayMode
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity.CLIPBOARD_SERVICE
import kotlinx.coroutines.launch
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import android.view.View
import android.widget.EditText
import android.util.Log
import com.petterp.floatingx.listener.IFxPermissionAskControl
import com.petterp.floatingx.listener.IFxViewLifecycle
import com.petterp.floatingx.view.FxViewHolder

object NlipFxManager {
    lateinit var context: Application
    lateinit var apiUtils: ApiUtils
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())

    fun install(_context: Application, _apiUtils: ApiUtils) {
        this.context = _context
        this.apiUtils = _apiUtils
        if (!FloatingX.isInstalled()) {
            FloatingX.install {
                setContext(_context)
                setLayout(R.layout.item_floating)
                setScopeType(FxScopeType.SYSTEM)
                setDisplayMode(FxDisplayMode.Normal)
                // 设置权限拦截器
                setPermissionInterceptor { activity, controller -> 
                    showPermissionDialog(activity, controller)
                }
                // setSaveDirectionImpl(IFxConfigStorage)
                setEnableSafeArea(true)
                setEnableKeyBoardAdapt(true, listOf(R.id.uploadItemFx))
                addViewLifecycle(object : IFxViewLifecycle {
                    override fun initView(holder: FxViewHolder) {
                        holder.getViewOrNull<EditText>(R.id.uploadItemFx)?.apply {
                            setOnFocusChangeListener {
                                view, hasFocus -> handleUploadFocusChanged(view, hasFocus)
                            }
                            showSoftInputOnFocus = false
                        }
                        holder.getViewOrNull<EditText>(R.id.downloadItemFx)?.apply {
                            setOnFocusChangeListener {
                                    view, hasFocus -> handleDownloadFocusChanged(view, hasFocus)
                            }
                            showSoftInputOnFocus = false
                        }
                    }
                })
            }
        }
    }

    private fun handleUploadFocusChanged(view: View, hasFocus: Boolean) {
        Log.d("NlipFxManager", "handleUploadFocusChanged")

        if (hasFocus) {
            val clipboard = context.getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
            val clip = clipboard.getPrimaryClip()
            if (clip != null && clip.getItemCount() > 0) {
                val text = clip.getItemAt(0).text.toString()
                coroutineScope.launch {
                    apiUtils.uploadTextClip(text)
                }
                Log.d("NlipFxManager", "上传剪贴板内容: $text")
            } else {
                Log.d("NlipFxManager", "剪贴板为空")
            }
            hide()
        }
    }

    private fun handleDownloadFocusChanged(view: View, hasFocus: Boolean) {
        Log.d("NlipFxManager", "handleDownloadFocusChanged")

        if (hasFocus) {
            val clipboard = context.getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
            var lastClip = ""
            coroutineScope.launch {
                lastClip = apiUtils.getLastClip()
            }
            clipboard.setPrimaryClip(ClipData.newPlainText(null, lastClip))
            hide()
        }
    }

    fun show() {
        if (!FloatingX.isInstalled()) {
            return
        }
        FloatingX.controlOrNull()?.show()
    }

    fun hide() {
        if (!FloatingX.isInstalled()) {
            return
        }
        FloatingX.controlOrNull()?.hide()
    }

    fun isShow(): Boolean {
        if (!FloatingX.isInstalled()) {
            return false
        }
        return FloatingX.controlOrNull()?.isShow() ?: false
    }

    /**
     * 显示权限请求对话框
     */
    private fun showPermissionDialog(
        activity: android.app.Activity,
        controller: IFxPermissionAskControl
    ) {
        AlertDialog.Builder(activity).setTitle("提示").setMessage("需要允许悬浮窗权限")
            .setPositiveButton("去开启") { _, _ ->
                Toast.makeText(
                    activity.applicationContext,
                    "去申请权限中~",
                    Toast.LENGTH_SHORT,
                ).show()
                controller.requestPermission(
                    activity = activity,
                    isAutoShow = true,
                    canUseAppScope = true,
                    resultListener = {
                        Toast.makeText(
                            activity.applicationContext,
                            "申请权限结果: $it",
                            Toast.LENGTH_SHORT,
                        ).show()
                    }
                )
            }.setNegativeButton("取消") { _, _ ->
                Toast.makeText(
                    activity.applicationContext,
                    "降级为App浮窗~",
                    Toast.LENGTH_SHORT,
                ).show()
                controller.downgradeToAppScope()
            }.show()
    }
}