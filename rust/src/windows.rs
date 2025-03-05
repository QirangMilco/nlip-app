// copy from https://github.com/zibo-chen/Selectic
use crate::nlip_utils::{Selection, NlipError, NlipManager};
use arboard::Clipboard;
use enigo::{
    self,
    Direction::{Click, Press, Release},
    Enigo, Key, Keyboard, Settings,
};
use log::{debug, error, info, warn};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Once;
use std::time::Duration;
use windows::Win32::System::Com::{
    CoCreateInstance, CoInitializeEx, CLSCTX_ALL, COINIT_APARTMENTTHREADED,
};
use windows::Win32::System::DataExchange::GetClipboardSequenceNumber;
use windows::Win32::UI::Accessibility::{
    CUIAutomation, IUIAutomation, IUIAutomationTextPattern, UIA_TextPatternId, 
    IUIAutomationValuePattern, UIA_ValuePatternId
};

// 确保COM只初始化一次
static COM_INIT: Once = Once::new();
static COM_INIT_FAILED: AtomicBool = AtomicBool::new(false);

pub struct WindowsNlipManager {}

impl WindowsNlipManager {
    pub fn new() -> Self {
        // 在创建选择器时尝试初始化COM
        init_com();
        WindowsNlipManager {}
    }
}

impl NlipManager for WindowsNlipManager {
    fn get_selection(&self) -> Result<Selection, NlipError> {
        get_windows_selection()
    }
    fn paste_text(&self, text: &str) -> Result<(), NlipError> {
        paste_text_to_active_window(text)
    }
}

impl Default for WindowsNlipManager {
    fn default() -> Self {
        Self::new()
    }
}

fn init_com() {
    COM_INIT.call_once(|| {
        let hr = unsafe { CoInitializeEx(None, COINIT_APARTMENTTHREADED) };
        if hr.is_ok() {
            debug!("COM initialized successfully");
        } else {
            let error_code = hr.0;
            error!("Failed to initialize COM: HRESULT 0x{:08X}", error_code);
            COM_INIT_FAILED.store(true, Ordering::SeqCst);
        }
    });
}

fn get_windows_selection() -> Result<Selection, NlipError> {
    debug!("Getting Windows selection...");

    let result = get_text_internal()?;

    if result.is_empty() {
        return Err(NlipError::NoSelectedContent);
    }

    Ok(Selection::new_text(result))
}

fn get_text_internal() -> Result<String, NlipError> {
    // 首先尝试UI自动化方法
    if !COM_INIT_FAILED.load(Ordering::SeqCst) {
        match get_text_by_automation() {
            Ok(text) if !text.is_empty() => {
                debug!(
                    "Successfully retrieved text via UI Automation: {} chars",
                    text.len()
                );
                return Ok(text);
            }
            Ok(_) => info!("UI Automation returned empty text"),
            Err(err) => error!("UI Automation error: {}", err),
        }
    } else {
        debug!("Skipping UI Automation due to COM initialization failure");
    }

    // 回退到剪贴板方法
    info!("Falling back to clipboard method");
    match get_text_by_clipboard() {
        Ok(text) if !text.is_empty() => {
            debug!(
                "Successfully retrieved text via clipboard: {} chars",
                text.len()
            );
            return Ok(text);
        }
        Ok(_) => info!("Clipboard method returned empty text"),
        Err(err) => {
            error!("Clipboard method error: {}", err);
            return Err(NlipError::ClipboardError(err.to_string()));
        }
    }

    Err(NlipError::NoSelectedContent)
}

