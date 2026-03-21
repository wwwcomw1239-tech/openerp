'use client'

import { Module } from '@/lib/erp-store'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { 
  Menu, 
  Search, 
  Bell, 
  Settings,
  Moon,
  Sun
} from 'lucide-react'
import { useState } from 'react'

interface HeaderProps {
  sidebarOpen: boolean
  setSidebarOpen: (open: boolean) => void
  activeModule: Module
}

const moduleTitles: Record<Module, string> = {
  dashboard: 'لوحة التحكم',
  customers: 'إدارة العملاء',
  suppliers: 'إدارة الموردين',
  products: 'إدارة المنتجات',
  invoices: 'إدارة الفواتير',
  purchases: 'إدارة المشتريات',
  accounting: 'المحاسبة',
  reports: 'التقارير',
}

export function Header({ sidebarOpen, setSidebarOpen, activeModule }: HeaderProps) {
  const [isDark, setIsDark] = useState(true)

  return (
    <header className="h-16 bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between px-6 sticky top-0 z-30">
      {/* Right Side */}
      <div className="flex items-center gap-4">
        <Button
          variant="ghost"
          size="icon"
          className="lg:hidden"
          onClick={() => setSidebarOpen(!sidebarOpen)}
        >
          <Menu className="w-5 h-5" />
        </Button>
        
        <div>
          <h2 className="text-xl font-bold text-slate-800 dark:text-white">
            {moduleTitles[activeModule]}
          </h2>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            نظام إدارة موارد المؤسسات
          </p>
        </div>
      </div>
      
      {/* Center - Search */}
      <div className="hidden md:flex flex-1 max-w-md mx-8">
        <div className="relative w-full">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <Input 
            placeholder="بحث..." 
            className="pr-10 bg-slate-50 dark:bg-slate-700 border-0"
          />
        </div>
      </div>
      
      {/* Left Side */}
      <div className="flex items-center gap-2">
        {/* Notifications */}
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="w-5 h-5 text-slate-600 dark:text-slate-300" />
          <Badge className="absolute -top-1 -left-1 w-5 h-5 p-0 flex items-center justify-center bg-red-500 text-white text-xs">
            3
          </Badge>
        </Button>
        
        {/* Theme Toggle */}
        <Button 
          variant="ghost" 
          size="icon"
          onClick={() => setIsDark(!isDark)}
        >
          {isDark ? (
            <Sun className="w-5 h-5 text-slate-300" />
          ) : (
            <Moon className="w-5 h-5 text-slate-600" />
          )}
        </Button>
        
        {/* Settings */}
        <Button variant="ghost" size="icon">
          <Settings className="w-5 h-5 text-slate-600 dark:text-slate-300" />
        </Button>
        
        {/* User Avatar */}
        <div className="flex items-center gap-3 mr-2 pr-4 border-r border-slate-200 dark:border-slate-700">
          <div className="text-left">
            <p className="text-sm font-medium text-slate-800 dark:text-white">المدير</p>
            <p className="text-xs text-slate-500 dark:text-slate-400">admin@erp.com</p>
          </div>
          <Avatar>
            <AvatarFallback className="bg-emerald-500 text-white">
              م
            </AvatarFallback>
          </Avatar>
        </div>
      </div>
    </header>
  )
}
