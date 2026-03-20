import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../logic/providers/app_state_provider.dart';
import '../../logic/providers/auth_provider.dart';

/// Main app scaffold with navigation drawer
class AppScaffold extends ConsumerWidget {
  final Widget child;

  const AppScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSidebarExpanded = ref.watch(isSidebarExpandedProvider);
    final activeModule = ref.watch(activeModuleProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            // Navigation Drawer
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSidebarExpanded ? 280 : 72,
              child: _buildDrawer(context, ref, activeModule, isSidebarExpanded, currentUser),
            ),
            
            // Vertical divider
            const VerticalDivider(width: 1),
            
            // Main content
            Expanded(
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    String activeModule,
    bool isExpanded,
    AuthUser? user,
  ) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          // Logo header
          _buildHeader(isExpanded),
          
          const Divider(color: Colors.white24),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  ref,
                  icon: Icons.dashboard,
                  label: 'لوحة التحكم',
                  route: '/',
                  moduleId: 'dashboard',
                  isActive: activeModule == 'dashboard',
                  isExpanded: isExpanded,
                ),
                _buildNavItem(
                  context,
                  ref,
                  icon: Icons.people,
                  label: 'العملاء',
                  route: '/customers',
                  moduleId: 'customers',
                  isActive: activeModule == 'customers',
                  isExpanded: isExpanded,
                ),
                _buildNavItem(
                  context,
                  ref,
                  icon: Icons.local_shipping,
                  label: 'الموردين',
                  route: '/suppliers',
                  moduleId: 'suppliers',
                  isActive: activeModule == 'suppliers',
                  isExpanded: isExpanded,
                ),
                _buildNavItem(
                  context,
                  ref,
                  icon: Icons.inventory_2,
                  label: 'المنتجات',
                  route: '/products',
                  moduleId: 'products',
                  isActive: activeModule == 'products',
                  isExpanded: isExpanded,
                ),
                _buildNavItem(
                  context,
                  ref,
                  icon: Icons.receipt_long,
                  label: 'الفواتير',
                  route: '/invoices',
                  moduleId: 'invoices',
                  isActive: activeModule == 'invoices',
                  isExpanded: isExpanded,
                ),
                _buildNavItem(
                  context,
                  ref,
                  icon: Icons.shopping_cart,
                  label: 'المشتريات',
                  route: '/purchases',
                  moduleId: 'purchases',
                  isActive: activeModule == 'purchases',
                  isExpanded: isExpanded,
                ),
                _buildNavItem(
                  context,
                  ref,
                  icon: Icons.account_balance,
                  label: 'المحاسبة',
                  route: '/accounting',
                  moduleId: 'accounting',
                  isActive: activeModule == 'accounting',
                  isExpanded: isExpanded,
                ),
                _buildNavItem(
                  context,
                  ref,
                  icon: Icons.bar_chart,
                  label: 'التقارير',
                  route: '/reports',
                  moduleId: 'reports',
                  isActive: activeModule == 'reports',
                  isExpanded: isExpanded,
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24),
          
          // User section
          _buildUserSection(context, ref, user, isExpanded),
          
          // Toggle button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(
                isExpanded ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.white70,
              ),
              onPressed: () => ref.read(appStateNotifierProvider.notifier).toggleSidebar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isExpanded) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calculate, color: Colors.white),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OpenERP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'نظام إدارة متكامل',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required String route,
    required String moduleId,
    required bool isActive,
    required bool isExpanded,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive ? const Color(0xFF10B981) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ref.read(appStateNotifierProvider.notifier).setActiveModule(moduleId);
            context.go(route);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.white70,
                  size: 22,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection(
    BuildContext context,
    WidgetRef ref,
    AuthUser? user,
    bool isExpanded,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isExpanded
          ? Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF10B981),
                  child: Text(
                    user?.name.substring(0, 1) ?? 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'المستخدم',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white54),
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
              ],
            )
          : CircleAvatar(
              backgroundColor: const Color(0xFF10B981),
              child: Text(
                user?.name.substring(0, 1) ?? 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}
