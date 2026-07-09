# Neko Money Manager

A personal finance and expense tracking app built with Flutter. Manage multiple ledgers, track transactions by category, monitor assets, and visualize spending with charts — all stored locally on your device.

## Features

- **Multiple Ledgers** — Organize finances across separate ledgers (e.g., personal, business)
- **Transaction Tracking** — Record income and expenses with category tagging
- **Categories** — Customizable categories with emoji icons
- **Assets Management** — Track accounts, wallets, and other financial assets
- **Charts & Analytics** — Visualize spending patterns with interactive charts
- **Bookmarks & Reimbursements** — Mark important transactions and track reimbursements
- **Filtering & History** — Filter transactions by category, date, and more
- **Dark/Light Theme** — Switch between appearance modes
- **Local Storage** — All data stored locally via SQLite (no cloud dependency)
- **Onboarding** — Guided setup with default data seeding

## Tech Stack

- **Framework:** Flutter (Dart SDK ^3.12.2)
- **State Management:** Riverpod
- **Database:** sqflite (SQLite)
- **Charts:** fl_chart
- **Fonts:** Google Fonts, Noto Sans, Noto Color Emoji
- **Architecture:** Feature-first with data/presentation layers

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK ^3.12.2
- Android Studio / Xcode (for mobile) or desktop toolchain

### Installation

```bash
git clone https://github.com/<your-username>/neko-money-manager.git
cd neko-money-manager
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── services/       # Database service
│   ├── theme/          # Light/dark theme definitions
│   ├── utils/
│   └── widgets/        # Shared UI components
└── features/
    ├── assets/         # Financial assets management
    ├── categories/     # Transaction categories
    ├── common/         # Shared data (default seeding)
    ├── home/           # Dashboard & ledger details
    ├── onboarding/     # Splash & first-launch flow
    ├── settings/       # Appearance, backup, ledger config
    └── transactions/   # Transaction CRUD, charts, filters
```

## Supported Platforms

- Android
- iOS
- Web
- Windows
- Linux
- macOS

## License

This project is licensed under the terms in the [LICENSE](LICENSE) file.