fn get_text_by_automation() -> Result<String, NlipError> {
    debug!("Attempting to get text via UI Automation");

    // 创建IUIAutomation实例
    let auto: IUIAutomation = unsafe { CoCreateInstance(&CUIAutomation, None, CLSCTX_ALL) }
        .map_err(|e| NlipError::AccessibilityError(format!("无法创建UI自动化实例: {}", e)))?;

    // 获取焦点元素
    let el = unsafe { auto.GetFocusedElement() }.map_err(|e| {
        debug!("Failed to get focused element: {:?}", e);
        NlipError::NoFocusedElement
    })?;

    // 尝试获取TextPattern
    let pattern_result =
        unsafe { el.GetCurrentPatternAs::<IUIAutomationTextPattern>(UIA_TextPatternId) };

    let text_pattern = match pattern_result {
        Ok(pattern) => pattern,
        Err(e) => {
            debug!("No text pattern available: {:?}", e);
            return Ok(String::new());
        }
    };

    // 获取TextRange数组
    let text_array = unsafe { text_pattern.GetSelection() }.map_err(|e| {
        debug!("Failed to get selection: {:?}", e);
        NlipError::AccessibilityError(format!("无法获取文本选择: {}", e))
    })?;

    let length = unsafe { text_array.Length() }.map_err(|e| {
        debug!("Failed to get text array length: {:?}", e);
        NlipError::AccessibilityError(format!("无法获取文本数组长度: {}", e))
    })?;

    if length == 0 {
        debug!("No text ranges in selection");
        return Ok(String::new());
    }

    // 迭代TextRange数组
    let mut target = String::with_capacity(256); // 预分配合理的容量
    for i in 0..length {
        let text_range = unsafe { text_array.GetElement(i) }.map_err(|e| {
            debug!("Failed to get text range element {}: {:?}", i, e);
            NlipError::AccessibilityError(format!("无法获取文本范围元素 {}: {}", i, e))
        })?;

        // 指定合理的字符数量限制，-1表示获取所有
        let text = unsafe { text_range.GetText(1024) }.map_err(|e| {
            debug!("Failed to get text from range {}: {:?}", i, e);
            NlipError::AccessibilityError(format!("无法从范围 {} 获取文本: {}", i, e))
        })?;

        target.push_str(&text.to_string());
    }

    Ok(target.trim().to_string())
}

fn get_text_by_clipboard() -> Result<String, NlipError> {
    debug!("Attempting to get text via clipboard");

    // 读取旧的剪贴板内容
    let mut clipboard = Clipboard::new().map_err(|e| {
        NlipError::ClipboardError(format!("Failed to open clipboard: {}", e))
    })?;

    let old_text = clipboard.get_text().ok();
    let old_image = clipboard.get_image().ok();

    // 尝试复制选中内容到剪贴板
    copy().map_err(|e| NlipError::ClipboardError(format!("复制操作失败: {}", e)))?;

    // 给系统一点时间处理剪贴板
    std::thread::sleep(Duration::from_millis(150));

    // 读取新的剪贴板内容
    let mut new_clipboard = Clipboard::new().map_err(|e| {
        NlipError::ClipboardError(format!("Failed to open clipboard after copy: {}", e))
    })?;

    let new_text = new_clipboard.get_text().map_err(|e| {
        NlipError::ClipboardError(format!("Failed to get text from clipboard: {}", e))
    })?;

    // 恢复原来的剪贴板内容
    restore_clipboard(old_text, old_image)?;

    // 返回新获取的文本
    if !new_text.is_empty() {
        Ok(new_text.trim().to_string())
    } else {
        Err(NlipError::NoSelectedContent)
    }
}

fn restore_clipboard(
    old_text: Option<String>,
    old_image: Option<arboard::ImageData>,
) -> Result<(), NlipError> {
    let mut restore_clipboard = Clipboard::new().map_err(|e| {
        NlipError::ClipboardError(format!("Failed to open clipboard for restoration: {}", e))
    })?;

    if let Some(text) = old_text {
        restore_clipboard.set_text(text).map_err(|e| {
            NlipError::ClipboardError(format!("Failed to restore text to clipboard: {}", e))
        })?;
    } else if let Some(image) = old_image {
        restore_clipboard.set_image(image).map_err(|e| {
            NlipError::ClipboardError(format!("Failed to restore image to clipboard: {}", e))
        })?;
    } else {
        restore_clipboard.clear().map_err(|e| {
            NlipError::ClipboardError(format!("Failed to clear clipboard: {}", e))
        })?;
    }

    Ok(())
}

