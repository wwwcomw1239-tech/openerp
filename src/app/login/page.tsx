'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { toast } from 'sonner'
import { Calculator, Loader2 } from 'lucide-react'

export default function LoginPage() {
  const [email, setEmail] = useState('admin@erp.com')
  const [password, setPassword] = useState('admin123')
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)

    // Simple demo authentication
    setTimeout(() => {
      if (email === 'admin@erp.com' && password === 'admin123') {
        localStorage.setItem('erp-user', JSON.stringify({
          email: 'admin@erp.com',
          name: 'المدير',
          role: 'admin'
        }))
        toast.success('تم تسجيل الدخول بنجاح')
        router.push('/')
      } else {
        toast.error('بيانات الدخول غير صحيحة')
      }
      setIsLoading(false)
    }, 1000)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="w-16 h-16 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg">
            <Calculator className="w-8 h-8 text-white" />
          </div>
          <CardTitle className="text-2xl font-bold">OpenERP</CardTitle>
          <p className="text-slate-500 text-sm mt-1">نظام إدارة موارد المؤسسات</p>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="text-sm font-medium mb-1 block">البريد الإلكتروني</label>
              <Input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@erp.com"
                required
                className="text-right"
              />
            </div>
            <div>
              <label className="text-sm font-medium mb-1 block">كلمة المرور</label>
              <Input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                className="text-right"
              />
            </div>
            <Button
              type="submit"
              className="w-full bg-emerald-600 hover:bg-emerald-700"
              disabled={isLoading}
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 ml-2 animate-spin" />
                  جاري تسجيل الدخول...
                </>
              ) : (
                'تسجيل الدخول'
              )}
            </Button>
          </form>
          
          <div className="mt-6 p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg">
            <p className="text-sm text-emerald-700 dark:text-emerald-300 text-center">
              🎉 بيانات تجريبية مُعدة مسبقاً - اضغط "تسجيل الدخول" مباشرة
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
