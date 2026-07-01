import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../injection/injection_container.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title} | ${message.data}');
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // Request notification permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[FCM] Foreground message: ${message.notification?.title} | ${message.data}');
      });

      // Try to register token if already logged in
      await registerFcmToken();

      // Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM] Token refreshed: $newToken');
        try {
          final authRepo = sl<AuthRepository>();
          await authRepo.updateFcmToken(newToken);
        } catch (e) {
          debugPrint('[FCM] Error updating refreshed token: $e');
        }
      });
    } catch (e) {
      debugPrint('[FCM] Error initializing NotificationService: $e');
    }
  }

  static Future<void> registerFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) {
        debugPrint('[FCM] Token is null, skipping registration');
        return;
      }
      debugPrint('[FCM] Current token: $token');
      
      final authRepo = sl<AuthRepository>();
      await authRepo.updateFcmToken(token);
      debugPrint('[FCM] Token registration call completed');
    } catch (e) {
      debugPrint('[FCM] Error registering FCM token: $e');
    }
  }
}
