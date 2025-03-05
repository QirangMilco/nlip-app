use log::debug;
use serde::{Deserialize, Serialize};
use reqwest::Client;
use std::fmt::Debug;
use crate::nlip_utils::{paste_text, get_text};
use crate::error::NlipError;

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[derive(Debug, Deserialize)]
pub struct ApiResponse<T> {
    pub code: i32,
    pub message: String,
    pub data: T,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum ApiError {
    NetworkError(String),
    ServerError {code: i32, message: String},
    DeserializeError(String),
    ClientError(String),
    Other(String),
}

impl std::fmt::Display for ApiError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NetworkError(e) => write!(f, "Network error: {}", e),
            Self::ServerError { code, message } => write!(f, "Server error: {} - {}", code, message),
            Self::DeserializeError(e) => write!(f, "Deserialize error: {}", e),
            Self::ClientError(e) => write!(f, "Client error: {}", e),
            Self::Other(e) => write!(f, "Other error: {}", e),
        }
    }
}

impl std::error::Error for ApiError {}

impl From<NlipError> for ApiError {
    fn from(error: NlipError) -> Self {
        ApiError::ClientError(error.to_string())
    }
}

fn create_client() -> Client {
    Client::builder()
        .use_rustls_tls()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .unwrap_or_else(|_| Client::new())
}

pub async fn api_request<T, R>(
    method: reqwest::Method,
    url: &str,
    token: Option<&str>,
    body: Option<T>,
) -> Result<R, ApiError>
where
    T: Serialize + Debug,
    R: for<'de> Deserialize<'de> + Debug,
{
    let client = create_client();
    let mut request_builder = client.request(method.clone(), url);

    if let Some(token_str) = token {
        request_builder = request_builder.header("Authorization", format!("Bearer {}", token_str));
    }

    if let Some(data) = body {
        debug!("请求体: {:?}", data);
        request_builder = request_builder.json(&data);
    }

    debug!("发送{}请求到{}", method, url);

    let response = request_builder
        .send()
        .await
        .map_err(|e| ApiError::NetworkError(e.to_string()))?;

    let response_text = response
        .text()
        .await
        .map_err(|e| ApiError::NetworkError(e.to_string()))?;

    debug!("收到响应: {}", response_text);
    
    let api_response: ApiResponse<R> = serde_json::from_str(&response_text)
        .map_err(|e| ApiError::DeserializeError(format!("响应解析失败: {}", e)))?;

    if api_response.code >= 400 {
        return Err(ApiError::ServerError {
            code: api_response.code,
            message: api_response.message,
        });
    }

    Ok(api_response.data)
}


#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // 统一日志初始化
    #[cfg(debug_assertions)]
    let default_level = log::LevelFilter::Debug;
    
    #[cfg(not(debug_assertions))]
    let default_level = log::LevelFilter::Info;

    crate::log_utils::init_logger(default_level);

    // 其他初始化代码...
    flutter_rust_bridge::setup_default_user_utils();
}

