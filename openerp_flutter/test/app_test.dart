// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openerp_flutter/main.dart';
import 'package:openerp_flutter/logic/providers/auth_provider.dart';
import 'package:openerp_flutter/core/router/app_router.dart';
import 'package:openerp_flutter/core/theme/app_theme.dart';
import 'package:openerp_flutter/ui/screens/auth/login_screen.dart';
import 'package:openerp_flutter/ui/screens/dashboard/dashboard_screen.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Initialization Tests', () {
    testWidgets('App should initialize without crashing', (tester) async {
      // Track any errors
      FlutterError.onError = (details) {
        print('❌ FlutterError: ${details.exception}');
        fail('Flutter error during initialization: ${details.exception}');
      };

      await tester.pumpWidget(
        const ProviderScope(
          child: OpenERPApp(),
        ),
      );

      // Wait for async operations
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should not show error widget
      expect(find.text('حدث خطأ غير متوقع'), findsNothing);

      print('✅ App initialized without crashing');
    });

    testWidgets('Should show login screen initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: OpenERPApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should find login screen elements
      expect(find.text('OpenERP'), findsWidgets);
      expect(find.text('تسجيل الدخول'), findsOneWidget);

      print('✅ Login screen displayed correctly');
    });

    testWidgets('Login form should be functional', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: OpenERPApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find text fields
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;
      final loginButton = find.widgetWithText(ElevatedButton, 'تسجيل الدخول');

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(loginButton, findsOneWidget);

      print('✅ Login form elements found');
    });
  });

  group('Provider Tests', () {
    test('AuthProvider should initialize as unauthenticated', () {
      final container = ProviderContainer();
      final authState = container.read(authProvider);

      expect(authState, isA<AuthUnauthenticated>());
      print('✅ AuthProvider initializes correctly');

      container.dispose();
    });

    test('Router should be created without errors', () {
      final container = ProviderContainer();
      final router = container.read(routerProvider);

      expect(router, isA<GoRouter>());
      print('✅ Router created successfully');

      container.dispose();
    });

    test('Login should update auth state', () async {
      final container = ProviderContainer();

      // Initial state
      expect(container.read(authProvider), isA<AuthUnauthenticated>());

      // Perform login
      final success = await container.read(authProvider.notifier).login(
        'admin@erp.com',
        'admin123',
      );

      expect(success, isTrue);
      expect(container.read(authProvider), isA<AuthAuthenticated>());

      print('✅ Login updates auth state correctly');

      container.dispose();
    });

    test('Invalid login should show error', () async {
      final container = ProviderContainer();

      // Perform invalid login
      final success = await container.read(authProvider.notifier).login(
        'wrong@email.com',
        'wrongpassword',
      );

      expect(success, isFalse);
      final state = container.read(authProvider);
      expect(state, isA<AuthUnauthenticated>());

      print('✅ Invalid login handled correctly');

      container.dispose();
    });
  });

  group('Theme Tests', () {
    test('Light theme should be valid', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      print('✅ Light theme is valid');
    });

    test('Dark theme should be valid', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      print('✅ Dark theme is valid');
    });

    test('Theme colors should be accessible', () {
      expect(AppTheme.primaryColor, isNotNull);
      expect(AppTheme.secondaryColor, isNotNull);
      expect(AppTheme.errorColor, isNotNull);
      expect(AppTheme.successColor, isNotNull);
      expect(AppTheme.warningColor, isNotNull);
      expect(AppTheme.infoColor, isNotNull);
      print('✅ All theme colors accessible');
    });
  });
}
