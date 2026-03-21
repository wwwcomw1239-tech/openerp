'use client'

import { Module } from '@/lib/erp-store'
import { cn } from '@/lib/utils'
import {
  LayoutDashboard,
  Users,
  Truck,
  Package,
  FileText,
  ShoppingCart,
  Calculator,
  BarChart3,
  ChevronRight,
  Menu
} from 'lucide-react'
import { Button } from '@/components/ui/button'

interface SidebarProps {
  activeModule: Module
  setActiveModule: (module: Module) => void
  isOpen: boolean
  setIsOpen: (open: boolean) => void
}

const menuItems: { id: Module; label: string; icon: React.ElementType }[] = [
  { id: 'dashboard', label: 'لوحة التحكم', icon: LayoutDashboard },
  { id: 'customers', label: 'العملاء', icon: Users },
  { id: 'suppliers', label: 'الموردين', icon: Truck },
  { id: 'products', label: 'المنتجات', icon: Package },
  { id: 'invoices', label: 'الفواتير', icon: FileText },
  { id: 'purchases', label: 'المشتريات', icon: ShoppingCart },
  { id: 'accounting', label: 'المحاسبة', icon: Calculator },
  { id: 'reports', label: 'التقارير', icon: BarChart3 },
]

export function Sidebar({ activeModule, setActiveModule, isOpen, setIsOpen }: SidebarProps) {
  return (
    <>
      {/* Mobile Overlay */}
      {isOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={() => setIsOpen(false)}
        />
      )}
      
      {/* Sidebar */}
      <aside className={cn(
        "fixed top-0 right-0 h-full bg-gradient-to-b from-slate-900 to-slate-800 z-50 transition-all duration-300 ease-in-out",
        "w-72 shadow-2xl",
        isOpen ? "translate-x-0" : "translate-x-full lg:translate-x-0"
      )}>
        {/* Logo */}
        <div className="h-16 flex items-center justify-between px-6 border-b border-slate-700">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-xl flex items-center justify-center shadow-lg">
              <Calculator className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-white">OpenERP</h1>
              <p className="text-xs text-slate-400">نظام إدارة متكامل</p>
            </div>
          </div>
          <Button
            variant="ghost"
            size="icon"
            className="lg:hidden text-slate-400 hover:text-white"
            onClick={() => setIsOpen(false)}
          >
            <Menu className="w-5 h-5" />
          </Button>
        </div>
        
        {/* Navigation */}
        <nav className="p-4 space-y-1">
          {menuItems.map((item) => {
            const Icon = item.icon
            const isActive = activeModule === item.id
            
            return (
              <button
                key={item.id}
                onClick={() => {
                  setActiveModule(item.id)
                  setIsOpen(false)
                }}
                className={cn(
                  "w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 group",
                  isActive 
                    ? "bg-gradient-to-l from-emerald-600 to-emerald-500 text-white shadow-lg shadow-emerald-500/20" 
                    : "text-slate-300 hover:bg-slate-700/50 hover:text-white"
                )}
              >
                <Icon className={cn(
                  "w-5 h-5 transition-transform",
                  isActive ? "scale-110" : "group-hover:scale-110"
                )} />
                <span className="font-medium">{item.label}</span>
                {isActive && (
                  <ChevronRight className="w-4 h-4 mr-auto" />
                )}
              </button>
            )
          })}
        </nav>
        
        {/* Footer */}
        <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-slate-700">
          <div className="bg-slate-800/50 rounded-xl p-4">
            <p className="text-xs text-slate-400 text-center">
              OpenERP v1.0.0
            </p>
            <p className="text-xs text-slate-500 text-center mt-1">
              نظام مفتوح المصدر
            </p>
          </div>
        </div>
      </aside>
    </>
  )
}
