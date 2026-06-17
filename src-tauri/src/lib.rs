use serde::{Deserialize, Serialize};
use tauri::{
    image::Image,
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, Manager, PhysicalPosition, Rect, Runtime, WindowEvent,
};

const BASE_URL: &str = "https://codex-everywhere.com/api/v1";
const TIMEZONE: &str = "Asia/Calcutta";

#[derive(Serialize)]
struct LoginPayload<'a> {
    email: &'a str,
    password: &'a str,
}

async fn fetch_json<T: serde::de::DeserializeOwned>(
    client: &reqwest::Client,
    path: &str,
    token: &str,
    query: &[(&str, &str)],
) -> Result<T, String> {
    let mut req = client
        .get(format!("{BASE_URL}{path}"))
        .header("Authorization", format!("Bearer {token}"));

    for (key, value) in query {
        req = req.query(&[(key, value)]);
    }

    let res = req.send().await.map_err(|e| e.to_string())?;
    if !res.status().is_success() {
        return Err(format!("HTTP Error: {}", res.status()));
    }

    res.json::<T>().await.map_err(|e| e.to_string())
}

#[tauri::command]
async fn login(email: String, password: String) -> Result<String, String> {
    let client = reqwest::Client::new();
    let res = client
        .post(format!("{BASE_URL}/auth/login"))
        .json(&LoginPayload {
            email: &email,
            password: &password,
        })
        .send()
        .await
        .map_err(|e| e.to_string())?;

    let status = res.status();
    let json: serde_json::Value = res.json().await.map_err(|e| e.to_string())?;
    if !status.is_success() {
        return Err(json
            .get("message")
            .and_then(|v| v.as_str())
            .unwrap_or("Login failed")
            .to_string());
    }

    json.get("data")
        .and_then(|v| v.get("access_token"))
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .ok_or_else(|| "No token received".to_string())
}

#[derive(Deserialize)]
struct UserData {
    email: String,
    balance: f64,
}

#[derive(Deserialize, Serialize)]
struct DashboardStats {
    total_api_keys: i64,
    active_api_keys: i64,
    total_requests: i64,
    total_input_tokens: i64,
    total_output_tokens: i64,
    total_cache_creation_tokens: i64,
    total_cache_read_tokens: i64,
    total_tokens: i64,
    total_cost: f64,
    total_actual_cost: f64,
    today_requests: i64,
    today_input_tokens: i64,
    today_output_tokens: i64,
    today_cache_creation_tokens: i64,
    today_cache_read_tokens: i64,
    today_tokens: i64,
    today_cost: f64,
    today_actual_cost: f64,
    average_duration_ms: f64,
    rpm: i64,
    tpm: i64,
}

#[derive(Deserialize, Serialize)]
struct UsageItem {
    id: i64,
    model: String,
    input_tokens: i64,
    output_tokens: i64,
    actual_cost: f64,
    created_at: String,
}

#[derive(Deserialize, Serialize)]
struct TrendDay {
    date: String,
    actual_cost: f64,
}

#[derive(Deserialize)]
struct MeResponse {
    data: UserData,
}

#[derive(Deserialize)]
struct StatsResponse {
    data: DashboardStats,
}

#[derive(Deserialize)]
struct UsageResponse {
    data: UsageItemsData,
}

#[derive(Deserialize)]
struct UsageItemsData {
    items: Vec<UsageItem>,
}

#[derive(Deserialize)]
struct TrendResponse {
    data: TrendItemsData,
}

#[derive(Deserialize)]
struct TrendItemsData {
    trend: Vec<TrendDay>,
}

#[derive(Serialize)]
struct DashboardPayload {
    email: String,
    balance: f64,
    stats: DashboardStats,
    recent_items: Vec<UsageItem>,
    trend: Vec<TrendDay>,
}

#[tauri::command]
async fn load_dashboard(token: String) -> Result<DashboardPayload, String> {
    let client = reqwest::Client::new();
    let today = chrono::Local::now().date_naive().format("%Y-%m-%d").to_string();
    let start = (chrono::Local::now().date_naive() - chrono::Days::new(6))
        .format("%Y-%m-%d")
        .to_string();

    let me = fetch_json::<MeResponse>(&client, "/auth/me", &token, &[("timezone", TIMEZONE)]).await?;
    let stats =
        fetch_json::<StatsResponse>(&client, "/usage/dashboard/stats", &token, &[("timezone", TIMEZONE)]).await?;
    let usage = fetch_json::<UsageResponse>(
        &client,
        "/usage",
        &token,
        &[
            ("page", "1"),
            ("page_size", "10"),
            ("start_date", &today),
            ("end_date", &today),
            ("sort_by", "created_at"),
            ("sort_order", "desc"),
            ("timezone", TIMEZONE),
        ],
    )
    .await?;
    let trend = fetch_json::<TrendResponse>(
        &client,
        "/usage/dashboard/trend",
        &token,
        &[
            ("start_date", &start),
            ("end_date", &today),
            ("granularity", "day"),
            ("timezone", TIMEZONE),
        ],
    )
    .await?;

    Ok(DashboardPayload {
        email: me.data.email,
        balance: me.data.balance,
        stats: stats.data,
        recent_items: usage.data.items,
        trend: trend.data.trend,
    })
}

