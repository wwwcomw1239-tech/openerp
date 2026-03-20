'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent } from '@/components/ui/card'
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

interface Supplier {
  id: string
  name: string
  email: string | null
  phone: string | null
  mobile: string | null
  address: string | null
  city: string | null
  country: string | null
  taxNumber: string | null
  balance: number
  notes: string | null
  isActive: boolean
  createdAt: string
}

export function SuppliersModule() {
  const [suppliers, setSuppliers] = useState<Supplier[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingSupplier, setEditingSupplier] = useState<Supplier | null>(null)
  const [formData, setFormData] = useState({
    name: '', email: '', phone: '', mobile: '', address: '', city: '', country: '', taxNumber: '', notes: ''
  })

  const fetchSuppliers = async () => {
    try {
      const response = await fetch(`/api/suppliers?search=${search}`)
      const data = await response.json()
      setSuppliers(data.suppliers)
    } catch (error) {
      console.error('Error fetching suppliers:', error)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchSuppliers()
  }, [search])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      const url = editingSupplier ? `/api/suppliers/${editingSupplier.id}` : '/api/suppliers'
      const method = editingSupplier ? 'PUT' : 'POST'
      
      const response = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      })
      
      if (response.ok) {
        toast.success(editingSupplier ? 'تم تحديث المورد' : 'تم إضافة المورد')
        setIsDialogOpen(false)
        setEditingSupplier(null)
        setFormData({ name: '', email: '', phone: '', mobile: '', address: '', city: '', country: '', taxNumber: '', notes: '' })
        fetchSuppliers()
      }
    } catch {
      toast.error('حدث خطأ')
    }
  }

  const handleEdit = (supplier: Supplier) => {
    setEditingSupplier(supplier)
    setFormData({
      name: supplier.name,
      email: supplier.email || '',
      phone: supplier.phone || '',
      mobile: supplier.mobile || '',
      address: supplier.address || '',
      city: supplier.city || '',
      country: supplier.country || '',
      taxNumber: supplier.taxNumber || '',
      notes: supplier.notes || ''
    })
    setIsDialogOpen(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('هل أنت متأكد من حذف هذا المورد؟')) return
    try {
      const response = await fetch(`/api/suppliers/${id}`, { method: 'DELETE' })
      if (response.ok) {
        toast.success('تم حذف المورد')
        fetchSuppliers()
      }
    } catch {
      toast.error('حدث خطأ')
    }
  }

  const openNewDialog = () => {
    setEditingSupplier(null)
    setFormData({ name: '', email: '', phone: '', mobile: '', address: '', city: '', country: '', taxNumber: '', notes: '' })
    setIsDialogOpen(true)
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 dark:text-white">إدارة الموردين</h1>
          <p className="text-slate-500 dark:text-slate-400">إدارة بيانات الموردين والحسابات</p>
        </div>
        
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={openNewDialog} className="bg-orange-600 hover:bg-orange-700">
              <Plus className="w-4 h-4 ml-2" />
              إضافة مورد
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>{editingSupplier ? 'تعديل المورد' : 'إضافة مورد جديد'}</DialogTitle>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="grid grid-cols-2 gap-4 mt-4">
              <div className="col-span-2">
                <label className="text-sm font-medium mb-1 block">اسم المورد *</label>
                <Input value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} required />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">البريد الإلكتروني</label>
                <Input type="email" value={formData.email} onChange={e => setFormData({...formData, email: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الهاتف</label>
                <Input value={formData.phone} onChange={e => setFormData({...formData, phone: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الجوال</label>
                <Input value={formData.mobile} onChange={e => setFormData({...formData, mobile: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">المدينة</label>
                <Input value={formData.city} onChange={e => setFormData({...formData, city: e.target.value})} />
              </div>
              <div className="col-span-2">
                <label className="text-sm font-medium mb-1 block">العنوان</label>
                <Input value={formData.address} onChange={e => setFormData({...formData, address: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الدولة</label>
                <Input value={formData.country} onChange={e => setFormData({...formData, country: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الرقم الضريبي</label>
                <Input value={formData.taxNumber} onChange={e => setFormData({...formData, taxNumber: e.target.value})} />
              </div>
              <div className="col-span-2">
                <label className="text-sm font-medium mb-1 block">ملاحظات</label>
                <Input value={formData.notes} onChange={e => setFormData({...formData, notes: e.target.value})} />
              </div>
              <div className="col-span-2 flex justify-end gap-2">
                <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>إلغاء</Button>
                <Button type="submit" className="bg-orange-600 hover:bg-orange-700">{editingSupplier ? 'تحديث' : 'إضافة'}</Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardContent className="p-4">
          <div className="relative">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <Input placeholder="بحث عن مورد..." className="pr-10" value={search} onChange={e => setSearch(e.target.value)} />
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
                  <TableHead>المورد</TableHead>
                  <TableHead>معلومات الاتصال</TableHead>
                  <TableHead>الموقع</TableHead>
                  <TableHead>الرصيد</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead>الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {suppliers.map((supplier) => (
                  <TableRow key={supplier.id}>
                    <TableCell>
                      <div>
                        <p className="font-medium">{supplier.name}</p>
                        {supplier.taxNumber && <p className="text-xs text-slate-500">رقم ضريبي: {supplier.taxNumber}</p>}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="space-y-1">
                        {supplier.email && <div className="flex items-center gap-1 text-sm text-slate-600"><Mail className="w-3 h-3" />{supplier.email}</div>}
                        {supplier.phone && <div className="flex items-center gap-1 text-sm text-slate-600"><Phone className="w-3 h-3" />{supplier.phone}</div>}
                      </div>
                    </TableCell>
                    <TableCell>
                      {supplier.city || supplier.country ? (
                        <div className="flex items-center gap-1 text-sm text-slate-600"><MapPin className="w-3 h-3" />{[supplier.city, supplier.country].filter(Boolean).join(', ')}</div>
                      ) : '-'}
                    </TableCell>
                    <TableCell>
                      <p className="font-medium">{supplier.balance.toLocaleString()} ر.س</p>
                    </TableCell>
                    <TableCell>
                      <Badge className={supplier.isActive ? 'bg-emerald-100 text-emerald-600' : 'bg-red-100 text-red-600'}>{supplier.isActive ? 'نشط' : 'غير نشط'}</Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-2">
                        <Button size="icon" variant="ghost" onClick={() => handleEdit(supplier)}><Edit className="w-4 h-4" /></Button>
                        <Button size="icon" variant="ghost" className="text-red-500" onClick={() => handleDelete(supplier.id)}><Trash2 className="w-4 h-4" /></Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
                {suppliers.length === 0 && (
                  <TableRow><TableCell colSpan={6} className="text-center py-8 text-slate-400">لا يوجد موردين</TableCell></TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
