import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

/// User preferences model
class UserPreferences {
  final ThemeMode themeMode;
  final bool enableNotifications;
  final int breakIntervalMinutes;
  final bool enableStudyReminders;
  final Map<String, dynamic> customSettings;

  const UserPreferences({
    required this.themeMode,
    required this.enableNotifications,
    required this.breakIntervalMinutes,
    required this.enableStudyReminders,
    required this.customSettings,
  });

  static const UserPreferences _defaults = UserPreferences(
    themeMode: ThemeMode.system,
    enableNotifications: true,
    breakIntervalMinutes: 25, // Default to Pomodoro style
    enableStudyReminders: true,
    customSettings: {},
  );

  factory UserPreferences.defaults() => _defaults;

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'enableNotifications': enableNotifications,
      'breakIntervalMinutes': breakIntervalMinutes,
      'enableStudyReminders': enableStudyReminders,
      'customSettings': customSettings,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == map['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      enableNotifications: map['enableNotifications'] ?? true,
      breakIntervalMinutes: map['breakIntervalMinutes'] ?? 25,
      enableStudyReminders: map['enableStudyReminders'] ?? true,
      customSettings: map['customSettings'] ?? {},
    );
  }

  UserPreferences copyWith({
    ThemeMode? themeMode,
    bool? enableNotifications,
    int? breakIntervalMinutes,
    bool? enableStudyReminders,
    Map<String, dynamic>? customSettings,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      breakIntervalMinutes: breakIntervalMinutes ?? this.breakIntervalMinutes,
      enableStudyReminders: enableStudyReminders ?? this.enableStudyReminders,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Controller for managing user preferences
class SettingsController extends StateNotifier<AsyncValue<UserPreferences>> {
  bool _hasLoaded = false;
  
  SettingsController() : super(AsyncValue.data(UserPreferences.defaults())) {
    // Load preferences when controller is created
    loadPreferences();
  }

  /// Load user preferences from Firestore
  Future<void> loadPreferences() async {
    if (_hasLoaded) return;
    
    state = const AsyncValue.loading();
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      state = AsyncValue.data(UserPreferences.defaults());
      _hasLoaded = true;
      return;
    }

    try {
      final userModel = await FirebaseService.getUser(firebaseUser.uid);
      if (userModel?.preferences != null && userModel!.preferences.isNotEmpty) {
        state = AsyncValue.data(UserPreferences.fromMap(userModel.preferences));
      } else {
        state = AsyncValue.data(UserPreferences.defaults());
      }
      _hasLoaded = true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      _hasLoaded = true;
    }
  }

  /// Update a specific preference
  Future<void> updatePreference({
    ThemeMode? themeMode,
    bool? enableNotifications,
    int? breakIntervalMinutes,
    bool? enableStudyReminders,
  }) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final currentPreferences = state.value ?? UserPreferences.defaults();
    final updatedPreferences = currentPreferences.copyWith(
      themeMode: themeMode,
      enableNotifications: enableNotifications,
      breakIntervalMinutes: breakIntervalMinutes,
      enableStudyReminders: enableStudyReminders,
    );

    // Update local state
    state = AsyncValue.data(updatedPreferences);

    // Save to Firestore
    try {
      await FirebaseService.updateUserPreferences(
        firebaseUser.uid,
        updatedPreferences.toMap(),
      );
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentPreferences);
      rethrow;
    }
  }

  /// Update custom settings
  Future<void> updateCustomSetting(String key, dynamic value) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final currentPreferences = state.value ?? UserPreferences.defaults();
    final updatedCustomSettings = Map<String, dynamic>.from(currentPreferences.customSettings);
    updatedCustomSettings[key] = value;

    final updatedPreferences = currentPreferences.copyWith(
      customSettings: updatedCustomSettings,
    );

    // Update local state
    state = AsyncValue.data(updatedPreferences);

    // Save to Firestore
    try {
      await FirebaseService.updateUserPreferences(
        firebaseUser.uid,
        updatedPreferences.toMap(),
      );
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentPreferences);
      rethrow;
    }
  }
}

/// Provider for settings controller
final settingsControllerProvider = StateNotifierProvider<SettingsController, AsyncValue<UserPreferences>>((ref) {
  return SettingsController();
});

/// Provider for current user preferences
final userPreferencesProvider = Provider<UserPreferences>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  
  return settings.when(
    data: (preferences) => preferences,
    loading: () => UserPreferences.defaults(),
    error: (_, __) => UserPreferences.defaults(),
  );
});

/// Provider for theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final preferences = ref.watch(userPreferencesProvider);
  return preferences.themeMode;
});
