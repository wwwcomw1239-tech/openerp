import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_state_provider.g.dart';

/// App locale
enum AppLocale {
  ar('ar', 'العربية'),
  en('en', 'English');

  final String code;
  final String name;

  const AppLocale(this.code, this.name);
}

/// App theme mode
enum AppThemeMode {
  system,
  light,
  dark,
}

/// App-wide state model
class AppState {
  final AppLocale locale;
  final AppThemeMode themeMode;
  final bool isSidebarExpanded;
  final String activeModule;

  const AppState({
    this.locale = AppLocale.ar,
    this.themeMode = AppThemeMode.system,
    this.isSidebarExpanded = true,
    this.activeModule = 'dashboard',
  });

  AppState copyWith({
    AppLocale? locale,
    AppThemeMode? themeMode,
    bool? isSidebarExpanded,
    String? activeModule,
  }) {
    return AppState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      isSidebarExpanded: isSidebarExpanded ?? this.isSidebarExpanded,
      activeModule: activeModule ?? this.activeModule,
    );
  }
}

/// App state notifier
/// Uses keepAlive: true to persist app state
@Riverpod(keepAlive: true)
class AppStateNotifier extends _$AppStateNotifier {
  @override
  AppState build() {
    return const AppState();
  }

  /// Set locale
  void setLocale(AppLocale locale) {
    state = state.copyWith(locale: locale);
  }

  /// Set theme mode
  void setThemeMode(AppThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }

  /// Toggle sidebar
  void toggleSidebar() {
    state = state.copyWith(isSidebarExpanded: !state.isSidebarExpanded);
  }

  /// Set active module
  void setActiveModule(String module) {
    state = state.copyWith(activeModule: module);
  }
}

/// Provider for current locale
@riverpod
AppLocale currentLocale(CurrentLocaleRef ref) {
  return ref.watch(appStateNotifierProvider).locale;
}

/// Provider for theme mode
@riverpod
AppThemeMode themeMode(ThemeModeRef ref) {
  return ref.watch(appStateNotifierProvider).themeMode;
}

/// Provider for sidebar state
@riverpod
bool isSidebarExpanded(IsSidebarExpandedRef ref) {
  return ref.watch(appStateNotifierProvider).isSidebarExpanded;
}

/// Provider for active module
@riverpod
String activeModule(ActiveModuleRef ref) {
  return ref.watch(appStateNotifierProvider).activeModule;
}
