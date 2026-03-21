import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

// GET - Fetch all suppliers
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const search = searchParams.get('search') || ''
    
    const suppliers = await db.supplier.findMany({
      where: {
        OR: [
          { name: { contains: search } },
          { email: { contains: search } },
          { phone: { contains: search } },
        ]
      },
      orderBy: { createdAt: 'desc' }
    })
    
    return NextResponse.json({ suppliers })
  } catch (error) {
    console.error('Error fetching suppliers:', error)
    return NextResponse.json({ error: 'Failed to fetch suppliers' }, { status: 500 })
  }
}

// POST - Create a new supplier
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    const supplier = await db.supplier.create({
      data: {
        name: body.name,
        email: body.email || null,
        phone: body.phone || null,
        mobile: body.mobile || null,
        address: body.address || null,
        city: body.city || null,
        country: body.country || null,
        taxNumber: body.taxNumber || null,
        notes: body.notes || null,
      }
    })
    
    return NextResponse.json({ supplier })
  } catch (error) {
    console.error('Error creating supplier:', error)
    return NextResponse.json({ error: 'Failed to create supplier' }, { status: 500 })
  }
}