// 确保所有修饰键处于释放状态
fn release_keys() -> Result<(), NlipError> {
    let mut enigo = Enigo::new(&Settings::default()).map_err(|e| {
        NlipError::Other(format!("Failed to create Enigo instance: {}", e))
    })?;

    enigo.key(Key::Control, Release).map_err(|e| {
        NlipError::Other(format!("Failed to release Control key: {}", e))
    })?;
    enigo.key(Key::Alt, Release).map_err(|e| {
        NlipError::Other(format!("Failed to release Alt key: {}", e))
    })?;
    enigo.key(Key::Shift, Release).map_err(|e| {
        NlipError::Other(format!("Failed to release Shift key: {}", e))
    })?;
    enigo.key(Key::Meta, Release).map_err(|e| {
        NlipError::Other(format!("Failed to release Meta key: {}", e))
    })?;

    Ok(())
}

fn copy() -> Result<(), NlipError> {
    debug!("Executing copy command");

    // 记录复制前的剪贴板序列号
    let num_before = unsafe { GetClipboardSequenceNumber() };

    // 创建自动化引擎
    let mut enigo = Enigo::new(&Settings::default()).map_err(|e| {
        error!("Failed to create Enigo instance: {:?}", e);
        NlipError::Other(format!("创建Enigo实例失败: {}", e))
    })?;

    release_keys()?;

    // 执行Ctrl+C
    enigo.key(Key::Control, Press).map_err(|e| {
        NlipError::Other(format!("按下Control键失败: {}", e))
    })?;

    enigo.key(Key::C, Click).map_err(|e| {
        // 确保释放Ctrl键
        let _ = enigo.key(Key::Control, Release);
        NlipError::Other(format!("点击C键失败: {}", e))
    })?;

    enigo.key(Key::Control, Release).map_err(|e| {
        NlipError::Other(format!("释放Control键失败: {}", e))
    })?;

    // 等待剪贴板更新
    std::thread::sleep(Duration::from_millis(150));

    // 检查剪贴板是否变化
    let num_after = unsafe { GetClipboardSequenceNumber() };
    if num_after == num_before {
        let mut clipboard = Clipboard::new().map_err(|e| {
            NlipError::ClipboardError(format!("无法打开剪贴板: {}", e))
        })?;
    
        let cur_text = clipboard.get_text().ok();
        warn!("Clipboard sequence number did not change after copy attempt, current clipboard: {}", cur_text.unwrap_or_default());
        return Err(NlipError::ClipboardError("剪贴板序列号未变化，复制可能失败".into()));
    }

    Ok(())
}

pub fn paste_text_to_active_window(text: &str) -> Result<(), NlipError> {
    debug!("粘贴文本到Windows焦点位置...");
    
    paste_text_internal(text, false).map_err(|err| {
        error!("粘贴文本失败: {}", err);
        match err {
            NlipError::ClipboardError(_) => err,
            NlipError::NoFocusedElement => err,
            NlipError::PasteError(_) => err,
            _ => NlipError::PasteError(format!("粘贴文本失败: {}", err))
        }
    })?;
    
    debug!("成功粘贴文本: {} 个字符", text.len());
    Ok(())
}

fn paste_text_internal(text: &str, sim_keyboard_input: bool) -> Result<(), NlipError> {
    debug!("尝试粘贴文本");

    // 首先尝试UI自动化方法
    if !COM_INIT_FAILED.load(Ordering::SeqCst) {
        match paste_text_by_automation(text) {
            Ok(true) => {
                debug!("成功通过UI自动化粘贴文本");
                return Ok(());
            }
            Ok(false) => info!("UI自动化粘贴方法不适用"),
            Err(err) => error!("UI自动化粘贴错误: {}", err),
        }
    } else {
        debug!("由于COM初始化失败，跳过UI自动化方法");
    }

    if sim_keyboard_input {
        // 尝试直接键盘输入方法
        info!("尝试直接键盘输入方法");
        match paste_text_by_keyboard(text) {
            Ok(()) => {
                debug!("成功通过直接键盘输入粘贴文本");
                return Ok(());
            }
            Err(err) => {
                error!("直接键盘输入失败: {}", err);
                // 失败后继续尝试剪贴板方法
            }
        }
    }

    // 回退到剪贴板方法
    info!("回退到剪贴板粘贴方法");
    paste_text_by_clipboard(text)
}

