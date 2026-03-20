import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

// GET - Fetch all invoices
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const status = searchParams.get('status') || ''
    
    const invoices = await db.invoice.findMany({
      where: status ? { status } : {},
      include: {
        customer: true,
        items: {
          include: { product: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    })
    
    return NextResponse.json({ invoices })
  } catch (error) {
    console.error('Error fetching invoices:', error)
    return NextResponse.json({ error: 'Failed to fetch invoices' }, { status: 500 })
  }
}

// POST - Create a new invoice
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    // Generate invoice number
    const lastInvoice = await db.invoice.findFirst({
      orderBy: { createdAt: 'desc' }
    })
    const invoiceNumber = lastInvoice 
      ? `INV-${String(parseInt(lastInvoice.invoiceNumber.split('-')[1] || '0') + 1).padStart(6, '0')}`
      : 'INV-000001'
    
    const subtotal = body.items.reduce((sum: number, item: { total: number }) => sum + item.total, 0)
    const taxAmount = body.taxAmount || 0
    const discount = body.discount || 0
    const total = subtotal + taxAmount - discount
    
    const invoice = await db.invoice.create({
      data: {
        invoiceNumber,
        customerId: body.customerId,
        userId: body.userId || 'default-user',
        date: new Date(body.date || new Date()),
        dueDate: body.dueDate ? new Date(body.dueDate) : null,
        status: body.status || 'draft',
        subtotal,
        taxAmount,
        discount,
        total,
        notes: body.notes || null,
        items: {
          create: body.items.map((item: { productId: string; description: string; quantity: number; unitPrice: number; discount: number; taxRate: number; total: number }) => ({
            productId: item.productId,
            description: item.description || null,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            discount: item.discount || 0,
            taxRate: item.taxRate || 0,
            total: item.total
          }))
        }
      },
      include: {
        items: { include: { product: true } },
        customer: true
      }
    })
    
    // Update product quantities
    for (const item of body.items) {
      await db.product.update({
        where: { id: item.productId },
        data: {
          quantity: { decrement: item.quantity }
        }
      })
    }
    
    return NextResponse.json({ invoice })
  } catch (error) {
    console.error('Error creating invoice:', error)
    return NextResponse.json({ error: 'Failed to create invoice' }, { status: 500 })
  }
}
