import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'logic/providers/app_state_provider.dart';

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Catch any errors during app initialization
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log error in debug mode
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  runApp(
    const ProviderScope(
      child: OpenERPApp(),
    ),
  );
}

class OpenERPApp extends ConsumerWidget {
  const OpenERPApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(currentLocaleProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'OpenERP',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(themeMode),

      // Locale configuration (RTL support for Arabic)
      locale: Locale(locale.code),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localeListResolutionCallback: (locales, supportedLocales) {
        return Locale(locale.code);
      },

      // Router configuration
      routerConfig: router,

      // Builder for error handling
      builder: (context, child) {
        // Wrap with error handling
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'حدث خطأ غير متوقع',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى إعادة تشغيل التطبيق',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        };

        return child ?? const SizedBox.shrink();
      },
    );
  }

  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
