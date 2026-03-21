import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'

// GET - Fetch all accounts (Chart of Accounts)
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const type = searchParams.get('type') || ''
    
    const accounts = await db.account.findMany({
      where: type ? { type } : {},
      orderBy: { code: 'asc' }
    })
    
    return NextResponse.json({ accounts })
  } catch (error) {
    console.error('Error fetching accounts:', error)
    return NextResponse.json({ error: 'Failed to fetch accounts' }, { status: 500 })
  }
}

// POST - Create a new account
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    const account = await db.account.create({
      data: {
        code: body.code,
        name: body.name,
        type: body.type,
        parentId: body.parentId || null,
      }
    })
    
    return NextResponse.json({ account })
  } catch (error) {
    console.error('Error creating account:', error)
    return NextResponse.json({ error: 'Failed to create account' }, { status: 500 })
  }
}
