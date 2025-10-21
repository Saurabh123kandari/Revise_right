import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  static bool _initialized = false;
  
  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();
      
      // Request permissions
      await requestPermissions();
      
      // Print FCM token
      await _printFCMToken();
      
      _initialized = true;
      debugPrint('NotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('NotificationService: Initialization failed - $e');
      rethrow;
    }
  }
  
  /// Initialize Firebase Cloud Messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // Set up message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Configure notification settings
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    debugPrint('Firebase Messaging: Initialized');
  }
  
  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    try {
      // Request FCM permissions
      final fcmSettings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      final granted = fcmSettings.authorizationStatus == AuthorizationStatus.authorized;
      
      debugPrint('NotificationService: Permissions granted - $granted');
      return granted;
    } catch (e) {
      debugPrint('NotificationService: Permission request failed - $e');
      return false;
    }
  }
  
  /// Print FCM token for debugging
  static Future<void> _printFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('NotificationService: Failed to get FCM token - $e');
    }
  }
  
  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('NotificationService: Received foreground message - ${message.notification?.title}');
  }
  
  /// Handle message opened from notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('NotificationService: App opened from notification - ${message.notification?.title}');
    // Handle navigation based on message data
    _handleNotificationNavigation(message.data);
  }
  
  /// Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('NotificationService: Received background message - ${message.notification?.title}');
    // Handle background message processing
  }
  
  /// Handle notification navigation
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Implement navigation logic based on notification data
    debugPrint('NotificationService: Handling navigation for - $data');
  }
  
  /// Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('NotificationService: Failed to get FCM token - $e');
      return null;
    }
  }
}

/// Top-level function for background message handling
/// This must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await NotificationService._handleBackgroundMessage(message);
}