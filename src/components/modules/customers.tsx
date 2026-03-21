'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
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
import { Plus, Search, Edit, Trash2, Phone, Mail, MapPin } from 'lucide-react'
import { toast } from 'sonner'

interface Customer {
  id: string
  name: string
  email: string | null
  phone: string | null
  mobile: string | null
  address: string | null
  city: string | null
  country: string | null
  taxNumber: string | null
  creditLimit: number
  balance: number
  notes: string | null
  isActive: boolean
  createdAt: string
}

export function CustomersModule() {
  const [customers, setCustomers] = useState<Customer[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingCustomer, setEditingCustomer] = useState<Customer | null>(null)
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    mobile: '',
    address: '',
    city: '',
    country: '',
    taxNumber: '',
    creditLimit: '',
    notes: ''
  })

  const fetchCustomers = async () => {
    try {
      const response = await fetch(`/api/customers?search=${search}`)
      const data = await response.json()
      setCustomers(data.customers)
    } catch (error) {
      console.error('Error fetching customers:', error)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchCustomers()
  }, [search])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      const url = editingCustomer 
        ? `/api/customers/${editingCustomer.id}`
        : '/api/customers'
      
      const method = editingCustomer ? 'PUT' : 'POST'
      
      const response = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      })
      
      if (response.ok) {
        toast.success(editingCustomer ? 'تم تحديث العميل' : 'تم إضافة العميل')
        setIsDialogOpen(false)
        setEditingCustomer(null)
        setFormData({
          name: '', email: '', phone: '', mobile: '', address: '', 
          city: '', country: '', taxNumber: '', creditLimit: '', notes: ''
        })
        fetchCustomers()
      }
    } catch (error) {
      toast.error('حدث خطأ')
    }
  }

  const handleEdit = (customer: Customer) => {
    setEditingCustomer(customer)
    setFormData({
      name: customer.name,
      email: customer.email || '',
      phone: customer.phone || '',
      mobile: customer.mobile || '',
      address: customer.address || '',
      city: customer.city || '',
      country: customer.country || '',
      taxNumber: customer.taxNumber || '',
      creditLimit: customer.creditLimit.toString(),
      notes: customer.notes || ''
    })
    setIsDialogOpen(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('هل أنت متأكد من حذف هذا العميل؟')) return
    
    try {
      const response = await fetch(`/api/customers/${id}`, { method: 'DELETE' })
      if (response.ok) {
        toast.success('تم حذف العميل')
        fetchCustomers()
      }
    } catch (error) {
      toast.error('حدث خطأ')
    }
  }

  const openNewDialog = () => {
    setEditingCustomer(null)
    setFormData({
      name: '', email: '', phone: '', mobile: '', address: '', 
      city: '', country: '', taxNumber: '', creditLimit: '', notes: ''
    })
    setIsDialogOpen(true)
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 dark:text-white">إدارة العملاء</h1>
          <p className="text-slate-500 dark:text-slate-400">إدارة بيانات العملاء والحسابات</p>
        </div>
        
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={openNewDialog} className="bg-emerald-600 hover:bg-emerald-700">
              <Plus className="w-4 h-4 ml-2" />
              إضافة عميل
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>{editingCustomer ? 'تعديل العميل' : 'إضافة عميل جديد'}</DialogTitle>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="grid grid-cols-2 gap-4 mt-4">
              <div className="col-span-2">
                <label className="text-sm font-medium mb-1 block">اسم العميل *</label>
                <Input 
                  value={formData.name} 
                  onChange={e => setFormData({...formData, name: e.target.value})}
                  required
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">البريد الإلكتروني</label>
                <Input 
                  type="email"
                  value={formData.email} 
                  onChange={e => setFormData({...formData, email: e.target.value})}
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الهاتف</label>
                <Input 
                  value={formData.phone} 
                  onChange={e => setFormData({...formData, phone: e.target.value})}
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الجوال</label>
                <Input 
                  value={formData.mobile} 
                  onChange={e => setFormData({...formData, mobile: e.target.value})}
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">المدينة</label>
                <Input 
                  value={formData.city} 
                  onChange={e => setFormData({...formData, city: e.target.value})}
                />
              </div>
              <div className="col-span-2">
                <label className="text-sm font-medium mb-1 block">العنوان</label>
                <Input 
                  value={formData.address} 
                  onChange={e => setFormData({...formData, address: e.target.value})}
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الدولة</label>
                <Input 
                  value={formData.country} 
                  onChange={e => setFormData({...formData, country: e.target.value})}
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الرقم الضريبي</label>
                <Input 
                  value={formData.taxNumber} 
                  onChange={e => setFormData({...formData, taxNumber: e.target.value})}
                />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">حد الائتمان</label>
                <Input 
                  type="number"
                  value={formData.creditLimit} 
                  onChange={e => setFormData({...formData, creditLimit: e.target.value})}
                />
              </div>
              <div className="col-span-2">
                <label className="text-sm font-medium mb-1 block">ملاحظات</label>
                <Input 
                  value={formData.notes} 
                  onChange={e => setFormData({...formData, notes: e.target.value})}
                />
              </div>
              <div className="col-span-2 flex justify-end gap-2">
                <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>
                  إلغاء
                </Button>
                <Button type="submit" className="bg-emerald-600 hover:bg-emerald-700">
                  {editingCustomer ? 'تحديث' : 'إضافة'}
                </Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      {/* Search */}
      <Card>
        <CardContent className="p-4">
          <div className="relative">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <Input 
              placeholder="بحث عن عميل..." 
              className="pr-10"
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
        </CardContent>
      </Card>

      {/* Customers Table */}
      <Card>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="p-8 text-center text-slate-400">جاري التحميل...</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>العميل</TableHead>
                  <TableHead>معلومات الاتصال</TableHead>
                  <TableHead>الموقع</TableHead>
                  <TableHead>الرصيد</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead>الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {customers.map((customer) => (
                  <TableRow key={customer.id}>
                    <TableCell>
                      <div>
                        <p className="font-medium">{customer.name}</p>
                        {customer.taxNumber && (
                          <p className="text-xs text-slate-500">رقم ضريبي: {customer.taxNumber}</p>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="space-y-1">
                        {customer.email && (
                          <div className="flex items-center gap-1 text-sm text-slate-600">
                            <Mail className="w-3 h-3" />
                            {customer.email}
                          </div>
                        )}
                        {customer.phone && (
                          <div className="flex items-center gap-1 text-sm text-slate-600">
                            <Phone className="w-3 h-3" />
                            {customer.phone}
                          </div>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      {customer.city || customer.country ? (
                        <div className="flex items-center gap-1 text-sm text-slate-600">
                          <MapPin className="w-3 h-3" />
                          {[customer.city, customer.country].filter(Boolean).join(', ')}
                        </div>
                      ) : '-'}
                    </TableCell>
                    <TableCell>
                      <div>
                        <p className="font-medium">{customer.balance.toLocaleString()} ر.س</p>
                        <p className="text-xs text-slate-500">حد: {customer.creditLimit.toLocaleString()}</p>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge className={customer.isActive ? 'bg-emerald-100 text-emerald-600' : 'bg-red-100 text-red-600'}>
                        {customer.isActive ? 'نشط' : 'غير نشط'}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-2">
                        <Button size="icon" variant="ghost" onClick={() => handleEdit(customer)}>
                          <Edit className="w-4 h-4" />
                        </Button>
                        <Button size="icon" variant="ghost" className="text-red-500" onClick={() => handleDelete(customer.id)}>
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
                {customers.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-8 text-slate-400">
                      لا يوجد عملاء
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
