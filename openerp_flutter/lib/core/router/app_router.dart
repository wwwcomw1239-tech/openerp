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

/// Splash screen shown during auth check
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
                Color(0xFF1E293B),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.calculate,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'OpenERP',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نظام إدارة موارد المؤسسات',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Router provider
@riverpod
GoRouter router(RouterRef ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: Routes.dashboard,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == Routes.login;

      // Handle different auth states
      if (authState is AuthLoading) {
        // Don't redirect during loading - let splash show
        return null;
      }

      final isAuthenticated = authState is AuthAuthenticated;

      if (!isAuthenticated && !isLoginRoute) {
        return Routes.login;
      }

      if (isAuthenticated && isLoginRoute) {
        return Routes.dashboard;
      }

      return null;
    },
    routes: [
      // Splash route for loading state
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // App routes (protected)
      ShellRoute(
        builder: (context, state, child) {
          // Show splash if still loading
          if (authState is AuthLoading) {
            return const SplashScreen();
          }
          // Show login if not authenticated
          if (authState is! AuthAuthenticated) {
            return const LoginScreen();
          }
          return AppScaffold(child: child);
        },
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
    errorBuilder: (context, state) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في التنقل',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('${state.error}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(Routes.dashboard),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
