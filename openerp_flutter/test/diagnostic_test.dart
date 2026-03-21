import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openerp_flutter/main.dart';
import 'package:openerp_flutter/logic/providers/auth_provider.dart';
import 'package:openerp_flutter/core/theme/app_theme.dart';

// This test runs the exact initialization sequence to catch errors
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Diagnostic Tests', () {
    test('AppTheme should create light theme without errors', () {
      try {
        final theme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF10B981),
            primaryContainer: const Color(0xFF10B981).withOpacity(0.1),
            secondary: const Color(0xFF14B8A6),
            secondaryContainer: const Color(0xFF14B8A6).withOpacity(0.1),
            error: const Color(0xFFEF4444),
            surface: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFF1F2937),
          ),
        );

        expect(theme, isNotNull);
        print('✅ Light theme created successfully');
      } catch (e, stack) {
        print('❌ Light theme error: $e');
        print('Stack: $stack');
        rethrow;
      }
    });

    test('AppTheme should create dark theme without errors', () {
      try {
        final theme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF10B981),
            primaryContainer: const Color(0xFF10B981).withOpacity(0.2),
            secondary: const Color(0xFF14B8A6),
            secondaryContainer: const Color(0xFF14B8A6).withOpacity(0.2),
            error: const Color(0xFFEF4444),
            surface: const Color(0xFF1E1E1E),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
          ),
        );

        expect(theme, isNotNull);
        print('✅ Dark theme created successfully');
      } catch (e, stack) {
        print('❌ Dark theme error: $e');
        print('Stack: $stack');
        rethrow;
      }
    });

    test('DataTableTheme should work with MaterialStateProperty', () {
      try {
        final theme = DataTableThemeData(
          headingRowColor: MaterialStateProperty.all(const Color(0xFF10B981)),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          dividerThickness: 1,
        );

        expect(theme, isNotNull);
        print('✅ DataTableTheme created successfully');
      } catch (e, stack) {
        print('❌ DataTableTheme error: $e');
        print('Stack: $stack');
        rethrow;
      }
    });
  });

  group('Widget Initialization Tests', () {
    testWidgets('OpenERPApp should build without errors', (tester) async {
      FlutterError.onError = (details) {
        print('❌ FlutterError during build: ${details.exception}');
        print('Stack: ${details.stack}');
      };

      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: OpenERPApp(),
          ),
        );

        // Allow async operations to complete
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Check if error widget is shown
        final errorFinder = find.text('حدث خطأ غير متوقع');
        if (errorFinder.evaluate().isNotEmpty) {
          print('❌ Error widget is being shown!');
          throw Exception('Error widget shown during initialization');
        }

        print('✅ OpenERPApp built successfully');
      } catch (e, stack) {
        print('❌ OpenERPApp build error: $e');
        print('Stack: $stack');
        rethrow;
      }
    });

    testWidgets('ProviderScope initializes correctly', (tester) async {
      try {
        final container = ProviderContainer();

        // Test that auth provider initializes
        final authState = container.read(authProvider);
        print('Auth state type: ${authState.runtimeType}');

        // Should be AuthUnauthenticated
        expect(authState, isA<AuthUnauthenticated>());
        print('✅ Auth provider initializes as AuthUnauthenticated');

        container.dispose();
      } catch (e, stack) {
        print('❌ ProviderScope error: $e');
        print('Stack: $stack');
        rethrow;
      }
    });
  });

  group('AppTheme Class Tests', () {
    test('AppTheme.lightTheme should be accessible', () {
      try {
        final theme = AppTheme.lightTheme;
        expect(theme, isNotNull);
        print('✅ AppTheme.lightTheme accessible');
      } catch (e, stack) {
        print('❌ AppTheme.lightTheme error: $e');
        print('Stack: $stack');
        rethrow;
      }
    });

    test('AppTheme.darkTheme should be accessible', () {
      try {
        final theme = AppTheme.darkTheme;
        expect(theme, isNotNull);
        print('✅ AppTheme.darkTheme accessible');
      } catch (e, stack) {
        print('❌ AppTheme.darkTheme error: $e');
        print('Stack: $stack');
        rethrow;
      }
    });

    test('AppTheme colors should be accessible', () {
      try {
        expect(AppTheme.primaryColor, const Color(0xFF10B981));
        expect(AppTheme.secondaryColor, const Color(0xFF14B8A6));
        expect(AppTheme.errorColor, const Color(0xFFEF4444));
        expect(AppTheme.successColor, const Color(0xFF22C55E));
        expect(AppTheme.warningColor, const Color(0xFFF59E0B));
        expect(AppTheme.infoColor, const Color(0xFF3B82F6));
        print('✅ All AppTheme colors accessible');
      } catch (e, stack) {
        print('❌ AppTheme colors error: $e');
        print('Stack: $stack');
        rethrow;
      }
    });
  });
}