fn paste_text_by_automation(text: &str) -> Result<bool, NlipError> {
    debug!("尝试通过UI自动化粘贴文本");

    // 创建IUIAutomation实例
    let auto: IUIAutomation = unsafe { CoCreateInstance(&CUIAutomation, None, CLSCTX_ALL) }
        .map_err(|e| NlipError::AccessibilityError(format!("无法创建UI自动化实例: {}", e)))?;

    // 获取焦点元素
    let el = unsafe { auto.GetFocusedElement() }.map_err(|e| {
        debug!("无法获取焦点元素: {:?}", e);
        NlipError::NoFocusedElement
    })?;

    let is_enabled = unsafe { el.CurrentIsEnabled() }.map_err(|e| {
        debug!("无法检查是否启用: {:?}", e);
        NlipError::NoFocusedElement
    })?;

    if !is_enabled.as_bool() {
        debug!("元素未启用，跳过粘贴");
        return Ok(false);
    }

    let is_keyboard_focusable = unsafe { el.CurrentIsKeyboardFocusable() }.map_err(|e| {
        debug!("无法检查是否可键盘聚焦: {:?}", e);
        NlipError::NoFocusedElement
    })?;

    if !is_keyboard_focusable.as_bool() {
        debug!("元素不可键盘聚焦，跳过粘贴");
        return Ok(false);
    }
    
    // 尝试获取ValuePattern
    let pattern_result =
        unsafe { el.GetCurrentPatternAs::<IUIAutomationValuePattern>(UIA_ValuePatternId) };

    match pattern_result {
        Ok(value_pattern) => {
            // 使用完整路径
            let bstr_text = windows::core::BSTR::from(text);
            unsafe { value_pattern.SetValue(&bstr_text) }.map_err(|e| {
                debug!("无法设置文本: {:?}", e);
                NlipError::AccessibilityError(format!("无法通过ValuePattern设置文本: {}", e))
            })?;
            
            debug!("成功通过ValuePattern设置文本");
            std::thread::sleep(Duration::from_millis(100));
            verify_paste(text, Some(el))?;
            return Ok(true);
        }
        Err(e) => {
            debug!("无法获取ValuePattern: {:?}", e);
            return Err(NlipError::PasteError(format!("无法获取ValuePattern: {}", e)));
        }
    };
}

// 添加新的直接键盘输入方法
fn paste_text_by_keyboard(text: &str) -> Result<(), NlipError> {
    debug!("尝试通过直接键盘输入粘贴文本");
    
    let mut enigo = Enigo::new(&Settings::default()).map_err(|e| {
        error!("创建Enigo实例失败: {:?}", e);
        NlipError::Other(format!("创建Enigo实例失败: {}", e))
    })?;
    
    release_keys()?;

    enigo.text(text).map_err(|e| {
        error!("输入字符失败: {:?}", e);
        NlipError::PasteError(format!("通过模拟键盘输入文本失败: {}", e))
    })?;
    
    // 等待文本输入完成
    std::thread::sleep(Duration::from_millis(100));
    
    debug!("成功通过直接键盘输入文本");
    Ok(())
}

fn paste_text_by_clipboard(text: &str) -> Result<(), NlipError> {
    debug!("尝试通过剪贴板粘贴文本");

    // 读取旧的剪贴板内容
    let mut clipboard = Clipboard::new().map_err(|e| {
        NlipError::ClipboardError(format!("无法打开剪贴板: {}", e))
    })?;

    let old_text = clipboard.get_text().ok();
    let old_image = clipboard.get_image().ok();

    // 将要粘贴的文本设置到剪贴板
    clipboard.set_text(text.to_string()).map_err(|e| {
        NlipError::ClipboardError(format!("无法设置文本到剪贴板: {}", e))
    })?;

    // 给系统一点时间处理剪贴板变更
    std::thread::sleep(Duration::from_millis(100));

    // 执行粘贴操作
    paste().map_err(|e| NlipError::PasteError(format!("粘贴操作失败: {}", e)))?;

    // 增加等待时间，确保粘贴操作完成
    std::thread::sleep(Duration::from_millis(300));

    // 恢复原来的剪贴板内容
    restore_clipboard(old_text, old_image)?;

    Ok(())
}