#[derive(Debug, Deserialize)]
pub struct User {
    pub id: String,
    pub username: String,
    #[serde(rename = "isAdmin")]
    pub is_admin: bool,
    #[serde(rename = "needChangePwd")]
    pub need_change_pwd: bool,
    #[serde(rename = "createdAt")]
    pub created_at: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginResponse {
    #[serde(rename = "jwtToken")]
    pub jwt_token: String,
    pub user: User,
}

#[flutter_rust_bridge::frb]
pub async fn login(server_url: String, username: String, token: String) -> Result<LoginResponse, ApiError> {
    let url = format!("{}/api/v1/nlip/auth/token-login", server_url.trim_end_matches('/'));
    let data = serde_json::json!({
        "username": username,
        "token": token
    });
    api_request(reqwest::Method::POST, &url, None, Some(data)).await
}

#[derive(Debug, Deserialize)]
pub struct ClipCreator {
    pub id: String,
    pub username: String,
}

#[derive(Debug, Deserialize)]
pub struct Clip {
    pub id: String,
    #[serde(rename = "clipId")]
    pub clip_id: String,
    #[serde(rename = "spaceId")]
    pub space_id: String,
    pub content: String,
    #[serde(rename = "contentType")]
    pub content_type: String,
    pub creator: ClipCreator,
    #[serde(rename = "createdAt")]
    pub created_at: String,
    #[serde(rename = "updatedAt")]
    pub updated_at: String,
    #[serde(rename = "filePath", default)]
    pub file_path: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct ClipResponse {
    pub clip: Clip,
}

#[flutter_rust_bridge::frb]
pub async fn get_last_clip(server_url: String, token: String, space_id: String) -> Result<ClipResponse, ApiError> {
    let url = format!("{}/api/v1/nlip/spaces/{}/clips/last", server_url.trim_end_matches('/'), space_id);
    
    api_request(reqwest::Method::GET, &url, Some(&token), None::<()>).await
}

#[flutter_rust_bridge::frb]
pub async fn upload_text_clip(server_url: String, token: String, space_id: String, content: String) -> Result<ClipResponse, ApiError> {
    let url = format!("{}/api/v1/nlip/spaces/{}/clips/upload", server_url.trim_end_matches('/'), space_id);
    let data = serde_json::json!({
        "content": content,
        "contentType": "text/plain",
        "spaceId": space_id
    });

    api_request(reqwest::Method::POST, &url, Some(&token), Some(data)).await
}

#[derive(Debug, Deserialize)]
pub struct Space {
    pub id: String,
    pub name: String,
    #[serde(rename = "type")]
    pub type_field: String,
    #[serde(rename = "ownerId")]
    pub owner_id: String,
    #[serde(rename = "maxItems")]
    pub max_items: i32,
    #[serde(rename = "retentionDays")]
    pub retention_days: i32,
    #[serde(rename = "createdAt")]
    pub created_at: String,
    #[serde(rename = "updatedAt")]
    pub updated_at: String,
}

// 获取空间列表响应
#[derive(Debug, Deserialize)]
pub struct SpacesListResponse {
    pub spaces: Vec<Space>,
}

#[flutter_rust_bridge::frb]
pub async fn get_spaces_list(server_url: String, token: String) -> Result<SpacesListResponse, ApiError> {
    let url = format!("{}/api/v1/nlip/spaces/list", server_url.trim_end_matches('/'));
    
    api_request(reqwest::Method::GET, &url, Some(&token), None::<()>).await
}

#[derive(Debug, Deserialize)]
pub struct CreateSpaceResponse {
    pub space: Space,
}

#[flutter_rust_bridge::frb]
pub async fn create_space(server_url: String, token: String, name: String) -> Result<CreateSpaceResponse, ApiError> {
    let url = format!("{}/api/v1/nlip/spaces/create", server_url.trim_end_matches('/'));
    let data = serde_json::json!({
        "name": name,
        "maxItems": 5,
        "retentionDays": 1,
        "type": null,
        "collaborators": null
    });
    
    api_request(reqwest::Method::POST, &url, Some(&token), Some(data)).await
}

#[flutter_rust_bridge::frb]
pub async fn paste_text_from_nlip(server_url: String, token: String, space_id: String) -> Result<(), ApiError> {
    let text = get_last_clip(server_url, token, space_id).await?;
    paste_text(text.clip.content.as_str()).map_err(|e| ApiError::ClientError(e.to_string()))?;
    Ok(())
}

#[flutter_rust_bridge::frb]
pub async fn upload_selected_text_to_nlip(server_url: String, token: String, space_id: String) -> Result<(), ApiError> {
    let text = get_text().map_err(|e| ApiError::ClientError(e.to_string()))?;
    upload_text_clip(server_url, token, space_id, text).await?;
    Ok(())
}