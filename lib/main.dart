import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/owner_dashboard_page.dart';
import 'services/session_service.dart';

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
  // GET FCM TOKEN
  // ==========================================================

  try {
    final String? token = await FirebaseMessaging.instance.getToken();

    debugPrint('======================================');
    debugPrint('FCM TOKEN');
    debugPrint('$token');
    debugPrint('======================================');
  } catch (e) {
    debugPrint('FCM TOKEN ERROR: $e');
  }

  // ==========================================================
  // FOREGROUND NOTIFICATION
  // ==========================================================

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('======================================');
    debugPrint('FOREGROUND NOTIFICATION');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('======================================');
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
      debugShowCheckedModeBanner: false,

      title: 'Library Management',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),

      // Start from session checking page
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

      // ========================================================
      // NOT LOGGED IN
      // ========================================================

      if (!loggedIn) {
        await _goToLogin();
        return;
      }

      // ========================================================
      // GET SAVED SESSION DATA
      // ========================================================

      final int? userId = await SessionService.getUserId();

      final String? name = await SessionService.getName();

      final String? mobile = await SessionService.getMobile();

      final String? role = await SessionService.getRole();

      final String? token = await SessionService.getToken();

      // ========================================================
      // DEBUG SESSION
      // ========================================================

      debugPrint('======================================');
      debugPrint('SAVED SESSION');
      debugPrint('USER ID     : $userId');
      debugPrint('USER NAME   : $name');
      debugPrint('USER MOBILE : $mobile');
      debugPrint('USER ROLE   : $role');
      debugPrint(
        'JWT TOKEN   : '
        '${token != null && token.isNotEmpty ? 'AVAILABLE' : 'NOT AVAILABLE'}',
      );
      debugPrint('======================================');

      // ========================================================
      // VALIDATE SESSION
      // ========================================================

      if (userId == null ||
          role == null ||
          role.trim().isEmpty ||
          token == null ||
          token.trim().isEmpty) {
        debugPrint('INVALID SESSION');
        debugPrint('CLEARING SESSION');

        await SessionService.logout();

        await _goToLogin();

        return;
      }

      // ========================================================
      // NORMALIZE ROLE
      // ========================================================

      final String userRole = role.trim().toUpperCase();

      debugPrint('NORMALIZED ROLE: $userRole');

      // ========================================================
      // OWNER
      // ========================================================

      if (userRole == 'OWNER') {
        debugPrint('======================================');
        debugPrint('OPENING OWNER DASHBOARD');
        debugPrint('======================================');

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

      // ========================================================
      // STUDENT
      // ========================================================

      if (userRole == 'STUDENT') {
        debugPrint('======================================');
        debugPrint('OPENING STUDENT DASHBOARD');
        debugPrint('======================================');

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              userId: userId,
              name: name ?? 'User',
              mobile: mobile ?? '',
            ),
          ),
        );

        return;
      }

      // ========================================================
      // UNKNOWN ROLE
      // ========================================================

      debugPrint('UNKNOWN ROLE: $userRole');

      await SessionService.logout();

      await _goToLogin();
    } catch (e) {
      debugPrint('SESSION CHECK ERROR: $e');

      await SessionService.logout();

      await _goToLogin();
    }
  }

  // ==========================================================
  // GO TO LOGIN
  // ==========================================================

  Future<void> _goToLogin() async {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
