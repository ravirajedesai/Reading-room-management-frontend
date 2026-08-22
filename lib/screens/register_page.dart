import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_text_field.dart';
import 'library_selection_page.dart';
import 'owner_dashboard_page.dart';
import 'super_admin_dashboard_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ==========================================================
  // VARIABLES
  // ==========================================================

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String? serverError;

  // ==========================================================
  // VALIDATE NAME
  // ==========================================================

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return "Name is required";
    }
    if (name.length < 2) {
      return "Enter a valid name (at least 2 characters)";
    }
    return null;
  }

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
    if (password.length < 6) {
      return "Password must contain at least 6 characters";
    }
    return null;
  }

  // ==========================================================
  // VALIDATE CONFIRM PASSWORD
  // ==========================================================

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) {
      return "Please confirm your password";
    }
    if (confirmPassword != passwordController.text) {
      return "Passwords do not match";
    }
    return null;
  }

  // ==========================================================
  // REGISTER & AUTO-LOGIN
  // ==========================================================

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    setState(() {
      serverError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = nameController.text.trim();
    final mobile = mobileController.text.trim();
    final password = passwordController.text;

    setState(() {
      loading = true;
    });

    try {
      // 1. Call Register Backend
      final response = await AuthService.register(
        name: name,
        mobile: mobile,
        password: password,
      );

      if (!mounted) return;

      int? userId = response['id'] is int
          ? response['id'] as int
          : int.tryParse(response['id']?.toString() ?? '');

      String? token = response['token']?.toString();
      String role = (response['role']?.toString() ?? 'STUDENT').toUpperCase();
      String registeredName = response['name']?.toString() ?? name;

      // 2. If token is missing, perform automatic background login
      if (token == null || token.isEmpty || userId == null) {
        final loginRes = await AuthService.login(mobile: mobile, password: password);
        userId = loginRes['id'] is int ? loginRes['id'] as int : int.tryParse(loginRes['id']?.toString() ?? '');
        token = loginRes['token']?.toString();
        role = (loginRes['role']?.toString() ?? 'STUDENT').toUpperCase();
      }

      // 3. Save Session & Token
      if (userId != null && token != null && token.isNotEmpty) {
        await SessionService.saveLogin(
          userId: userId,
          name: registeredName,
          mobile: mobile,
          role: role,
          token: token,
        );

        // 4. Initialize FCM Push Notifications
        await NotificationService.initializeFcmAndSaveToken(userId);
      }

      if (!mounted) return;

      // 5. Success SnackBar
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Welcome, $registeredName! Account created.",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );

      // 6. Direct Frictionless Navigation (Auto-Login)
      if (role == 'SUPER_ADMIN') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => SuperAdminDashboardPage()),
          (route) => false,
        );
      } else if (role == 'OWNER') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerDashboardPage(
              userId: userId ?? 0,
              name: registeredName,
              mobile: mobile,
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LibrarySelectionPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (message.startsWith("Exception: ")) {
        message = message.substring("Exception: ".length);
      }
      setState(() {
        serverError = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  // Logo
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff4F46E5), Color(0xff6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff4F46E5).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff111827),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Register as a student to book reading seats",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xff6B7280)),
                  ),

                  const SizedBox(height: 24),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                              const SizedBox(height: 18),
                            ],

                            // Full Name
                            CustomTextField(
                              controller: nameController,
                              label: "Full Name",
                              hint: "Enter your full name",
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              validator: _validateName,
                              onChanged: (_) {
                                if (serverError != null) setState(() => serverError = null);
                              },
                            ),

                            const SizedBox(height: 16),

                            // Mobile Number with +91 Prefix
                            CustomTextField(
                              controller: mobileController,
                              label: "Mobile Number",
                              hint: "10-digit mobile number",
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              prefixWidget: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.phone_rounded, color: Color(0xFF6366F1), size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      '+91',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    VerticalDivider(width: 1, thickness: 1, color: Color(0xFFCBD5E1)),
                                  ],
                                ),
                              ),
                              validator: _validateMobile,
                              onChanged: (_) {
                                if (serverError != null) setState(() => serverError = null);
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password
                            CustomTextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              label: "Password",
                              hint: "Create a password (min 6 chars)",
                              icon: Icons.lock_outline_rounded,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: _validatePassword,
                              onChanged: (_) {
                                if (serverError != null) setState(() => serverError = null);
                              },
                              suffixIcon: IconButton(
                                tooltip: obscurePassword ? "Show password" : "Hide password",
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                ),
                                onPressed: () => setState(() => obscurePassword = !obscurePassword),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Confirm Password
                            CustomTextField(
                              controller: confirmPasswordController,
                              obscureText: obscureConfirmPassword,
                              label: "Confirm Password",
                              hint: "Re-enter your password",
                              icon: Icons.lock_outline_rounded,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => register(),
                              autofillHints: const [AutofillHints.newPassword],
                              validator: _validateConfirmPassword,
                              onChanged: (_) {
                                if (serverError != null) setState(() => serverError = null);
                              },
                              suffixIcon: IconButton(
                                tooltip: obscureConfirmPassword ? "Show password" : "Hide password",
                                icon: Icon(
                                  obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                ),
                                onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Register Button
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: loading ? null : register,
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
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Create Account",
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

                            const SizedBox(height: 18),

                            // Google Play Compliant Terms & Privacy Policy Notice
                            Center(
                              child: Text(
                                "By registering, you agree to our Terms of Service\nand Privacy Policy.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade500,
                                  height: 1.35,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Back to Login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account? ",
                                  style: TextStyle(color: Color(0xff6B7280)),
                                ),
                                GestureDetector(
                                  onTap: loading ? null : () => Navigator.pop(context),
                                  child: const Text(
                                    "Login",
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
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}