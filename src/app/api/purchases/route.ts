import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

// GET - Fetch all purchases
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const status = searchParams.get('status') || ''
    
    const purchases = await db.purchase.findMany({
      where: status ? { status } : {},
      include: {
        supplier: true,
        items: {
          include: { product: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    })
    
    return NextResponse.json({ purchases })
  } catch (error) {
    console.error('Error fetching purchases:', error)
    return NextResponse.json({ error: 'Failed to fetch purchases' }, { status: 500 })
  }
}

// POST - Create a new purchase
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    // Generate purchase number
    const lastPurchase = await db.purchase.findFirst({
      orderBy: { createdAt: 'desc' }
    })
    const purchaseNumber = lastPurchase 
      ? `PO-${String(parseInt(lastPurchase.purchaseNumber.split('-')[1] || '0') + 1).padStart(6, '0')}`
      : 'PO-000001'
    
    const subtotal = body.items.reduce((sum: number, item: { total: number }) => sum + item.total, 0)
    const taxAmount = body.taxAmount || 0
    const total = subtotal + taxAmount
    
    const purchase = await db.purchase.create({
      data: {
        purchaseNumber,
        supplierId: body.supplierId,
        userId: body.userId || 'default-user',
        date: new Date(body.date || new Date()),
        status: body.status || 'draft',
        subtotal,
        taxAmount,
        total,
        notes: body.notes || null,
        items: {
          create: body.items.map((item: { productId: string; description: string; quantity: number; unitPrice: number; total: number }) => ({
            productId: item.productId,
            description: item.description || null,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            total: item.total
          }))
        }
      },
      include: {
        items: { include: { product: true } },
        supplier: true
      }
    })
    
    // Update product quantities
    for (const item of body.items) {
      await db.product.update({
        where: { id: item.productId },
        data: {
          quantity: { increment: item.quantity },
          costPrice: item.unitPrice
        }
      })
    }
    
    return NextResponse.json({ purchase })
  } catch (error) {
    console.error('Error creating purchase:', error)
    return NextResponse.json({ error: 'Failed to create purchase' }, { status: 500 })
  }
}
