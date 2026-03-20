import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// User model for authentication
class AuthUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatar;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatar,
  });

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || isAdmin;
  
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'avatar': avatar,
    };
  }
}

/// Authentication state
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  final String? error;
  const AuthUnauthenticated([this.error]);
}

/// Authentication state notifier
@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() {
    _checkAuthStatus();
    return const AuthLoading();
  }
  
  /// Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    // TODO: Check SharedPreferences for saved session
    state = const AuthUnauthenticated();
  }
  
  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = const AuthLoading();
    
    try {
      // Demo login - in production, verify against database
      if (email == 'admin@erp.com' && password == 'admin123') {
        final user = AuthUser(
          id: 'user-1',
          email: email,
          name: 'المدير',
          role: 'admin',
        );
        state = AuthAuthenticated(user);
        return true;
      }
      
      state = const AuthUnauthenticated('بيانات الدخول غير صحيحة');
      return false;
    } catch (e) {
      state = AuthUnauthenticated(e.toString());
      return false;
    }
  }
  
  /// Logout current user
  Future<void> logout() async {
    state = const AuthLoading();
    // TODO: Clear SharedPreferences
    state = const AuthUnauthenticated();
  }
  
  /// Get current user (null if not authenticated)
  AuthUser? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => state is AuthAuthenticated;
}

/// Provider for current user
@riverpod
AuthUser? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
}

/// Provider for checking if authenticated
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
}
