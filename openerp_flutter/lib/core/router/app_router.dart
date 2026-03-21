import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../logic/providers/auth_provider.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/dashboard/dashboard_screen.dart';
import '../../ui/screens/customers/customers_screen.dart';
import '../../ui/screens/suppliers/suppliers_screen.dart';
import '../../ui/screens/products/products_screen.dart';
import '../../ui/screens/invoices/invoices_screen.dart';
import '../../ui/screens/purchases/purchases_screen.dart';
import '../../ui/screens/accounting/accounts_screen.dart';
import '../../ui/screens/reports/reports_screen.dart';
import '../../ui/widgets/common/app_scaffold.dart';

part 'app_router.g.dart';

/// Route names
class Routes {
  static const login = '/login';
  static const dashboard = '/';
  static const customers = '/customers';
  static const suppliers = '/suppliers';
  static const products = '/products';
  static const invoices = '/invoices';
  static const purchases = '/purchases';
  static const accounting = '/accounting';
  static const reports = '/reports';
}

/// Router provider
@riverpod
GoRouter router(RouterRef ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: Routes.dashboard,
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoginRoute = state.matchedLocation == Routes.login;
      
      if (!isAuthenticated && !isLoginRoute) {
        return Routes.login;
      }
      
      if (isAuthenticated && isLoginRoute) {
        return Routes.dashboard;
      }
      
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // App routes (protected)
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: Routes.customers,
            name: 'customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: Routes.suppliers,
            name: 'suppliers',
            builder: (context, state) => const SuppliersScreen(),
          ),
          GoRoute(
            path: Routes.products,
            name: 'products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: Routes.invoices,
            name: 'invoices',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: Routes.purchases,
            name: 'purchases',
            builder: (context, state) => const PurchasesScreen(),
          ),
          GoRoute(
            path: Routes.accounting,
            name: 'accounting',
            builder: (context, state) => const AccountsScreen(),
          ),
          GoRoute(
            path: Routes.reports,
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
