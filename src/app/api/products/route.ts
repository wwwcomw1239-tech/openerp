import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

// GET - Fetch all products
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const search = searchParams.get('search') || ''
    const categoryId = searchParams.get('categoryId') || ''
    
    const products = await db.product.findMany({
      where: {
        AND: [
          {
            OR: [
              { name: { contains: search } },
              { sku: { contains: search } },
              { barcode: { contains: search } },
            ]
          },
          categoryId ? { categoryId } : {}
        ]
      },
      include: { category: true },
      orderBy: { createdAt: 'desc' }
    })
    
    return NextResponse.json({ products })
  } catch (error) {
    console.error('Error fetching products:', error)
    return NextResponse.json({ error: 'Failed to fetch products' }, { status: 500 })
  }
}

// POST - Create a new product
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    const product = await db.product.create({
      data: {
        sku: body.sku,
        name: body.name,
        description: body.description || null,
        categoryId: body.categoryId || null,
        unit: body.unit || 'piece',
        costPrice: parseFloat(body.costPrice) || 0,
        salePrice: parseFloat(body.salePrice) || 0,
        quantity: parseFloat(body.quantity) || 0,
        minQuantity: parseFloat(body.minQuantity) || 0,
        maxQuantity: parseFloat(body.maxQuantity) || 0,
        barcode: body.barcode || null,
      }
    })
    
    return NextResponse.json({ product })
  } catch (error) {
    console.error('Error creating product:', error)
    return NextResponse.json({ error: 'Failed to create product' }, { status: 500 })
  }
}
