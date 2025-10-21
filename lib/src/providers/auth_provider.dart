import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.currentUserStream;
});

// Current user model provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        return Stream.fromFuture(FirebaseService.getUser(user.uid));
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Auth controller provider
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController();
});

class AuthController {
  // Register new user
  Future<UserModel?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      return await AuthService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Login user
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      return await AuthService.login(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      await AuthService.logout();
    } catch (e) {
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await AuthService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }
}
