import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'logic/providers/app_state_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
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
