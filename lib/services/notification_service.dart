import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_service.dart';

class NotificationService {
  // ==========================================================
  // FCM TOKEN HANDLING
  // ==========================================================
  static Future<void> initializeFcmAndSaveToken(int userId) async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // ------------------------------------------------------
      // REQUEST NOTIFICATION PERMISSION
      // ------------------------------------------------------
      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint("FCM PERMISSION STATUS: ${settings.authorizationStatus}");

      // ------------------------------------------------------
      // GET CURRENT FCM TOKEN
      // ------------------------------------------------------
      final String? fcmToken = await messaging.getToken();

      debugPrint("======================================");
      debugPrint("FCM TOKEN");
      debugPrint("USER ID : $userId");
      debugPrint("TOKEN  : $fcmToken");
      debugPrint("======================================");

      // ------------------------------------------------------
      // SAVE CURRENT TOKEN
      // ------------------------------------------------------
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await AuthService.saveFcmToken(userId: userId, token: fcmToken);
        debugPrint("FCM TOKEN SAVED SUCCESSFULLY FOR USER: $userId");
      } else {
        debugPrint("FCM TOKEN IS NULL OR EMPTY FOR USER: $userId");
      }

      // ------------------------------------------------------
      // LISTEN FOR FUTURE TOKEN REFRESH
      // ------------------------------------------------------
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (String newToken) async {
          try {
            debugPrint("======================================");
            debugPrint("FCM TOKEN REFRESHED");
            debugPrint("USER ID : $userId");
            debugPrint("NEW TOKEN: $newToken");
            debugPrint("======================================");

            if (newToken.isNotEmpty) {
              await AuthService.saveFcmToken(userId: userId, token: newToken);
              debugPrint("NEW FCM TOKEN SAVED SUCCESSFULLY FOR USER: $userId");
            }
          } catch (e) {
            debugPrint("FCM TOKEN REFRESH SAVE ERROR: $e");
          }
        },
        onError: (error) {
          debugPrint("FCM TOKEN REFRESH LISTENER ERROR: $error");
        },
      );
    } catch (e) {
      // FCM failure should NEVER block login.
      debugPrint("FCM TOKEN ERROR: $e");
    }
  }
}
