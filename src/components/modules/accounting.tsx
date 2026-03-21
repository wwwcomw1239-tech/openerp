'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Plus, Calculator, TrendingUp, TrendingDown, DollarSign } from 'lucide-react'
import { toast } from 'sonner'

interface Account {
  id: string
  code: string
  name: string
  type: string
  parentId: string | null
  balance: number
  isActive: boolean
}

export function AccountingModule() {
  const [accounts, setAccounts] = useState<Account[]>([])
  const [isLoading, setIsLoading] = useState(true)

  const fetchAccounts = async () => {
    try {
      const response = await fetch('/api/accounts')
      const data = await response.json()
      setAccounts(data.accounts)
    } catch {
      console.error('Error fetching accounts')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchAccounts()
  }, [])

  const getTypeLabel = (type: string) => {
    const labels: Record<string, string> = {
      asset: 'أصول',
      liability: 'خصوم',
      equity: 'حقوق ملكية',
      income: 'إيرادات',
      expense: 'مصروفات',
    }
    return labels[type] || type
  }

  const getTypeBadge = (type: string) => {
    const styles: Record<string, string> = {
      asset: 'bg-blue-100 text-blue-600',
      liability: 'bg-red-100 text-red-600',
      equity: 'bg-purple-100 text-purple-600',
      income: 'bg-emerald-100 text-emerald-600',
      expense: 'bg-orange-100 text-orange-600',
    }
    return <Badge className={styles[type] || 'bg-slate-100'}>{getTypeLabel(type)}</Badge>
  }

  // Group accounts by type
  const groupedAccounts = accounts.reduce((acc, account) => {
    const type = account.type
    if (!acc[type]) acc[type] = []
    acc[type].push(account)
    return acc
  }, {} as Record<string, Account[]>)

  // Calculate totals
  const totals = Object.entries(groupedAccounts).reduce((acc, [type, accounts]) => {
    acc[type] = accounts.reduce((sum, a) => sum + a.balance, 0)
    return acc
  }, {} as Record<string, number>)

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 dark:text-white">المحاسبة</h1>
          <p className="text-slate-500 dark:text-slate-400">شجرة الحسابات والقيود المحاسبية</p>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
                <TrendingUp className="w-6 h-6 text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-slate-500">إجمالي الأصول</p>
                <p className="text-xl font-bold text-slate-800">{(totals.asset || 0).toLocaleString()} ر.س</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-red-100 rounded-xl flex items-center justify-center">
                <TrendingDown className="w-6 h-6 text-red-600" />
              </div>
              <div>
                <p className="text-sm text-slate-500">إجمالي الخصوم</p>
                <p className="text-xl font-bold text-slate-800">{(totals.liability || 0).toLocaleString()} ر.س</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center">
                <DollarSign className="w-6 h-6 text-emerald-600" />
              </div>
              <div>
                <p className="text-sm text-slate-500">إجمالي الإيرادات</p>
                <p className="text-xl font-bold text-slate-800">{(totals.income || 0).toLocaleString()} ر.س</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center">
                <Calculator className="w-6 h-6 text-orange-600" />
              </div>
              <div>
                <p className="text-sm text-slate-500">إجمالي المصروفات</p>
                <p className="text-xl font-bold text-slate-800">{(totals.expense || 0).toLocaleString()} ر.س</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Chart of Accounts */}
      <Card>
        <CardHeader>
          <CardTitle>شجرة الحسابات</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="p-8 text-center text-slate-400">جاري التحميل...</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>رمز الحساب</TableHead>
                  <TableHead>اسم الحساب</TableHead>
                  <TableHead>النوع</TableHead>
                  <TableHead>الرصيد</TableHead>
                  <TableHead>الحالة</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {accounts.map((account) => (
                  <TableRow key={account.id}>
                    <TableCell className="font-mono">{account.code}</TableCell>
                    <TableCell className="font-medium">{account.name}</TableCell>
                    <TableCell>{getTypeBadge(account.type)}</TableCell>
                    <TableCell className="font-medium">{account.balance.toLocaleString()} ر.س</TableCell>
                    <TableCell>
                      <Badge className={account.isActive ? 'bg-emerald-100 text-emerald-600' : 'bg-slate-100 text-slate-600'}>
                        {account.isActive ? 'نشط' : 'غير نشط'}
                      </Badge>
                    </TableCell>
                  </TableRow>
                ))}
                {accounts.length === 0 && (
                  <TableRow><TableCell colSpan={5} className="text-center py-8 text-slate-400">لا يوجد حسابات</TableCell></TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
