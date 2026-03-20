'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { BarChart3, TrendingUp, TrendingDown, DollarSign, Package, Users, FileText, Download } from 'lucide-react'

interface DashboardStats {
  customersCount: number
  suppliersCount: number
  productsCount: number
  invoicesCount: number
  purchasesCount: number
  totalSales: number
  totalPurchases: number
  profit: number
}

export function ReportsModule() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch('/api/dashboard')
        const data = await response.json()
        setStats(data.stats)
      } catch {
        console.error('Error fetching data')
      } finally {
        setIsLoading(false)
      }
    }
    fetchData()
  }, [])

  if (isLoading) {
    return <div className="p-8 text-center text-slate-400">جاري التحميل...</div>
  }

  const profitMargin = stats?.totalSales ? ((stats.profit / stats.totalSales) * 100).toFixed(1) : 0

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 dark:text-white">التقارير المالية</h1>
          <p className="text-slate-500 dark:text-slate-400">تحليل الأداء المالي والتقارير</p>
        </div>
        <Button className="bg-emerald-600 hover:bg-emerald-700" onClick={() => window.open('/api/reports/export', '_blank')}>
          <Download className="w-4 h-4 ml-2" />
          تصدير التقرير
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-xl flex items-center justify-center shadow-lg">
                <TrendingUp className="w-7 h-7 text-white" />
              </div>
              <div>
                <p className="text-sm text-slate-500">إجمالي المبيعات</p>
                <p className="text-2xl font-bold text-slate-800">{(stats?.totalSales || 0).toLocaleString()} ر.س</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 bg-gradient-to-br from-orange-500 to-amber-500 rounded-xl flex items-center justify-center shadow-lg">
                <TrendingDown className="w-7 h-7 text-white" />
              </div>
              <div>
                <p className="text-sm text-slate-500">إجمالي المشتريات</p>
                <p className="text-2xl font-bold text-slate-800">{(stats?.totalPurchases || 0).toLocaleString()} ر.س</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-500 rounded-xl flex items-center justify-center shadow-lg">
                <DollarSign className="w-7 h-7 text-white" />
              </div>
              <div>
                <p className="text-sm text-slate-500">صافي الربح</p>
                <p className="text-2xl font-bold text-slate-800">{(stats?.profit || 0).toLocaleString()} ر.س</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>مؤشرات الأداء</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-emerald-100 rounded-lg flex items-center justify-center">
                  <TrendingUp className="w-5 h-5 text-emerald-600" />
                </div>
                <div>
                  <p className="font-medium">هامش الربح</p>
                  <p className="text-sm text-slate-500">نسبة الربح من المبيعات</p>
                </div>
              </div>
              <p className="text-2xl font-bold text-emerald-600">{profitMargin}%</p>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                  <Users className="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <p className="font-medium">عدد العملاء</p>
                  <p className="text-sm text-slate-500">إجمالي العملاء المسجلين</p>
                </div>
              </div>
              <p className="text-2xl font-bold">{stats?.customersCount || 0}</p>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                  <Package className="w-5 h-5 text-purple-600" />
                </div>
                <div>
                  <p className="font-medium">عدد المنتجات</p>
                  <p className="text-sm text-slate-500">إجمالي المنتجات في المخزون</p>
                </div>
              </div>
              <p className="text-2xl font-bold">{stats?.productsCount || 0}</p>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
                  <FileText className="w-5 h-5 text-orange-600" />
                </div>
                <div>
                  <p className="font-medium">عدد الفواتير</p>
                  <p className="text-sm text-slate-500">إجمالي الفواتير المصدرة</p>
                </div>
              </div>
              <p className="text-2xl font-bold">{stats?.invoicesCount || 0}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>ملخص الأعمال</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>البند</TableHead>
                  <TableHead>القيمة</TableHead>
                  <TableHead>النسبة</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                <TableRow>
                  <TableCell className="font-medium">إجمالي المبيعات</TableCell>
                  <TableCell>{stats?.totalSales?.toLocaleString() || 0} ر.س</TableCell>
                  <TableCell><Badge className="bg-emerald-100 text-emerald-600">100%</Badge></TableCell>
                </TableRow>
                <TableRow>
                  <TableCell className="font-medium">تكلفة المشتريات</TableCell>
                  <TableCell>{stats?.totalPurchases?.toLocaleString() || 0} ر.س</TableCell>
                  <TableCell>
                    <Badge className="bg-orange-100 text-orange-600">
                      {stats?.totalSales ? ((stats.totalPurchases / stats.totalSales) * 100).toFixed(1) : 0}%
                    </Badge>
                  </TableCell>
                </TableRow>
                <TableRow>
                  <TableCell className="font-medium">صافي الربح</TableCell>
                  <TableCell className="font-bold text-emerald-600">{stats?.profit?.toLocaleString() || 0} ر.س</TableCell>
                  <TableCell><Badge className="bg-blue-100 text-blue-600">{profitMargin}%</Badge></TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>التقارير المتاحة</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {[
              { name: 'الميزانية العمومية', icon: BarChart3 },
              { name: 'قائمة الدخل', icon: TrendingUp },
              { name: 'تقرير المبيعات', icon: FileText },
              { name: 'تقرير المخزون', icon: Package },
            ].map((report, index) => {
              const Icon = report.icon
              return (
                <Button key={index} variant="outline" className="h-20 flex flex-col gap-2">
                  <Icon className="w-5 h-5" />
                  <span>{report.name}</span>
                </Button>
              )
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
