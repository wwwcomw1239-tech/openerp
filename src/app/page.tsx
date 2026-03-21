'use client'

// OpenERP - Open Source Enterprise Resource Planning System
// Version 1.0.0
import { useState, useEffect } from 'react'
import { useAppStore, Module } from '@/lib/erp-store'
import { 
  Dashboard, 
  CustomersModule, 
  SuppliersModule, 
  ProductsModule, 
  InvoicesModule, 
  PurchasesModule, 
  AccountingModule, 
  ReportsModule 
} from '@/components/modules'
import { Sidebar } from '@/components/layout/sidebar'
import { Header } from '@/components/layout/header'
import { toast } from 'sonner'

export default function Home() {
  const { activeModule, setActiveModule, sidebarOpen, setSidebarOpen } = useAppStore()
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const seedData = async () => {
      try {
        const response = await fetch('/api/seed', { method: 'POST' })
        if (response.ok) {
          toast.success('تم تحميل البيانات الأولية')
        }
      } catch {
        // Data might already exist
      } finally {
        setIsLoading(false)
      }
    }
    seedData()
  }, [])

  const renderModule = () => {
    switch (activeModule) {
      case 'dashboard':
        return <Dashboard />
      case 'customers':
        return <CustomersModule />
      case 'suppliers':
        return <SuppliersModule />
      case 'products':
        return <ProductsModule />
      case 'invoices':
        return <InvoicesModule />
      case 'purchases':
        return <PurchasesModule />
      case 'accounting':
        return <AccountingModule />
      case 'reports':
        return <ReportsModule />
      default:
        return <Dashboard />
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <h2 className="text-xl font-semibold text-white">جاري تحميل النظام...</h2>
          <p className="text-slate-400 mt-2">ERP System</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900 flex" dir="rtl">
      <Sidebar 
        activeModule={activeModule} 
        setActiveModule={setActiveModule}
        isOpen={sidebarOpen}
        setIsOpen={setSidebarOpen}
      />
      
      <div className="flex-1 flex flex-col min-h-screen">
        <Header 
          sidebarOpen={sidebarOpen}
          setSidebarOpen={setSidebarOpen}
          activeModule={activeModule}
        />
        
        <main className="flex-1 p-6 overflow-auto">
          {renderModule()}
        </main>
      </div>
    </div>
  )
}
