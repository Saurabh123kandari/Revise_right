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
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user != null) {
        final userModel = await FirebaseService.getUser(user.uid);
        // If user doesn't exist in Firestore, create it
        if (userModel == null) {
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'Student',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            preferences: {},
          );
          await FirebaseService.createUser(newUser);
          return newUser;
        }
        return userModel;
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
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
