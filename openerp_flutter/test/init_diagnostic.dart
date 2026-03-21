// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openerp_flutter/core/theme/app_theme.dart';
import 'package:openerp_flutter/logic/providers/auth_provider.dart';

void main() {
  print('=== OpenERP Initialization Diagnostic ===\n');

  // Test 1: Theme
  print('Test 1: Testing AppTheme...');
  try {
    final lightTheme = AppTheme.lightTheme;
    print('  - lightTheme: OK');

    final darkTheme = AppTheme.darkTheme;
    print('  - darkTheme: OK');

    final primary = AppTheme.primaryColor;
    print('  - primaryColor: $primary');
    print('✅ Theme tests passed!\n');
  } catch (e, stack) {
    print('❌ Theme test FAILED: $e');
    print('Stack: $stack\n');
  }

  // Test 2: Auth Provider
  print('Test 2: Testing Auth Provider...');
  try {
    final container = ProviderContainer();
    final authState = container.read(authProvider);
    print('  - Auth state type: ${authState.runtimeType}');

    if (authState is AuthUnauthenticated) {
      print('  - State is AuthUnauthenticated (expected)');
    } else {
      print('  - WARNING: Unexpected state: ${authState.runtimeType}');
    }

    container.dispose();
    print('✅ Auth provider tests passed!\n');
  } catch (e, stack) {
    print('❌ Auth provider test FAILED: $e');
    print('Stack: $stack\n');
  }

  // Test 3: AuthUser model
  print('Test 3: Testing AuthUser model...');
  try {
    final user = AuthUser(
      id: 'test-1',
      email: 'test@test.com',
      name: 'Test User',
      role: 'admin',
    );

    print('  - Created user: ${user.name}');
    print('  - isAdmin: ${user.isAdmin}');
    print('  - isManager: ${user.isManager}');

    final json = user.toJson();
    final fromJson = AuthUser.fromJson(json);
    print('  - toJson/fromJson: OK');

    print('✅ AuthUser tests passed!\n');
  } catch (e, stack) {
    print('❌ AuthUser test FAILED: $e');
    print('Stack: $stack\n');
  }

  print('=== Diagnostic Complete ===');
}
