# OpenERP Flutter

Open Source ERP System - Flutter Desktop & Mobile Application

## Overview

This is the Flutter version of OpenERP, converted from the Next.js web application. It provides a native desktop and mobile experience with offline-first SQLite database.

## Features

- ✅ **Dashboard** - Analytics, KPIs, charts with fl_chart
- ✅ **CRM** - Customer & Supplier management with full CRUD
- ✅ **Inventory** - Product & stock management with categories
- ✅ **Invoicing** - Sales invoices with multi-item support and stock tracking
- ✅ **Purchasing** - Purchase orders with multi-item support and stock tracking
- ⏳ **Accounting** - Chart of accounts, journal entries (Phase 4)
- ⏳ **Reports** - Financial reports & export (Phase 4)

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
│   ├── theme/          # App theme configuration
│   └── router/         # go_router navigation
├── data/               # Models, database, repositories
│   └── database/       # Drift database tables
│       ├── tables/     # Table definitions
│       └── database.dart
├── logic/              # State management
│   └── providers/      # Riverpod providers
│       ├── customers_provider.dart
│       ├── suppliers_provider.dart
│       ├── dashboard_provider.dart
│       ├── products_provider.dart
│       ├── invoices_provider.dart
│       └── purchases_provider.dart
├── ui/                 # UI layer
│   ├── screens/        # Screen widgets
│   │   ├── dashboard/  # Dashboard with fl_chart
│   │   ├── customers/  # Full CRUD customers
│   │   ├── suppliers/  # Full CRUD suppliers
│   │   ├── products/   # Products with categories
│   │   ├── invoices/   # Sales invoices (master-detail)
│   │   └── purchases/  # Purchase orders (master-detail)
│   └── widgets/        # Reusable widgets
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

## Implemented Screens

### Dashboard (Phase 3 Part 1)
- Sales and purchases trend charts (LineChart)
- Profit summary with PieChart
- Recent invoices and purchases lists
- Inventory alerts
- Top customers bar chart
- Responsive layout (Desktop/Tablet/Mobile)
- RTL (Right-to-Left) support

### Customers (Phase 3 Part 1)
- Full CRUD operations (Create, Read, Update, Delete)
- Search and filter functionality
- Data table view (Desktop)
- Card list view (Mobile)
- Customer details dialog
- Balance and credit limit tracking
- Active/inactive status toggle

### Suppliers (Phase 3 Part 1)
- Full CRUD operations (Create, Read, Update, Delete)
- Search and filter functionality
- Data table view (Desktop)
- Card list view (Mobile)
- Supplier details dialog
- Balance tracking (payables)
- Active/inactive status toggle

### Products (Phase 3 Part 2)
- Full CRUD operations with SKU management
- Categories management in separate tab
- Stock level indicators (low stock, out of stock, available)
- Unit of measurement support (piece, kg, liter, meter, box)
- Cost price and sale price tracking
- Search by name, SKU, or barcode
- Filter by category
- Responsive data table and card views

### Invoices (Phase 3 Part 2)
- Master-detail UI for invoice management
- Multi-item invoice creation
- Automatic subtotal, tax (15% VAT), and total calculation
- Invoice status workflow (draft → confirmed → paid → cancelled)
- Payment tracking with progress indicators
- **Automatic stock deduction** on invoice confirmation
- **Customer balance updates** on confirmation
- Stock restoration on cancellation
- Responsive layout with invoice list and detail panel

### Purchases (Phase 3 Part 2)
- Master-detail UI for purchase order management
- Multi-item purchase order creation
- Shipping cost calculation
- Purchase status workflow (draft → confirmed → received → cancelled)
- **Goods receipt with automatic stock addition**
- Supplier payment tracking
- **Supplier balance updates**
- Responsive layout with purchase list and detail panel

## Automatic Stock Management

The system automatically manages inventory levels:

| Action | Stock Impact | Balance Impact |
|--------|--------------|----------------|
| Confirm Invoice | Deduct quantities | Increase customer receivables |
| Cancel Confirmed Invoice | Restore quantities | Decrease customer receivables |
| Receive Purchase Order | Add quantities | Increase supplier payables |
| Cancel Received Purchase | No change (irreversible) | Decrease supplier payables |
| Record Payment | No change | Decrease receivables/payables |

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
flutter pub run build_runner build --delete-conflicting-outputs

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

## Development Progress

### Phase 1: Deep Project Analysis ✅
- Analyzed 17 database models
- Mapped all API routes
- Selected technology stack
- Proposed Flutter project structure

### Phase 2: Project Initialization & Architecture ✅
- Initialized Flutter project
- Implemented all 17 Drift database tables
- Configured Riverpod providers
- Set up go_router navigation

### Phase 3 (Part 1): Core UI Conversion ✅
- Dashboard with fl_chart analytics
- Customers with full CRUD
- Suppliers with full CRUD
- Responsive layouts
- RTL support

### Phase 3 (Part 2): Core UI Conversion ✅
- Products management with categories
- Invoices management with multi-item support
- Purchases management with multi-item support
- Automatic stock level updates
- Customer/Supplier balance tracking
- Master-detail responsive layouts

### Phase 4: Business Logic & Integration (Upcoming)
- Accounting module
- Reports generation
- PDF export

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.
