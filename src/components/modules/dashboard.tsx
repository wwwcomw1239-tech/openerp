'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { 
  Users, 
  Package, 
  FileText, 
  ShoppingCart, 
  TrendingUp,
  TrendingDown,
  DollarSign,
  AlertTriangle,
  ArrowLeft
} from 'lucide-react'

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

interface ChartData {
  month: string
  total: number
}

interface RecentInvoice {
  id: string
  invoiceNumber: string
  total: number
  status: string
  customer: { name: string }
  createdAt: string
}

interface LowStockProduct {
  id: string
  name: string
  sku: string
  quantity: number
  minQuantity: number
}

export function Dashboard() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [chartData, setChartData] = useState<ChartData[]>([])
  const [recentInvoices, setRecentInvoices] = useState<RecentInvoice[]>([])
  const [lowStockProducts, setLowStockProducts] = useState<LowStockProduct[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch('/api/dashboard')
        const data = await response.json()
        setStats(data.stats)
        setChartData(data.chartData)
        setRecentInvoices(data.recentInvoices)
        setLowStockProducts(data.lowStockProducts)
      } catch (error) {
        console.error('Error fetching dashboard data:', error)
      } finally {
        setIsLoading(false)
      }
    }
    fetchData()
  }, [])

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[...Array(8)].map((_, i) => (
          <Card key={i} className="animate-pulse">
            <CardContent className="p-6">
              <div className="h-20 bg-slate-200 rounded"></div>
            </CardContent>
          </Card>
        ))}
      </div>
    )
  }

  const statCards = [
    { 
      title: 'إجمالي المبيعات', 
      value: `${(stats?.totalSales || 0).toLocaleString()} ر.س`, 
      icon: DollarSign, 
      color: 'emerald',
      trend: '+12%'
    },
    { 
      title: 'إجمالي المشتريات', 
      value: `${(stats?.totalPurchases || 0).toLocaleString()} ر.س`, 
      icon: ShoppingCart, 
      color: 'orange',
      trend: '+8%'
    },
    { 
      title: 'الربح الصافي', 
      value: `${(stats?.profit || 0).toLocaleString()} ر.س`, 
      icon: TrendingUp, 
      color: 'blue',
      trend: stats?.profit && stats.profit > 0 ? '+15%' : '-5%'
    },
    { 
      title: 'عدد العملاء', 
      value: stats?.customersCount || 0, 
      icon: Users, 
      color: 'purple',
      trend: '+3'
    },
  ]

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      draft: 'bg-slate-100 text-slate-600',
      confirmed: 'bg-blue-100 text-blue-600',
      paid: 'bg-emerald-100 text-emerald-600',
      cancelled: 'bg-red-100 text-red-600',
    }
    const labels: Record<string, string> = {
      draft: 'مسودة',
      confirmed: 'مؤكد',
      paid: 'مدفوع',
      cancelled: 'ملغي',
    }
    return (
      <Badge className={styles[status] || styles.draft}>
        {labels[status] || status}
      </Badge>
    )
  }

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statCards.map((stat, index) => {
          const Icon = stat.icon
          const colors: Record<string, string> = {
            emerald: 'from-emerald-500 to-teal-500',
            orange: 'from-orange-500 to-amber-500',
            blue: 'from-blue-500 to-indigo-500',
            purple: 'from-purple-500 to-pink-500',
          }
          
          return (
            <Card key={index} className="overflow-hidden">
              <CardContent className="p-0">
                <div className="flex items-center p-6">
                  <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${colors[stat.color]} flex items-center justify-center shadow-lg`}>
                    <Icon className="w-6 h-6 text-white" />
                  </div>
                  <div className="mr-4 flex-1">
                    <p className="text-sm text-slate-500 dark:text-slate-400">{stat.title}</p>
                    <p className="text-2xl font-bold text-slate-800 dark:text-white">{stat.value}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )
        })}
      </div>

      {/* Charts and Tables Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Sales Chart */}
        <Card className="lg:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>المبيعات الشهرية</CardTitle>
            <Button variant="outline" size="sm">
              عرض الكل
              <ArrowLeft className="w-4 h-4 mr-2" />
            </Button>
          </CardHeader>
          <CardContent>
            <div className="h-64 flex items-end gap-4">
              {chartData.length > 0 ? chartData.map((data, index) => {
                const maxTotal = Math.max(...chartData.map(d => d.total), 1)
                const height = (data.total / maxTotal) * 100
                return (
                  <div key={index} className="flex-1 flex flex-col items-center gap-2">
                    <div 
                      className="w-full bg-gradient-to-t from-emerald-500 to-teal-400 rounded-t-lg transition-all hover:from-emerald-600 hover:to-teal-500"
                      style={{ height: `${Math.max(height, 5)}%` }}
                    />
                    <span className="text-xs text-slate-500">{data.month}</span>
                    <span className="text-xs font-medium text-slate-700 dark:text-slate-300">
                      {data.total.toLocaleString()}
                    </span>
                  </div>
                )
              }) : (
                <div className="flex-1 flex items-center justify-center text-slate-400">
                  لا توجد بيانات مبيعات
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Quick Stats */}
        <Card>
          <CardHeader>
            <CardTitle>إحصائيات سريعة</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-700/50 rounded-xl">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center">
                  <FileText className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-500 dark:text-slate-400">الفواتير</p>
                  <p className="text-lg font-bold text-slate-800 dark:text-white">{stats?.invoicesCount || 0}</p>
                </div>
              </div>
              <TrendingUp className="w-5 h-5 text-emerald-500" />
            </div>
            
            <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-700/50 rounded-xl">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-orange-100 dark:bg-orange-900/30 rounded-lg flex items-center justify-center">
                  <ShoppingCart className="w-5 h-5 text-orange-600 dark:text-orange-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-500 dark:text-slate-400">أوامر الشراء</p>
                  <p className="text-lg font-bold text-slate-800 dark:text-white">{stats?.purchasesCount || 0}</p>
                </div>
              </div>
              <TrendingUp className="w-5 h-5 text-orange-500" />
            </div>
            
            <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-700/50 rounded-xl">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
                  <Package className="w-5 h-5 text-blue-600 dark:text-blue-400" />
                </div>
                <div>
                  <p className="text-sm text-slate-500 dark:text-slate-400">المنتجات</p>
                  <p className="text-lg font-bold text-slate-800 dark:text-white">{stats?.productsCount || 0}</p>
                </div>
              </div>
              <Package className="w-5 h-5 text-blue-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Invoices */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>آخر الفواتير</CardTitle>
            <Button variant="outline" size="sm">عرض الكل</Button>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentInvoices.length > 0 ? recentInvoices.map((invoice) => (
                <div key={invoice.id} className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-700/50 rounded-xl">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center">
                      <FileText className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
                    </div>
                    <div>
                      <p className="font-medium text-slate-800 dark:text-white">{invoice.invoiceNumber}</p>
                      <p className="text-sm text-slate-500 dark:text-slate-400">{invoice.customer.name}</p>
                    </div>
                  </div>
                  <div className="text-left">
                    <p className="font-bold text-slate-800 dark:text-white">{invoice.total.toLocaleString()} ر.س</p>
                    {getStatusBadge(invoice.status)}
                  </div>
                </div>
              )) : (
                <div className="text-center py-8 text-slate-400">
                  لا توجد فواتير حديثة
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Low Stock Alert */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-orange-500" />
              تنبيه المخزون
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {lowStockProducts.length > 0 ? lowStockProducts.slice(0, 5).map((product) => (
                <div key={product.id} className="flex items-center justify-between p-4 bg-orange-50 dark:bg-orange-900/20 rounded-xl">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-orange-100 dark:bg-orange-900/30 rounded-lg flex items-center justify-center">
                      <Package className="w-5 h-5 text-orange-600 dark:text-orange-400" />
                    </div>
                    <div>
                      <p className="font-medium text-slate-800 dark:text-white">{product.name}</p>
                      <p className="text-sm text-slate-500 dark:text-slate-400">{product.sku}</p>
                    </div>
                  </div>
                  <div className="text-left">
                    <p className="text-sm text-slate-500 dark:text-slate-400">الكمية</p>
                    <p className="font-bold text-orange-600 dark:text-orange-400">{product.quantity} / {product.minQuantity}</p>
                  </div>
                </div>
              )) : (
                <div className="text-center py-8 text-slate-400">
                  <Package className="w-12 h-12 mx-auto mb-2 opacity-50" />
                  <p>جميع المنتجات متوفرة</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
