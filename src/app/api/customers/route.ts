import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

// GET - Fetch all customers
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const search = searchParams.get('search') || ''
    
    const customers = await db.customer.findMany({
      where: {
        OR: [
          { name: { contains: search } },
          { email: { contains: search } },
          { phone: { contains: search } },
        ]
      },
      orderBy: { createdAt: 'desc' }
    })
    
    return NextResponse.json({ customers })
  } catch (error) {
    console.error('Error fetching customers:', error)
    return NextResponse.json({ error: 'Failed to fetch customers' }, { status: 500 })
  }
}

// POST - Create a new customer
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    const customer = await db.customer.create({
      data: {
        name: body.name,
        email: body.email || null,
        phone: body.phone || null,
        mobile: body.mobile || null,
        address: body.address || null,
        city: body.city || null,
        country: body.country || null,
        taxNumber: body.taxNumber || null,
        creditLimit: parseFloat(body.creditLimit) || 0,
        notes: body.notes || null,
      }
    })
    
    return NextResponse.json({ customer })
  } catch (error) {
    console.error('Error creating customer:', error)
    return NextResponse.json({ error: 'Failed to create customer' }, { status: 500 })
  }
}
