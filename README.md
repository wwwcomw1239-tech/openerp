<div align="center">

# 🚀 OpenERP

### نظام إدارة موارد المؤسسات مفتوح المصدر

**مشابه لـ Odoo - مبنية بـ Next.js 16**

[![Next.js](https://img.shields.io/badge/Next.js-16.1-black?style=flat-square&logo=next.js)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue?style=flat-square&logo=typescript)](https://www.typescriptlang.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-4.0-38B2AC?style=flat-square&logo=tailwind-css)](https://tailwindcss.com/)
[![Prisma](https://img.shields.io/badge/Prisma-6.0-2D3748?style=flat-square&logo=prisma)](https://www.prisma.io/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

[📸 Screenshots](#-screenshots) • [✨ Features](#-features) • [🚀 Quick Start](#-quick-start) • [📖 Documentation](#-documentation)

</div>

---

## 📸 Screenshots

| Dashboard | Invoices | Products |
|-----------|----------|----------|
| ![Dashboard](docs/screenshots/dashboard.png) | ![Invoices](docs/screenshots/invoices.png) | ![Products](docs/screenshots/products.png) |

---

## ✨ Features

### 🎯 Core Modules

| Module | Description | Status |
|--------|-------------|--------|
| 📊 **Dashboard** | Analytics, charts, KPIs, alerts | ✅ Complete |
| 👥 **CRM** | Customer management, contacts, history | ✅ Complete |
| 🚚 **Suppliers** | Supplier management, purchase tracking | ✅ Complete |
| 📦 **Inventory** | Products, stock levels, alerts | ✅ Complete |
| 🧾 **Invoicing** | Sales invoices, multi-item, auto-calc | ✅ Complete |
| 🛒 **Purchases** | Purchase orders, auto stock update | ✅ Complete |
| 📒 **Accounting** | Chart of accounts, journal entries | ✅ Complete |
| 📈 **Reports** | Financial reports, profit analysis | ✅ Complete |

### 🔥 Key Features

- ✅ **Modern UI/UX** - Built with shadcn/ui components
- ✅ **Responsive Design** - Works on desktop, tablet, and mobile
- ✅ **RTL Support** - Full Arabic language support
- ✅ **Real-time Updates** - Instant data synchronization
- ✅ **RESTful API** - Complete API for integrations
- ✅ **SQLite Database** - Easy setup, no external DB needed
- ✅ **Type-Safe** - Full TypeScript implementation

---

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ 
- Bun or npm
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/openerp.git

# Navigate to project
cd openerp

# Install dependencies
bun install

# Setup database
bun run db:push

# Start development server
bun run dev
```

### Access the Application

Open [http://localhost:3000](http://localhost:3000) in your browser.

**Default Login:**
- Email: `admin@erp.com`
- Password: `admin123`

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Next.js 16 (App Router) |
| **Language** | TypeScript 5 |
| **Styling** | Tailwind CSS 4 + shadcn/ui |
| **Database** | Prisma ORM + SQLite |
| **State** | Zustand |
| **Icons** | Lucide React |
| **Charts** | Recharts |

---

## 📁 Project Structure

```
openerp/
├── 📂 prisma/
│   └── schema.prisma          # Database schema
├── 📂 src/
│   ├── 📂 app/
│   │   ├── 📂 api/            # API Routes
│   │   ├── layout.tsx         # Root layout
│   │   └── page.tsx           # Main page
│   ├── 📂 components/
│   │   ├── 📂 layout/         # Layout components
│   │   ├── 📂 modules/        # Module components
│   │   └── 📂 ui/             # UI components
│   └── 📂 lib/
│       ├── db.ts              # Database client
│       ├── auth.ts            # Authentication
│       └── erp-store.ts       # State management
├── package.json
└── README.md
```

---

## 📖 API Documentation

### Customers API

```typescript
GET    /api/customers        # List all customers
POST   /api/customers        # Create customer
GET    /api/customers/:id    # Get customer
PUT    /api/customers/:id    # Update customer
DELETE /api/customers/:id    # Delete customer
```

### Products API

```typescript
GET    /api/products         # List all products
POST   /api/products         # Create product
GET    /api/products/:id     # Get product
PUT    /api/products/:id     # Update product
DELETE /api/products/:id     # Delete product
```

### Invoices API

```typescript
GET    /api/invoices         # List all invoices
POST   /api/invoices         # Create invoice
GET    /api/invoices/:id     # Get invoice details
```

### Dashboard API

```typescript
GET    /api/dashboard        # Get dashboard statistics
```

---

## 🔧 Configuration

### Environment Variables

Create a `.env` file:

```env
DATABASE_URL="file:./db/custom.db"
NEXTAUTH_SECRET="your-secret-key"
NEXTAUTH_URL="http://localhost:3000"
```

### Database Models

The system includes these models:
- **User** - System users
- **Customer** - CRM customers
- **Supplier** - Suppliers
- **Product** - Inventory items
- **Category** - Product categories
- **Invoice** - Sales invoices
- **InvoiceItem** - Invoice line items
- **Purchase** - Purchase orders
- **PurchaseItem** - Purchase line items
- **Account** - Chart of accounts
- **JournalEntry** - Accounting entries

---

## 📦 Deployment

### Docker

```bash
# Build image
docker build -t openerp .

# Run container
docker run -p 3000:3000 openerp
```

### Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel
```

### Self-Hosted

```bash
# Build for production
bun run build

# Start production server
bun run start
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 💬 Support

- 📧 Email: support@openerp.com
- 💬 Discord: [Join our community](https://discord.gg/openerp)
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/openerp/issues)

---

## ⭐ Show Your Support

If this project helped you, please consider giving it a ⭐️ on GitHub!

---

<div align="center">

**Made with ❤️ by OpenERP Team**

</div>
