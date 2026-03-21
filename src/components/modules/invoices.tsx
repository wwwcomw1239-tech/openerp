'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
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
import { Plus, Search, Eye, FileText } from 'lucide-react'
import { toast } from 'sonner'

interface Customer {
  id: string
  name: string
}

interface Product {
  id: string
  name: string
  sku: string
  salePrice: number
  quantity: number
}

interface InvoiceItem {
  id: string
  productId: string
  product: { name: string; sku: string }
  quantity: number
  unitPrice: number
  total: number
}

interface Invoice {
  id: string
  invoiceNumber: string
  customer: { name: string }
  items: InvoiceItem[]
  date: string
  dueDate: string | null
  status: string
  subtotal: number
  taxAmount: number
  discount: number
  total: number
  paidAmount: number
  notes: string | null
}

export function InvoicesModule() {
  const [invoices, setInvoices] = useState<Invoice[]>([])
  const [customers, setCustomers] = useState<Customer[]>([])
  const [products, setProducts] = useState<Product[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [selectedInvoice, setSelectedInvoice] = useState<Invoice | null>(null)
  const [formData, setFormData] = useState({
    customerId: '',
    date: new Date().toISOString().split('T')[0],
    dueDate: '',
    notes: '',
    items: [{ productId: '', quantity: '1', unitPrice: '0', total: '0' }]
  })

  const fetchData = async () => {
    try {
      const [invoicesRes, customersRes, productsRes] = await Promise.all([
        fetch(`/api/invoices?status=${statusFilter}`),
        fetch('/api/customers'),
        fetch('/api/products')
      ])
      const invoicesData = await invoicesRes.json()
      const customersData = await customersRes.json()
      const productsData = await productsRes.json()
      setInvoices(invoicesData.invoices)
      setCustomers(customsData.customers || customersData)
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

      const response = await fetch('/api/invoices', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          customerId: formData.customerId,
          date: formData.date,
          dueDate: formData.dueDate || null,
          notes: formData.notes,
          items,
          userId: 'default-user'
        })
      })
      
      if (response.ok) {
        toast.success('تم إنشاء الفاتورة')
        setIsDialogOpen(false)
        setFormData({
          customerId: '',
          date: new Date().toISOString().split('T')[0],
          dueDate: '',
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
        newItems[index].unitPrice = product.salePrice.toString()
        newItems[index].total = (parseFloat(newItems[index].quantity) * product.salePrice).toString()
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
      paid: 'bg-emerald-100 text-emerald-600',
      cancelled: 'bg-red-100 text-red-600',
    }
    const labels: Record<string, string> = {
      draft: 'مسودة',
      confirmed: 'مؤكد',
      paid: 'مدفوع',
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
          <h1 className="text-2xl font-bold text-slate-800 dark:text-white">إدارة الفواتير</h1>
          <p className="text-slate-500 dark:text-slate-400">إنشاء وإدارة فواتير المبيعات</p>
        </div>
        
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button className="bg-emerald-600 hover:bg-emerald-700">
              <Plus className="w-4 h-4 ml-2" />
              إنشاء فاتورة
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>إنشاء فاتورة جديدة</DialogTitle>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="space-y-4 mt-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm font-medium mb-1 block">العميل *</label>
                  <Select value={formData.customerId} onValueChange={v => setFormData({...formData, customerId: v})}>
                    <SelectTrigger><SelectValue placeholder="اختر العميل" /></SelectTrigger>
                    <SelectContent>
                      {customers.map(c => <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <label className="text-sm font-medium mb-1 block">التاريخ</label>
                  <Input type="date" value={formData.date} onChange={e => setFormData({...formData, date: e.target.value})} />
                </div>
                <div>
                  <label className="text-sm font-medium mb-1 block">تاريخ الاستحقاق</label>
                  <Input type="date" value={formData.dueDate} onChange={e => setFormData({...formData, dueDate: e.target.value})} />
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
                <Button type="submit" className="bg-emerald-600 hover:bg-emerald-700">إنشاء الفاتورة</Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardContent className="p-4">
          <div className="flex gap-4">
            <div className="relative flex-1">
              <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <Input placeholder="بحث..." className="pr-10" value={search} onChange={e => setSearch(e.target.value)} />
            </div>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-40"><SelectValue placeholder="الحالة" /></SelectTrigger>
              <SelectContent>
                <SelectItem value="">الكل</SelectItem>
                <SelectItem value="draft">مسودة</SelectItem>
                <SelectItem value="confirmed">مؤكد</SelectItem>
                <SelectItem value="paid">مدفوع</SelectItem>
              </SelectContent>
            </Select>
          </div>
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
                  <TableHead>رقم الفاتورة</TableHead>
                  <TableHead>العميل</TableHead>
                  <TableHead>التاريخ</TableHead>
                  <TableHead>الإجمالي</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead>الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {invoices.map((invoice) => (
                  <TableRow key={invoice.id}>
                    <TableCell className="font-medium">{invoice.invoiceNumber}</TableCell>
                    <TableCell>{invoice.customer.name}</TableCell>
                    <TableCell>{new Date(invoice.date).toLocaleDateString('ar-SA')}</TableCell>
                    <TableCell className="font-medium">{invoice.total.toLocaleString()} ر.س</TableCell>
                    <TableCell>{getStatusBadge(invoice.status)}</TableCell>
                    <TableCell>
                      <Button size="icon" variant="ghost" onClick={() => setSelectedInvoice(invoice)}>
                        <Eye className="w-4 h-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
                {invoices.length === 0 && (
                  <TableRow><TableCell colSpan={6} className="text-center py-8 text-slate-400">لا يوجد فواتير</TableCell></TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Invoice Details Dialog */}
      {selectedInvoice && (
        <Dialog open={!!selectedInvoice} onOpenChange={() => setSelectedInvoice(null)}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <FileText className="w-5 h-5" />
                {selectedInvoice.invoiceNumber}
              </DialogTitle>
            </DialogHeader>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-slate-500">العميل</p>
                  <p className="font-medium">{selectedInvoice.customer.name}</p>
                </div>
                <div>
                  <p className="text-sm text-slate-500">التاريخ</p>
                  <p className="font-medium">{new Date(selectedInvoice.date).toLocaleDateString('ar-SA')}</p>
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
                  {selectedInvoice.items.map((item) => (
                    <TableRow key={item.id}>
                      <TableCell>{item.product.name}</TableCell>
                      <TableCell>{item.quantity}</TableCell>
                      <TableCell>{item.unitPrice.toLocaleString()}</TableCell>
                      <TableCell>{item.total.toLocaleString()}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              <div className="bg-slate-50 dark:bg-slate-700/50 p-4 rounded-lg space-y-2">
                <div className="flex justify-between"><span>المجموع الفرعي:</span><span>{selectedInvoice.subtotal.toLocaleString()} ر.س</span></div>
                <div className="flex justify-between"><span>الضريبة:</span><span>{selectedInvoice.taxAmount.toLocaleString()} ر.س</span></div>
                {selectedInvoice.discount > 0 && <div className="flex justify-between"><span>الخصم:</span><span>{selectedInvoice.discount.toLocaleString()} ر.س</span></div>}
                <div className="flex justify-between font-bold text-lg border-t pt-2"><span>الإجمالي:</span><span>{selectedInvoice.total.toLocaleString()} ر.س</span></div>
              </div>
            </div>
          </DialogContent>
        </Dialog>
      )}
    </div>
  )
}
