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
import { Plus, Search, Edit, Trash2, Package, AlertTriangle } from 'lucide-react'
import { toast } from 'sonner'

interface Product {
  id: string
  sku: string
  name: string
  description: string | null
  unit: string
  costPrice: number
  salePrice: number
  quantity: number
  minQuantity: number
  maxQuantity: number
  barcode: string | null
  isActive: boolean
  category: { name: string } | null
}

export function ProductsModule() {
  const [products, setProducts] = useState<Product[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingProduct, setEditingProduct] = useState<Product | null>(null)
  const [formData, setFormData] = useState({
    sku: '', name: '', description: '', unit: 'piece', costPrice: '', salePrice: '', quantity: '', minQuantity: '', maxQuantity: '', barcode: ''
  })

  const fetchProducts = async () => {
    try {
      const response = await fetch(`/api/products?search=${search}`)
      const data = await response.json()
      setProducts(data.products)
    } catch {
      console.error('Error fetching products')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchProducts()
  }, [search])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      const url = editingProduct ? `/api/products/${editingProduct.id}` : '/api/products'
      const method = editingProduct ? 'PUT' : 'POST'
      
      const response = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          costPrice: parseFloat(formData.costPrice) || 0,
          salePrice: parseFloat(formData.salePrice) || 0,
          quantity: parseFloat(formData.quantity) || 0,
          minQuantity: parseFloat(formData.minQuantity) || 0,
          maxQuantity: parseFloat(formData.maxQuantity) || 0,
        })
      })
      
      if (response.ok) {
        toast.success(editingProduct ? 'تم تحديث المنتج' : 'تم إضافة المنتج')
        setIsDialogOpen(false)
        setEditingProduct(null)
        setFormData({ sku: '', name: '', description: '', unit: 'piece', costPrice: '', salePrice: '', quantity: '', minQuantity: '', maxQuantity: '', barcode: '' })
        fetchProducts()
      }
    } catch {
      toast.error('حدث خطأ')
    }
  }

  const handleEdit = (product: Product) => {
    setEditingProduct(product)
    setFormData({
      sku: product.sku,
      name: product.name,
      description: product.description || '',
      unit: product.unit,
      costPrice: product.costPrice.toString(),
      salePrice: product.salePrice.toString(),
      quantity: product.quantity.toString(),
      minQuantity: product.minQuantity.toString(),
      maxQuantity: product.maxQuantity.toString(),
      barcode: product.barcode || ''
    })
    setIsDialogOpen(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('هل أنت متأكد من حذف هذا المنتج؟')) return
    try {
      const response = await fetch(`/api/products/${id}`, { method: 'DELETE' })
      if (response.ok) {
        toast.success('تم حذف المنتج')
        fetchProducts()
      }
    } catch {
      toast.error('حدث خطأ')
    }
  }

  const openNewDialog = () => {
    setEditingProduct(null)
    setFormData({ sku: '', name: '', description: '', unit: 'piece', costPrice: '', salePrice: '', quantity: '', minQuantity: '', maxQuantity: '', barcode: '' })
    setIsDialogOpen(true)
  }

  const getStockStatus = (product: Product) => {
    if (product.quantity <= product.minQuantity) {
      return { color: 'bg-red-100 text-red-600', label: 'منخفض', icon: AlertTriangle }
    }
    if (product.quantity >= product.maxQuantity && product.maxQuantity > 0) {
      return { color: 'bg-blue-100 text-blue-600', label: 'مكتمل', icon: Package }
    }
    return { color: 'bg-emerald-100 text-emerald-600', label: 'متوفر', icon: Package }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 dark:text-white">إدارة المنتجات</h1>
          <p className="text-slate-500 dark:text-slate-400">إدارة المخزون والمنتجات</p>
        </div>
        
        <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={openNewDialog} className="bg-blue-600 hover:bg-blue-700">
              <Plus className="w-4 h-4 ml-2" />
              إضافة منتج
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>{editingProduct ? 'تعديل المنتج' : 'إضافة منتج جديد'}</DialogTitle>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="grid grid-cols-2 gap-4 mt-4">
              <div>
                <label className="text-sm font-medium mb-1 block">رمز المنتج *</label>
                <Input value={formData.sku} onChange={e => setFormData({...formData, sku: e.target.value})} required />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">اسم المنتج *</label>
                <Input value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} required />
              </div>
              <div className="col-span-2">
                <label className="text-sm font-medium mb-1 block">الوصف</label>
                <Input value={formData.description} onChange={e => setFormData({...formData, description: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الوحدة</label>
                <Input value={formData.unit} onChange={e => setFormData({...formData, unit: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الباركود</label>
                <Input value={formData.barcode} onChange={e => setFormData({...formData, barcode: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">سعر التكلفة</label>
                <Input type="number" value={formData.costPrice} onChange={e => setFormData({...formData, costPrice: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">سعر البيع</label>
                <Input type="number" value={formData.salePrice} onChange={e => setFormData({...formData, salePrice: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الكمية</label>
                <Input type="number" value={formData.quantity} onChange={e => setFormData({...formData, quantity: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الحد الأدنى</label>
                <Input type="number" value={formData.minQuantity} onChange={e => setFormData({...formData, minQuantity: e.target.value})} />
              </div>
              <div>
                <label className="text-sm font-medium mb-1 block">الحد الأقصى</label>
                <Input type="number" value={formData.maxQuantity} onChange={e => setFormData({...formData, maxQuantity: e.target.value})} />
              </div>
              <div className="col-span-2 flex justify-end gap-2">
                <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>إلغاء</Button>
                <Button type="submit" className="bg-blue-600 hover:bg-blue-700">{editingProduct ? 'تحديث' : 'إضافة'}</Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardContent className="p-4">
          <div className="relative">
            <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <Input placeholder="بحث عن منتج..." className="pr-10" value={search} onChange={e => setSearch(e.target.value)} />
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
                  <TableHead>المنتج</TableHead>
                  <TableHead>السعر</TableHead>
                  <TableHead>الكمية</TableHead>
                  <TableHead>الحالة</TableHead>
                  <TableHead>الإجراءات</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {products.map((product) => {
                  const stockStatus = getStockStatus(product)
                  const StockIcon = stockStatus.icon
                  return (
                    <TableRow key={product.id}>
                      <TableCell>
                        <div>
                          <p className="font-medium">{product.name}</p>
                          <p className="text-xs text-slate-500">{product.sku} | {product.unit}</p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <p className="font-medium text-emerald-600">{product.salePrice.toLocaleString()} ر.س</p>
                          <p className="text-xs text-slate-500">تكلفة: {product.costPrice.toLocaleString()}</p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <p className="font-medium">{product.quantity}</p>
                          <p className="text-xs text-slate-500">حد: {product.minQuantity} - {product.maxQuantity}</p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge className={stockStatus.color}>
                          <StockIcon className="w-3 h-3 ml-1" />
                          {stockStatus.label}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-2">
                          <Button size="icon" variant="ghost" onClick={() => handleEdit(product)}><Edit className="w-4 h-4" /></Button>
                          <Button size="icon" variant="ghost" className="text-red-500" onClick={() => handleDelete(product.id)}><Trash2 className="w-4 h-4" /></Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  )
                })}
                {products.length === 0 && (
                  <TableRow><TableCell colSpan={5} className="text-center py-8 text-slate-400">لا يوجد منتجات</TableCell></TableRow>
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
