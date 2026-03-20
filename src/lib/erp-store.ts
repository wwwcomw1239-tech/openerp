import { create } from 'zustand'

export type Module = 'dashboard' | 'customers' | 'suppliers' | 'products' | 'invoices' | 'purchases' | 'accounting' | 'reports'

interface AppState {
  activeModule: Module
  setActiveModule: (module: Module) => void
  sidebarOpen: boolean
  setSidebarOpen: (open: boolean) => void
}

export const useAppStore = create<AppState>((set) => ({
  activeModule: 'dashboard',
  setActiveModule: (module) => set({ activeModule: module }),
  sidebarOpen: true,
  setSidebarOpen: (open) => set({ sidebarOpen: open }),
}))
