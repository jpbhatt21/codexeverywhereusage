# Codex Everywhere Menu Bar

A lightweight macOS menu bar app for [Codex Everywhere](https://codex-everywhere.com) that shows your account balance, spending, and API usage at a glance.

![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-blue)
![Language](https://img.shields.io/badge/language-Swift%205-green)
![License](https://img.shields.io/badge/license-MIT-orange)

## Features

- **Menu bar icon** — always accessible, never clutters your dock
- **Balance display** — see your current balance at a glance
- **Spending tracking** — daily, monthly, and all-time spend
- **Cache hit rate** — monitor your API cache efficiency
- **7-day spend chart** — visual breakdown of your weekly costs
- **Recent requests** — last 3 API calls with model, tokens, and cost
- **Multi-account** — switch between multiple Codex accounts
- **Auto-refresh** — data updates every 2 minutes
- **Background caching** — instant data on launch from local cache

## Screenshots

> Run the app and click the brain icon in your menu bar.

## Installation

### Option 1: Download DMG

1. Download `CodexMenuBar.dmg` from [Releases](https://github.com/pujan-modha/codexeverywhereusage/releases)
2. Open the DMG
3. Drag **CodexMenuBar** to your **Applications** folder
4. Launch from Applications or Spotlight

> **Note:** Since the app is not signed with an Apple Developer certificate, you may need to right-click → Open → Open the first time to bypass Gatekeeper.

### Option 2: Build from Source

```bash
git clone https://github.com/pujan-modha/codexeverywhereusage.git
cd codexeverywhereusage
xcodebuild -scheme CodexMenuBar -configuration Release build
cp -R build/Build/Products/Release/CodexMenuBar.app /Applications/
```

### Option 3: Build DMG

```bash
./Scripts/build_dmg.sh
```

This creates `CodexMenuBar.dmg` in the project root.

## Usage

1. Launch **CodexMenuBar** from Applications
2. Click the brain icon in the menu bar
3. Sign in with your Codex Everywhere email and password
4. Your balance, spending, and usage stats appear immediately

### What's Shown

| Section | Description |
|---------|-------------|
| **Balance** | Current account balance, cache hit rate, avg latency |
| **Spending** | Today, this month, and all-time spend |
| **7-Day Chart** | Bar chart of daily costs over the last week |
| **Last 3 Requests** | Model used, tokens in/out, cost, and time ago |

### Multi-Account

- Click the person icon to switch between accounts
- Add new accounts from the menu
- Logout from any account

## Architecture

```
Sources/
├── CodexMenuBarApp.swift    # App entry point, MenuBarExtra setup
├── MenuBarView.swift        # Main UI + ViewModel
├── APIClient.swift          # All API networking
├── Models.swift             # Codable data models
├── AccountManager.swift     # Multi-account management
├── LoginView.swift          # Email/password login screen
└── KeychainHelper.swift     # Secure storage helper
```

## API Endpoints Used

| Endpoint | Purpose |
|----------|---------|
| `POST /api/v1/auth/login` | Email/password authentication |
| `GET /api/v1/auth/me` | Current user info |
| `GET /api/v1/usage/dashboard/stats` | All-time and today's stats |
| `GET /api/v1/usage/dashboard/trend` | 7-day spending trend |
| `GET /api/v1/usage` | Recent API requests |

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15.4+ (for building from source)
- Active [Codex Everywhere](https://codex-everywhere.com) account

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Disclaimer

This is an unofficial client for Codex Everywhere. It is not affiliated with or endorsed by the Codex Everywhere team.
