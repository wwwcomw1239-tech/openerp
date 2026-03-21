# OpenERP Flutter

Open Source ERP System - Flutter Desktop & Mobile Application

## Overview

A complete, production-ready ERP (Enterprise Resource Planning) system built with Flutter, featuring double-entry accounting, inventory management, CRM, and financial reporting with full Arabic RTL support.

## Features

- ✅ **Dashboard** - Analytics, KPIs, charts with fl_chart
- ✅ **CRM** - Customer & Supplier management with full CRUD
- ✅ **Inventory** - Product & stock management with automatic updates
- ✅ **Invoicing** - Sales invoices with multi-item support and stock deduction
- ✅ **Purchasing** - Purchase orders with goods receipt and stock addition
- ✅ **Accounting** - Chart of Accounts with double-entry enforcement
- ✅ **Reports** - Financial reports with PDF export

## Technology Stack

| Component | Technology |
|-----------|------------|
| **Framework** | Flutter 3.16+ |
| **State Management** | Riverpod 2.0 |
| **Database** | Drift (SQLite) |
| **Navigation** | go_router |
| **Charts** | fl_chart |
| **PDF Export** | pdf + printing (Arabic RTL) |

## Database Schema

17 tables with full double-entry accounting support:

- **Core**: Users, Companies
- **CRM**: Customers, Suppliers
- **Inventory**: Categories, Products
- **Sales**: Invoices, InvoiceItems, Payments
- **Purchasing**: Purchases, PurchaseItems, SupplierPayments
- **Accounting**: Accounts, JournalEntries, JournalLines
- **Analytics**: ActivityLogs

## Implemented Modules

### Dashboard
- Sales and purchases trend charts
- Profit summary with PieChart
- Recent invoices and purchases
- Inventory alerts
- Top customers analysis

### CRM
- Customer management with balance tracking
- Supplier management with payables
- Search, filter, and CRUD operations

### Inventory
- Product management with SKU/barcode
- Category management
- Stock level indicators
- Automatic stock updates

### Invoicing
- Master-detail UI with line items
- 15% VAT calculation
- Status workflow (draft → confirmed → paid)
- Stock deduction on confirmation
- PDF export with Arabic RTL

### Purchasing
- Purchase order management
- Goods receipt with stock addition
- Supplier payment tracking
- PDF export

### Accounting (Double-Entry)
- **Chart of Accounts**: Hierarchical tree view
- **Journal Entries**: Strict double-entry enforcement
  - **CRITICAL**: Cannot save unless Debits = Credits
  - Real-time balance validation
  - Automatic account balance updates

### Financial Reports
- Trial Balance with verification
- Income Statement (Profit & Loss)
- Balance Sheet
- PDF export with Arabic font support

## PDF Export Features

- Arabic RTL text rendering with Cairo font
- Professional invoice formatting
- Financial statement exports
- Print and save functionality

## Automatic Stock Management

| Action | Stock Impact | Balance Impact |
|--------|--------------|----------------|
| Confirm Invoice | Deduct quantities | Increase receivables |
| Cancel Invoice | Restore quantities | Decrease receivables |
| Receive Purchase | Add quantities | Increase payables |
| Record Payment | - | Decrease balances |

## Double-Entry Accounting Rules

| Rule | Enforcement |
|------|-------------|
| Debits = Credits | ✅ Validated before save |
| Account Types | Asset, Liability, Equity, Income, Expense |
| Normal Balance | Debit or Credit per account |
| Posting | Updates account balances |
| Cancellation | Creates reversing entry |

## Getting Started

```bash
# Clone
git clone https://github.com/wwwcomw1239-tech/openerp.git
cd openerp/openerp_flutter

# Install
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run
flutter run -d windows  # Desktop
flutter run -d android  # Mobile
```

## Project Structure

```
lib/
├── core/           # Theme, router, constants
├── data/           # Database, models
├── logic/          # Riverpod providers
│   ├── customers_provider.dart
│   ├── suppliers_provider.dart
│   ├── products_provider.dart
│   ├── invoices_provider.dart
│   ├── purchases_provider.dart
│   ├── accounts_provider.dart
│   ├── journal_entries_provider.dart
│   └── financial_reports_provider.dart
├── services/       # PDF export, utilities
├── ui/             # Screens and widgets
└── main.dart
```

## Development Progress

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | ✅ | Deep Project Analysis |
| Phase 2 | ✅ | Project Initialization & Database |
| Phase 3 Part 1 | ✅ | Dashboard, Customers, Suppliers |
| Phase 3 Part 2 | ✅ | Products, Invoices, Purchases |
| Phase 4 | ✅ | Accounting, Reports, PDF Export |

## License

MIT License
