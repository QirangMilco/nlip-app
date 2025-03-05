// copy from https://github.com/zibo-chen/Selectic
#[cfg(target_os = "macos")]
use accessibility_ng::Error as AccessibilityErrorNg;

use thiserror::Error;

#[derive(Error, Debug)]
pub enum NlipError {
    #[error("No focused UI element found")]
    NoFocusedElement,

    #[error("No selected content in focused element")]
    NoSelectedContent,

    #[error("Unsupported platform")]
    UnsupportedPlatform,

    #[error("Invalid content type: expected {expected}, received {received}")]
    InvalidContentType { expected: String, received: String },

    #[error("AppleScript execution failed: {0}")]
    AppleScriptError(String),

    #[error("Accessibility API error: {0}")]
    AccessibilityError(String),

    #[error("Clipboard error: {0}")]
    ClipboardError(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("UTF-8 conversion error: {0}")]
    Utf8Error(#[from] std::string::FromUtf8Error),

    #[error("Paste operation failed: {0}")]
    PasteError(String),

    #[error("Nlip error: {0}")]
    Other(String),
}

impl From<String> for NlipError {
    fn from(error: String) -> Self {
        NlipError::Other(error)
    }
}

impl From<&str> for NlipError {
    fn from(error: &str) -> Self {
        NlipError::Other(error.to_string())
    }
}

#[cfg(target_os = "macos")]
impl From<AccessibilityErrorNg> for NlipError {
    fn from(error: AccessibilityErrorNg) -> Self {
        NlipError::AccessibilityError(error.to_string())
    }
}

impl From<Box<dyn std::error::Error>> for NlipError {
    fn from(error: Box<dyn std::error::Error>) -> Self {
        let error_str = error.to_string();
        if error_str.contains("clipboard") || error_str.contains("剪贴板") {
            NlipError::ClipboardError(error_str)
        } else if error_str.contains("paste") || error_str.contains("粘贴") {
            NlipError::PasteError(error_str)
        } else if error_str.contains("focus") || error_str.contains("焦点") {
            NlipError::NoFocusedElement
        } else if error_str.contains("select") || error_str.contains("选择") {
            NlipError::NoSelectedContent
        } else {
            NlipError::Other(error_str)
        }
    }
}