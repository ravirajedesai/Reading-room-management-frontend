import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_text_field.dart';

import 'register_page.dart';
import 'dashboard_page.dart';
import 'library_selection_page.dart';
import 'owner_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ==========================================================
  // VARIABLES
  // ==========================================================

  bool loading = false;
  bool hidePassword = true;

  String? serverError;


  // ==========================================================
  // VALIDATE MOBILE
  // ==========================================================

  String? _validateMobile(String? value) {
    final mobile = value?.trim() ?? '';

    if (mobile.isEmpty) {
      return "Mobile number is required";
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      return "Enter a valid 10 digit mobile number";
    }

    return null;
  }

  // ==========================================================
  // VALIDATE PASSWORD
  // ==========================================================

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return "Password is required";
    }

    return null;
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    setState(() {
      serverError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final mobile = mobileController.text.trim();
    final password = passwordController.text;

    setState(() {
      loading = true;
    });

    try {
      // ======================================================
      // CALL LOGIN API
      // ======================================================

      final response = await AuthService.login(
        mobile: mobile,
        password: password,
      );

      if (!mounted) return;

      // ======================================================
      // GET USER ID
      // ======================================================

      final int? userId = response['id'] is int
          ? response['id'] as int
          : int.tryParse(response['id']?.toString() ?? '');

      // ======================================================
      // GET USER NAME
      // ======================================================

      final String name = response['name']?.toString().trim().isNotEmpty == true
          ? response['name'].toString()
          : 'User';

      // ======================================================
      // GET MOBILE
      // ======================================================

      final String responseMobile =
          response['mobile']?.toString().trim().isNotEmpty == true
          ? response['mobile'].toString()
          : mobile;

      // ======================================================
      // GET ROLE
      // ======================================================

      final String? roleValue = response['role']?.toString().trim();

      // ======================================================
      // GET JWT TOKEN
      // ======================================================

      final String? token = response['token']?.toString().trim();

      // ======================================================
      // CHECK ROLE
      // ======================================================

      if (roleValue == null || roleValue.isEmpty) {
        throw Exception("Login response does not contain user role.");
      }

      final String role = roleValue.toUpperCase();

      // ======================================================
      // DEBUG
      // ======================================================

      debugPrint("======================================");
      debugPrint("LOGIN SUCCESS");
      debugPrint("USER ID     : $userId");
      debugPrint("USER NAME   : $name");
      debugPrint("USER MOBILE : $responseMobile");
      debugPrint("USER ROLE   : $role");
      debugPrint(
        "TOKEN       : ${token != null ? 'RECEIVED' : 'NOT RECEIVED'}",
      );
      debugPrint("======================================");

      // ======================================================
      // CHECK USER ID
      // ======================================================

      if (userId == null) {
        _showError("Login successful, but User ID was not received.");
        return;
      }

      // ======================================================
      // CHECK JWT TOKEN
      // ======================================================

      if (token == null || token.isEmpty) {
        _showError("Login successful, but security token was not received.");
        return;
      }

      // ======================================================
      // SAVE FCM TOKEN
      // ======================================================

      await NotificationService.initializeFcmAndSaveToken(userId);

      // ======================================================
      // SAVE LOGIN SESSION
      // ======================================================

      await SessionService.saveLogin(
        userId: userId,
        name: name,
        mobile: responseMobile,
        role: role,
        token: token,
      );

      debugPrint("LOGIN SESSION SAVED SUCCESSFULLY");

      if (!mounted) return;

      // ======================================================
      // OWNER DASHBOARD
      // ======================================================

      if (role == 'OWNER') {
        debugPrint("OPENING OWNER DASHBOARD");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerDashboardPage(
              userId: userId,
              name: name,
              mobile: responseMobile,
            ),
          ),
        );
      }
      // ======================================================
      // STUDENT DASHBOARD
      // ======================================================
      else {
        debugPrint("OPENING STUDENT DASHBOARD");

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LibrarySelectionPage()));
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint("LOGIN ERROR: $e");

      // ======================================================
      // SHOW CLEAN ERROR
      // ======================================================

      String message = e.toString();

      if (message.startsWith("Exception: ")) {
        message = message.substring("Exception: ".length);
      }

      setState(() {
        serverError = message;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ==========================================================
  // SHOW ERROR SNACKBAR
  // ==========================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    mobileController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ==========================================================

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),

              child: Column(
                children: [
                  // ==================================================
                  // LOGO
                  // ==================================================
                  Container(
                    height: 82,
                    width: 82,

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff4F46E5), Color(0xff6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                      borderRadius: BorderRadius.circular(26),

                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff4F46E5).withOpacity(0.25),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: const Icon(
                      Icons.local_library_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ==================================================
                  // TITLE
                  // ==================================================
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff111827),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Login to manage your reading room",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xff6B7280)),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // CARD
                  // ==================================================
                  Container(
                    padding: const EdgeInsets.all(24),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),

                    child: Form(
                      key: _formKey,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,

                        children: [
                          // ========================================
                          // SERVER ERROR
                          // ========================================
                          if (serverError != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),

                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.red.shade100),
                              ),

                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red.shade700,
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      serverError!,
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],

                          // ========================================
                          // MOBILE
                          // ========================================
                          CustomTextField(
                            controller: mobileController,
                            label: "Mobile Number",
                            hint: "Enter 10 digit mobile number",
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            validator: _validateMobile,
                            onChanged: (_) {
                              if (serverError != null) {
                                setState(() {
                                  serverError = null;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 18),

                          // ========================================
                          // PASSWORD
                          // ========================================
                          CustomTextField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            label: "Password",
                            hint: "Enter your password",
                            icon: Icons.lock_rounded,
                            validator: _validatePassword,
                            onChanged: (_) {
                              if (serverError != null) {
                                setState(() {
                                  serverError = null;
                                });
                              }
                            },
                            suffixIcon: IconButton(
                              tooltip: hidePassword
                                  ? "Show password"
                                  : "Hide password",
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                              onPressed: () {
                                setState(() {
                                  hidePassword = !hidePassword;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 26),

                          // ========================================
                          // LOGIN BUTTON
                          // ========================================
                          SizedBox(
                            height: 56,

                            child: ElevatedButton(
                              onPressed: loading ? null : login,

                              style: ElevatedButton.styleFrom(
                                elevation: 0,

                                backgroundColor: const Color(0xff4F46E5),

                                foregroundColor: Colors.white,

                                disabledBackgroundColor: Colors.grey.shade300,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),

                              child: loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,

                                      children: [
                                        Text(
                                          "Login",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),

                                        SizedBox(width: 8),

                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ========================================
                          // REGISTER
                          // ========================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Color(0xff6B7280)),
                              ),

                              GestureDetector(
                                onTap: loading
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterPage(),
                                          ),
                                        );
                                      },

                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                    color: Color(0xff4F46E5),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Secure access to your reading room",
                    style: TextStyle(fontSize: 12, color: Color(0xff9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

