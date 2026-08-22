import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/library_selection_page.dart';
import 'screens/owner_dashboard_page.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

// Global ScaffoldMessengerKey for in-app floating notification banners
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('======================================');
  debugPrint('BACKGROUND NOTIFICATION');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('======================================');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // INITIALIZE FIREBASE
  // ==========================================================

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ==========================================================
  // FCM BACKGROUND HANDLER
  // ==========================================================

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ==========================================================
  // REQUEST NOTIFICATION PERMISSION
  // ==========================================================

  final notificationSettings = await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);

  debugPrint(
    'Notification permission: '
    '${notificationSettings.authorizationStatus}',
  );

  // ==========================================================
  // FOREGROUND PRESENTATION OPTIONS (iOS / macOS)
  // ==========================================================

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // ==========================================================
  // GET FCM TOKEN
  // ==========================================================

  try {
    final String? token = await FirebaseMessaging.instance.getToken();

    debugPrint('======================================');
    debugPrint('FCM TOKEN: $token');
    debugPrint('======================================');
  } catch (e) {
    debugPrint('FCM TOKEN ERROR: $e');
  }

  // ==========================================================
  // FOREGROUND NOTIFICATION (In-App Floating Banner)
  // ==========================================================

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('======================================');
    debugPrint('FOREGROUND NOTIFICATION');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('======================================');

    final title = message.notification?.title ??
        message.data['title'] ??
        'Library Alert';
    final body = message.notification?.body ??
        message.data['body'] ??
        '';

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 6),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4054C7).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active,
                  color: Color(0xFF6576D8), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });

  // ==========================================================
  // START APPLICATION
  // ==========================================================

  runApp(const LibraryManagementApp());
}

// ============================================================
// APPLICATION
// ============================================================

class LibraryManagementApp extends StatelessWidget {
  const LibraryManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Library Management',
      theme: AppTheme.lightTheme,
      home: const StartPage(),
    );
  }
}

// ============================================================
// START PAGE
// ============================================================

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  void initState() {
    super.initState();
    checkLoginSession();
  }

  // ==========================================================
  // CHECK LOGIN SESSION
  // ==========================================================

  Future<void> checkLoginSession() async {
    try {
      final bool loggedIn = await SessionService.isLoggedIn();

      debugPrint('======================================');
      debugPrint('CHECKING SAVED LOGIN SESSION');
      debugPrint('LOGGED IN: $loggedIn');
      debugPrint('======================================');

      if (!loggedIn) {
        await _goToLogin();
        return;
      }

      final int? userId = await SessionService.getUserId();
      final String? name = await SessionService.getName();
      final String? mobile = await SessionService.getMobile();
      final String? role = await SessionService.getRole();
      final String? token = await SessionService.getToken();

      debugPrint('======================================');
      debugPrint('SAVED SESSION: USER ID: $userId, NAME: $name, ROLE: $role');
      debugPrint('======================================');

      if (userId == null ||
          role == null ||
          role.trim().isEmpty ||
          token == null ||
          token.trim().isEmpty) {
        await SessionService.logout();
        await _goToLogin();
        return;
      }

      final String userRole = role.trim().toUpperCase();

      if (userRole == 'OWNER') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerDashboardPage(
              userId: userId,
              name: name ?? 'Owner',
              mobile: mobile ?? '',
            ),
          ),
        );
        return;
      }

      if (userRole == 'STUDENT') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LibrarySelectionPage(),
          ),
        );
        return;
      }

      await SessionService.logout();
      await _goToLogin();
    } catch (e) {
      debugPrint('SESSION CHECK ERROR: $e');
      await SessionService.logout();
      await _goToLogin();
    }
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
