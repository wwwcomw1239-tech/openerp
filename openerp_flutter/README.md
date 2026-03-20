# OpenERP Flutter

Open Source ERP System - Flutter Desktop & Mobile Application

## Overview

This is the Flutter version of OpenERP, converted from the Next.js web application. It provides a native desktop and mobile experience with offline-first SQLite database.

## Features

- ✅ **Dashboard** - Analytics, KPIs, charts
- ✅ **CRM** - Customer & Supplier management
- ✅ **Inventory** - Product & stock management
- ✅ **Invoicing** - Sales invoices with multi-item support
- ✅ **Purchasing** - Purchase orders management
- ✅ **Accounting** - Chart of accounts, journal entries
- ✅ **Reports** - Financial reports & export

## Technology Stack

| Component | Technology |
|-----------|------------|
| **Framework** | Flutter 3.16+ |
| **State Management** | Riverpod 2.0 |
| **Database** | Drift (SQLite) |
| **Navigation** | go_router |
| **Charts** | fl_chart |
| **PDF Export** | pdf + printing |

## Project Structure

```
lib/
├── core/               # Core utilities, theme, router
├── data/               # Models, database, repositories
│   ├── database/       # Drift database tables
│   ├── models/         # Data models
│   └── repositories/   # Data access layer
├── logic/              # State management
│   ├── providers/      # Riverpod providers
│   └── viewmodels/     # View models
├── ui/                 # UI layer
│   ├── screens/        # Screen widgets
│   ├── widgets/        # Reusable widgets
│   └── dialogs/        # Dialog widgets
└── main.dart           # Entry point
```

## Database Schema

17 tables mirroring the original Prisma schema:

- **Core**: Users, Companies
- **CRM**: Customers, Suppliers
- **Inventory**: Categories, Products
- **Sales**: Invoices, InvoiceItems, Payments
- **Purchasing**: Purchases, PurchaseItems, SupplierPayments
- **Accounting**: Accounts, JournalEntries, JournalLines
- **Analytics**: ActivityLogs

## Getting Started

### Prerequisites

- Flutter SDK 3.16+
- Dart SDK 3.2+

### Installation

```bash
# Clone the repository
git clone https://github.com/wwwcomw1239-tech/openerp.git
cd openerp/openerp_flutter

# Install dependencies
flutter pub get

# Generate database code
flutter pub run build_runner build

# Run the app
flutter run
```

### Running on Desktop

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### Running on Mobile

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

## Code Generation

This project uses code generation for:

1. **Drift database** - Run after schema changes:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Riverpod providers** - Run after provider changes:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.