// 修改验证粘贴是否成功的函数
fn verify_paste(expected_text: &str, focused_element: Option<windows::Win32::UI::Accessibility::IUIAutomationElement>) -> Result<(), NlipError> {
    debug!("验证粘贴是否成功");
    
    // 获取当前焦点元素（如果未提供）
    let element = match focused_element {
        Some(el) => el,
        None => {
            debug!("未提供焦点元素，尝试获取当前焦点");
            if COM_INIT_FAILED.load(Ordering::SeqCst) {
                return Err(NlipError::AccessibilityError("COM初始化失败，无法获取焦点元素".into()));
            }
            
            // 创建IUIAutomation实例
            let auto: IUIAutomation = unsafe { CoCreateInstance(&CUIAutomation, None, CLSCTX_ALL) }
                .map_err(|e| NlipError::AccessibilityError(format!("无法创建UI自动化实例: {}", e)))?;
            
            // 获取焦点元素
            unsafe { auto.GetFocusedElement() }.map_err(|e| {
                debug!("无法获取焦点元素: {:?}", e);
                NlipError::NoFocusedElement
            })?
        }
    };
    
    // 尝试获取元素中的文本内容
    let current_text = get_text_from_element(&element)?;
    
    // 验证文本是否包含预期内容
    if current_text.contains(expected_text) {
        debug!("验证成功：文本框包含预期文本");
        Ok(())
    } else {
        debug!("验证失败：文本框不包含预期文本");
        debug!("预期文本: {}", expected_text);
        debug!("当前文本: {}", current_text);
        Err(NlipError::PasteError("粘贴的文本未在目标元素中找到".into()))
    }
}

// 从元素获取文本内容的辅助函数
fn get_text_from_element(element: &windows::Win32::UI::Accessibility::IUIAutomationElement) -> Result<String, NlipError> {
    // 尝试获取TextPattern
    let pattern_result = unsafe { 
        element.GetCurrentPatternAs::<IUIAutomationTextPattern>(UIA_TextPatternId) 
    };
    
    if let Ok(text_pattern) = pattern_result {
        // 获取整个文档范围
        let document_range = unsafe { text_pattern.DocumentRange() }.map_err(|e| {
            debug!("无法获取文档范围: {:?}", e);
            NlipError::AccessibilityError(format!("无法获取文档范围: {}", e))
        })?;
        
        // 获取文本内容
        let text = unsafe { document_range.GetText(-1) }.map_err(|e| {
            debug!("无法获取文本内容: {:?}", e);
            NlipError::AccessibilityError(format!("无法获取文本内容: {}", e))
        })?;
        
        return Ok(text.to_string());
    }
    
    // 尝试获取ValuePattern
    let value_pattern_result = unsafe { 
        element.GetCurrentPatternAs::<IUIAutomationValuePattern>(UIA_ValuePatternId) 
    };
    
    if let Ok(value_pattern) = value_pattern_result {
        let value = unsafe { value_pattern.CurrentValue() }.map_err(|e| {
            debug!("无法获取值: {:?}", e);
            NlipError::AccessibilityError(format!("无法获取元素值: {}", e))
        })?;
        
        return Ok(value.to_string());
    }
    
    // 如果无法通过模式获取文本，尝试获取Name属性
    let name = unsafe { element.CurrentName() }.map_err(|e| {
        debug!("无法获取元素名称: {:?}", e);
        NlipError::AccessibilityError(format!("无法获取元素名称: {}", e))
    })?;
    
    if !name.is_empty() {
        return Ok(name.to_string());
    }
    
    // 如果所有方法都失败，返回空字符串
    debug!("无法从元素获取任何文本内容");
    Ok(String::new())
}

fn paste() -> Result<(), NlipError> {
    debug!("执行粘贴命令");

    // 创建自动化引擎
    let mut enigo = Enigo::new(&Settings::default()).map_err(|e| {
        error!("创建Enigo实例失败: {:?}", e);
        NlipError::Other(format!("创建Enigo实例失败: {}", e))
    })?;

    release_keys()?;

    // 执行Ctrl+V
    enigo.key(Key::Control, Press).map_err(|e| {
        NlipError::Other(format!("按下Control键失败: {}", e))
    })?;

    enigo.key(Key::V, Click).map_err(|e| {
        // 确保释放Ctrl键
        let _ = enigo.key(Key::Control, Release);
        NlipError::PasteError(format!("点击V键失败: {}", e))
    })?;

    enigo.key(Key::Control, Release).map_err(|e| {
        NlipError::Other(format!("释放Control键失败: {}", e))
    })?;

    Ok(())
}