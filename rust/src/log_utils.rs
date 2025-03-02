use log::LevelFilter;

/// 跨平台日志初始化
pub fn init_logger(default_level: LevelFilter) {
    #[cfg(target_os = "android")]
    init_android_logger(default_level);

    #[cfg(not(target_os = "android"))]
    init_env_logger(default_level);
}

#[cfg(target_os = "android")]
fn init_android_logger(default_level: LevelFilter) {
    use android_logger::{Config, FilterBuilder};
    use std::env;

    let filter_str = env::var("NLIP_LOG")
        .unwrap_or_else(|_| default_level.to_string());

    android_logger::init_once(
        Config::default()
            .with_max_level(default_level)
            .with_tag("NLIP")
            .with_filter(
                FilterBuilder::new()
                    .parse(&filter_str)
                    .build(),
            )
    );
}

#[cfg(not(target_os = "android"))]
fn init_env_logger(default_level: LevelFilter) {
    use env_logger::{Builder, Env};
    use std::env;

    let env = Env::default()
        .filter_or("NLIP_LOG", default_level.to_string())
        .write_style_or("NLIP_LOG_STYLE", "auto");

    Builder::from_env(env)
        .format_timestamp_millis()
        .format_module_path(false)
        .init();
} 