fn position_popover<R: Runtime>(app: &AppHandle<R>, tray_rect: Option<Rect>) {
    let Some(window) = app.get_webview_window("main") else {
        return;
    };

    let Ok(size) = window.outer_size() else {
        let _ = window.center();
        return;
    };
    let scale_factor = window.scale_factor().unwrap_or(1.0);

    let margin = 12;
    let (mut x, mut y) = if let Some(rect) = tray_rect {
        let icon_pos = rect.position.to_physical::<i32>(scale_factor);
        let icon_size = rect.size.to_physical::<u32>(scale_factor);
        let icon_x = icon_pos.x;
        let icon_y = icon_pos.y;
        let icon_w = icon_size.width as i32;
        let icon_h = icon_size.height as i32;
        (
            icon_x + (icon_w - size.width as i32) / 2,
            icon_y + icon_h + margin,
        )
    } else if let Ok(Some(monitor)) = window.current_monitor().or_else(|_| window.primary_monitor()) {
        let monitor_pos = monitor.position();
        let monitor_size = monitor.size();
        (
            monitor_pos.x + monitor_size.width as i32 - size.width as i32 - margin,
            monitor_pos.y + margin,
        )
    } else {
        let _ = window.center();
        return;
    };

    if let Ok(Some(monitor)) = window.current_monitor().or_else(|_| window.primary_monitor()) {
        let monitor_pos = monitor.position();
        let monitor_size = monitor.size();
        let min_x = monitor_pos.x + margin;
        let max_x = monitor_pos.x + monitor_size.width as i32 - size.width as i32 - margin;
        let min_y = monitor_pos.y + margin;
        let max_y = monitor_pos.y + monitor_size.height as i32 - size.height as i32 - margin;
        x = x.clamp(min_x, max_x.max(min_x));
        y = y.clamp(min_y, max_y.max(min_y));
    }

    let _ = window.set_position(PhysicalPosition::new(x, y));
}

fn toggle_popover<R: Runtime>(app: &AppHandle<R>, tray_rect: Option<Rect>) {
    let Some(window) = app.get_webview_window("main") else {
        return;
    };

    if window.is_visible().unwrap_or(false) {
        let _ = window.hide();
    } else {
        position_popover(app, tray_rect);
        let _ = window.show();
        let _ = window.set_focus();
    }
}

fn show_popover<R: Runtime>(app: &AppHandle<R>, tray_rect: Option<Rect>) {
    let Some(window) = app.get_webview_window("main") else {
        return;
    };

    position_popover(app, tray_rect);
    let _ = window.show();
    let _ = window.set_focus();
}

#[tauri::command]
fn hide_window(app: AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.hide();
    }
}
use window_vibrancy::{apply_blur, apply_vibrancy, NSVisualEffectMaterial,apply_acrylic};

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![hide_window, login, load_dashboard])
        .setup(|app| {
            let window = app.get_webview_window("main").unwrap();

            // Apply vibrancy for macOS
            #[cfg(target_os = "macos")]
            apply_vibrancy(&window, NSVisualEffectMaterial::Sheet, None, Some(12.0))
                .expect("Unsupported platform!");

            // Apply blur/acrylic for Windows
            #[cfg(target_os = "windows")]
            apply_acrylic(&window, Some((1, 1, 1, 100)))
                .expect("Unsupported platform!");

            #[cfg(target_os = "macos")]
            app.set_activation_policy(tauri::ActivationPolicy::Accessory);

            let quit = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
            let show = MenuItem::with_id(app, "show", "Show", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&show, &quit])?;
            let app_handle = app.handle().clone();
            let icon = Image::from_bytes(include_bytes!("../icons/icon.png"))?;
            TrayIconBuilder::with_id("main-tray")
                .tooltip("Codex Everywhere")
                .icon(icon)
                .menu(&menu)
                .show_menu_on_left_click(false)
                .on_tray_icon_event(move |_tray, event| match event {
                    TrayIconEvent::Click {
                        rect,
                        button: MouseButton::Left,
                        button_state: MouseButtonState::Up,
                        ..
                    } => toggle_popover(&app_handle, Some(rect)),
                    #[cfg(any(target_os = "linux", target_os = "windows"))]
                    TrayIconEvent::Enter { rect, .. } => show_popover(&app_handle, Some(rect)),
                    _ => {}
                })
                .build(app)?;

            Ok(())
        })
        .on_menu_event(|app, event| match event.id().as_ref() {
            "quit" => app.exit(0),
            "show" => show_popover(app, None),
            _ => {}
        })
        .on_window_event(|window, event| {
            if window.label() == "main" {
                if let WindowEvent::Focused(false) = event {
                    let _ = window.hide();
                }
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running Codex Everywhere");
}
