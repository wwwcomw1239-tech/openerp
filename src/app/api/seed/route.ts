import { NextResponse } from 'next/server'
import { db } from '@/lib/db'

// POST - Seed initial data
export async function POST() {
  try {
    // Create default user
    const user = await db.user.upsert({
      where: { email: 'admin@erp.com' },
      update: {},
      create: {
        email: 'admin@erp.com',
        name: 'Admin User',
        password: 'admin123',
        role: 'admin'
      }
    })
    
    // Create sample customers
    const customers = await Promise.all([
      db.customer.upsert({
        where: { id: 'customer-1' },
        update: {},
        create: {
          id: 'customer-1',
          name: 'شركة الأمل للتجارة',
          email: 'alamal@example.com',
          phone: '+966501234567',
          city: 'الرياض',
          country: 'السعودية'
        }
      }),
      db.customer.upsert({
        where: { id: 'customer-2' },
        update: {},
        create: {
          id: 'customer-2',
          name: 'مؤسسة النور',
          email: 'alnoor@example.com',
          phone: '+966507654321',
          city: 'جدة',
          country: 'السعودية'
        }
      }),
      db.customer.upsert({
        where: { id: 'customer-3' },
        update: {},
        create: {
          id: 'customer-3',
          name: 'شركة التقدم',
          email: 'altaqadum@example.com',
          phone: '+966509876543',
          city: 'الدمام',
          country: 'السعودية'
        }
      })
    ])
    
    // Create sample suppliers
    const suppliers = await Promise.all([
      db.supplier.upsert({
        where: { id: 'supplier-1' },
        update: {},
        create: {
          id: 'supplier-1',
          name: 'مورد الخير',
          email: 'alkhair@example.com',
          phone: '+966511111111',
          city: 'الرياض',
          country: 'السعودية'
        }
      }),
      db.supplier.upsert({
        where: { id: 'supplier-2' },
        update: {},
        create: {
          id: 'supplier-2',
          name: 'شركة الإمداد',
          email: 'alimdad@example.com',
          phone: '+966522222222',
          city: 'جدة',
          country: 'السعودية'
        }
      })
    ])
    
    // Create sample categories
    const category = await db.category.upsert({
      where: { id: 'category-1' },
      update: {},
      create: {
        id: 'category-1',
        name: 'منتجات عامة',
        description: 'فئة المنتجات العامة'
      }
    })
    
    // Create sample products
    const products = await Promise.all([
      db.product.upsert({
        where: { sku: 'PRD-001' },
        update: {},
        create: {
          sku: 'PRD-001',
          name: 'لابتوب احترافي',
          description: 'لابتوب بمعالج حديث وذاكرة كبيرة',
          categoryId: 'category-1',
          unit: 'piece',
          costPrice: 2500,
          salePrice: 3200,
          quantity: 50,
          minQuantity: 10
        }
      }),
      db.product.upsert({
        where: { sku: 'PRD-002' },
        update: {},
        create: {
          sku: 'PRD-002',
          name: 'طابعة ليزر',
          description: 'طابعة ليزر عالية السرعة',
          categoryId: 'category-1',
          unit: 'piece',
          costPrice: 800,
          salePrice: 1100,
          quantity: 30,
          minQuantity: 5
        }
      }),
      db.product.upsert({
        where: { sku: 'PRD-003' },
        update: {},
        create: {
          sku: 'PRD-003',
          name: 'شاشة عرض',
          description: 'شاشة عرض 27 بوصة',
          categoryId: 'category-1',
          unit: 'piece',
          costPrice: 600,
          salePrice: 850,
          quantity: 25,
          minQuantity: 5
        }
      }),
      db.product.upsert({
        where: { sku: 'PRD-004' },
        update: {},
        create: {
          sku: 'PRD-004',
          name: 'لوحة مفاتيح',
          description: 'لوحة مفاتيح ميكانيكية',
          categoryId: 'category-1',
          unit: 'piece',
          costPrice: 150,
          salePrice: 250,
          quantity: 100,
          minQuantity: 20
        }
      }),
      db.product.upsert({
        where: { sku: 'PRD-005' },
        update: {},
        create: {
          sku: 'PRD-005',
          name: 'فأرة لاسلكية',
          description: 'فأرة لاسلكية مريحة',
          categoryId: 'category-1',
          unit: 'piece',
          costPrice: 50,
          salePrice: 100,
          quantity: 200,
          minQuantity: 30
        }
      })
    ])
    
    // Create chart of accounts
    const accounts = await Promise.all([
      db.account.upsert({
        where: { code: '1000' },
        update: {},
        create: { code: '1000', name: 'الأصول', type: 'asset' }
      }),
      db.account.upsert({
        where: { code: '1100' },
        update: {},
        create: { code: '1100', name: 'النقدية', type: 'asset', parentId: '1000' }
      }),
      db.account.upsert({
        where: { code: '1200' },
        update: {},
        create: { code: '1200', name: 'الذمم المدينة', type: 'asset', parentId: '1000' }
      }),
      db.account.upsert({
        where: { code: '1300' },
        update: {},
        create: { code: '1300', name: 'المخزون', type: 'asset', parentId: '1000' }
      }),
      db.account.upsert({
        where: { code: '2000' },
        update: {},
        create: { code: '2000', name: 'الخصوم', type: 'liability' }
      }),
      db.account.upsert({
        where: { code: '2100' },
        update: {},
        create: { code: '2100', name: 'الذمم الدائنة', type: 'liability', parentId: '2000' }
      }),
      db.account.upsert({
        where: { code: '3000' },
        update: {},
        create: { code: '3000', name: 'حقوق الملكية', type: 'equity' }
      }),
      db.account.upsert({
        where: { code: '4000' },
        update: {},
        create: { code: '4000', name: 'الإيرادات', type: 'income' }
      }),
      db.account.upsert({
        where: { code: '4100' },
        update: {},
        create: { code: '4100', name: 'مبيعات', type: 'income', parentId: '4000' }
      }),
      db.account.upsert({
        where: { code: '5000' },
        update: {},
        create: { code: '5000', name: 'المصروفات', type: 'expense' }
      }),
      db.account.upsert({
        where: { code: '5100' },
        update: {},
        create: { code: '5100', name: 'تكلفة البضاعة المباعة', type: 'expense', parentId: '5000' }
      })
    ])
    
    return NextResponse.json({
      success: true,
      message: 'Database seeded successfully',
      data: {
        user: user.email,
        customers: customers.length,
        suppliers: suppliers.length,
        products: products.length,
        accounts: accounts.length
      }
    })
  } catch (error) {
    console.error('Error seeding database:', error)
    return NextResponse.json({ error: 'Failed to seed database' }, { status: 500 })
  }
}
