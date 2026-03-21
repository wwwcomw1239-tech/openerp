'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Plus, Search, Eye, ShoppingCart } from 'lucide-react'
import { toast } from 'sonner'

interface Supplier {
  id: string
  name: string
}

interface Product {
  id: string
  name: string
  sku: string
  costPrice: number
  quantity: number
}

interface PurchaseItem {
  id: string
  productId: string
  product: { name: string; sku: string }
  quantity: number
  unitPrice: number
  total: number
}

interface Purchase {
  id: string
  purchaseNumber: string
  supplier: { name: string }
  items: PurchaseItem[]
  date: string
  status: string
  subtotal: number
  taxAmount: number
  total: number
  notes: string | null
}

export function PurchasesModule() {
  const [purchases, setPurchases] = useState<Purchase[]>([])
  const [suppliers, setSuppliers] = useState<Supplier[]>([])
  const [products, setProducts] = useState<Product[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState('')
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [selectedPurchase, setSelectedPurchase] = useState<Purchase | null>(null)
  const [formData, setFormData] = useState({
    supplierId: '',
    date: new Date().toISOString().split('T')[0],
    notes: '',
    items: [{ productId: '', quantity: '1', unitPrice: '0', total: '0' }]
  })

  const fetchData = async () => {
    try {
      const [purchasesRes, suppliersRes, productsRes] = await Promise.all([
        fetch(`/api/purchases?status=${statusFilter}`),
        fetch('/api/suppliers'),
        fetch('/api/products')
      ])
      const purchasesData = await purchasesRes.json()
      const suppliersData = await suppliersRes.json()
      const productsData = await productsRes.json()
      setPurchases(purchasesData.purchases)
      setSuppliers(suppliersData.suppliers)
      setProducts(productsData.products)
    } catch {
      console.error('Error fetching data')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [statusFilter])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      const items = formData.items.map(item => ({
        productId: item.productId,
        quantity: parseFloat(item.quantity) || 0,
        unitPrice: parseFloat(item.unitPrice) || 0,
        total: (parseFloat(item.quantity) || 0) * (parseFloat(item.unitPrice) || 0),
        description: ''
      }))

      const response = await fetch('/api/purchases', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          supplierId: formData.supplierId,
          date: formData.date,
          notes: formData.notes,
          items,
          userId: 'default-user'
        })
      })
      
      if (response.ok) {
        toast.success('تم إنشاء أمر الشراء')
        setIsDialogOpen(false)
        setFormData({
          supplierId: '',
          date: new Date().toISOString().split('T')[0],
          notes: '',
          items: [{ productId: '', quantity: '1', unitPrice: '0', total: '0' }]
        })
        fetchData()
      }
    } catch {
      toast.error('حدث خطأ')
    }
  }

  const addItem = () => {
    setFormData({
      ...formData,
      items: [...formData.items, { productId: '', quantity: '1', unitPrice: '0', total: '0' }]
    })
  }

  const updateItem = (index: number, field: string, value: string) => {
    const newItems = [...formData.items]
    newItems[index] = { ...newItems[index], [field]: value }
    
    if (field === 'productId') {
      const product = products.find(p => p.id === value)
      if (product) {
        newItems[index].unitPrice = product.costPrice.toString()
        newItems[index].total = (parseFloat(newItems[index].quantity) * product.costPrice).toString()
      }
    } else if (field === 'quantity') {
      newItems[index].total = (parseFloat(value) * parseFloat(newItems[index].unitPrice)).toString()
    }
    
    setFormData({ ...formData, items: newItems })
  }

  const removeItem = (index: number) => {
    const newItems = formData.items.filter((_, i) => i !== index)
    setFormData({ ...formData, items: newItems })
  }

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      draft: 'bg-slate-100 text-slate-600',
      confirmed: 'bg-blue-100 text-blue-600',
      received: 'bg-emerald-100 text-emerald-600',
      cancelled: 'bg-red-100 text-red-600',
    }
    const labels: Record<string, string> = {
      draft: 'مسودة',
      confirmed: 'مؤكد',
      received: 'مستلم',
      cancelled: 'ملغي',
    }
    return <Badge className={styles[status] || styles.draft}>{labels[status] || status}</Badge>
  }

  const calculateTotal = () => {
    return formData.items.reduce((sum, item) => sum + (parseFloat(item.total) || 0), 0)
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 dark:text-white">إدارة المشتريات</h1>
          <p className="text-slate-500 dark:text-slate-400">إنشاء وإدارة أوامر الشراء</p>
        </div>
        
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button className="bg-orange-600 hover:bg-orange-700">
              <Plus className="w-4 h-4 ml-2" />
              إنشاء أمر شراء
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>إنشاء أمر شراء جديد</DialogTitle>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="space-y-4 mt-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium mb-1 block">المورد *</label>
                  <Select value={formData.supplierId} onValueChange={v => setFormData({...formData, supplierId: v})}>
                    <SelectTrigger><SelectValue placeholder="اختر المورد" /></SelectTrigger>
                    <SelectContent>
                      {suppliers.map(s => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <label className="text-sm font-medium mb-1 block">التاريخ</label>
                  <Input type="date" value={formData.date} onChange={e => setFormData({...formData, date: e.target.value})} />
                </div>
              </div>
              
              <div>
                <div className="flex justify-between items-center mb-2">
                  <label className="text-sm font-medium">المنتجات</label>
                  <Button type="button" variant="outline" size="sm" onClick={addItem}>إضافة منتج</Button>
                </div>
                <div className="space-y-2">
                  {formData.items.map((item, index) => (
                    <div key={index} className="grid grid-cols-5 gap-2 items-end">
                      <div className="col-span-2">
                        <Select value={item.productId} onValueChange={v => updateItem(index, 'productId', v)}>
                          <SelectTrigger><SelectValue placeholder="اختر المنتج" /></SelectTrigger>
                          <SelectContent>
                            {products.map(p => <SelectItem key={p.id} value={p.id}>{p.name} ({p.sku})</SelectItem>)}
                          </SelectContent>
                        </Select>
                      </div>
                      <Input type="number" placeholder="الكمية" value={item.quantity} onChange={e => updateItem(index, 'quantity', e.target.value)} />
                      <Input type="number" placeholder="السعر" value={item.unitPrice} onChange={e => updateItem(index, 'unitPrice', e.target.value)} />
                      <Button type="button" variant="ghost" className="text-red-500" onClick={() => removeItem(index)}>حذف</Button>
                    </div>
                  ))}
                </div>
              </div>
              
              <div className="bg-slate-50 dark:bg-slate-700/50 p-4 rounded-lg">
                <div className="flex justify-between text-lg font-bold">
                  <span>الإجمالي:</span>
                  <span>{calculateTotal().toLocaleString()} ر.س</span>
                </div>
              </div>
              
              <div>
                <label className="text-sm font-medium mb-1 block">ملاحظات</label>
                <Input value={formData.notes} onChange={e => setFormData({...formData, notes: e.target.value})} />
              </div>
              
              <div className="flex justify-end gap-2">
                <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>إلغاء</Button>
                <Button type="submit" className="bg-orange-600 hover:bg-orange-700">إنشاء أمر الشراء</Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardContent className="p-4">
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-40"><SelectValue placeholder="فلترة بالحالة" /></SelectTrigger>
            <SelectContent>
              <SelectItem value="">الكل</SelectItem>
              <SelectItem value="draft">مسودة</SelectItem>
              <SelectItem value="confirmed">مؤكد</SelectItem>
              <SelectItem value="received">مستلم</SelectItem>
            </SelectContent>
          </Select>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="p-8 text-center text-slate-400">جاري التحميل...</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>رقم الأمر</TableHead>
                  <TableHead>المورد</TableHead>
                  <TableHead>التاريخ</TableHead>
                  <TableHead>الإجمالي</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead>الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {purchases.map((purchase) => (
                  <TableRow key={purchase.id}>
                    <TableCell className="font-medium">{purchase.purchaseNumber}</TableCell>
                    <TableCell>{purchase.supplier.name}</TableCell>
                    <TableCell>{new Date(purchase.date).toLocaleDateString('ar-SA')}</TableCell>
                    <TableCell className="font-medium">{purchase.total.toLocaleString()} ر.س</TableCell>
                    <TableCell>{getStatusBadge(purchase.status)}</TableCell>
                    <TableCell>
                      <Button size="icon" variant="ghost" onClick={() => setSelectedPurchase(purchase)}>
                        <Eye className="w-4 h-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
                {purchases.length === 0 && (
                  <TableRow><TableCell colSpan={6} className="text-center py-8 text-slate-400">لا يوجد أوامر شراء</TableCell></TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {selectedPurchase && (
        <Dialog open={!!selectedPurchase} onOpenChange={() => setSelectedPurchase(null)}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <ShoppingCart className="w-5 h-5" />
                {selectedPurchase.purchaseNumber}
              </DialogTitle>
            </DialogHeader>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-slate-500">المورد</p>
                  <p className="font-medium">{selectedPurchase.supplier.name}</p>
                </div>
                <div>
                  <p className="text-sm text-slate-500">التاريخ</p>
                  <p className="font-medium">{new Date(selectedPurchase.date).toLocaleDateString('ar-SA')}</p>
                </div>
              </div>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>المنتج</TableHead>
                    <TableHead>الكمية</TableHead>
                    <TableHead>السعر</TableHead>
                    <TableHead>الإجمالي</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {selectedPurchase.items.map((item) => (
                    <TableRow key={item.id}>
                      <TableCell>{item.product.name}</TableCell>
                      <TableCell>{item.quantity}</TableCell>
                      <TableCell>{item.unitPrice.toLocaleString()}</TableCell>
                      <TableCell>{item.total.toLocaleString()}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              <div className="bg-slate-50 dark:bg-slate-700/50 p-4 rounded-lg">
                <div className="flex justify-between font-bold text-lg">
                  <span>الإجمالي:</span>
                  <span>{selectedPurchase.total.toLocaleString()} ر.س</span>
                </div>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      )}
    </div>
  )
}
