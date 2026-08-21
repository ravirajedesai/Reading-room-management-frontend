import 'package:flutter/material.dart';

import '../services/auth_service.dart';

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

  final TextEditingController confirmPasswordController =
      TextEditingController();

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
      return "Enter a valid name";
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
  // REGISTER
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
      // ======================================================
      // CALL BACKEND
      // ======================================================

      final response = await AuthService.register(
        name: name,
        mobile: mobile,
        password: password,
      );

      if (!mounted) return;

      final registeredName =
          response['name']?.toString().trim().isNotEmpty == true
          ? response['name'].toString()
          : name;

      // ======================================================
      // SUCCESS
      // ======================================================

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: Colors.green.shade700,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),

            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    "Account created successfully for $registeredName",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );

      // ======================================================
      // GO BACK TO LOGIN
      // ======================================================

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      debugPrint("REGISTRATION ERROR: $e");

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
  // INPUT DECORATION
  // ==========================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,

      hintText: hint,

      prefixIcon: Icon(icon),

      suffixIcon: suffixIcon,

      filled: true,

      fillColor: Colors.grey.shade50,

      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff4F46E5), width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),

      errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        foregroundColor: const Color(0xff111827),

        title: const Text(
          "Create Account",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),

              child: Column(
                children: [
                  // ==================================================
                  // ICON
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
                      Icons.person_add_alt_1_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // TITLE
                  // ==================================================
                  const Text(
                    "Join Your Reading Room",
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff111827),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Create your account and reserve your seat",
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
                          // NAME
                          // ========================================
                          TextFormField(
                            controller: nameController,

                            textCapitalization: TextCapitalization.words,

                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,

                            validator: _validateName,

                            onChanged: (_) {
                              if (serverError != null) {
                                setState(() {
                                  serverError = null;
                                });
                              }
                            },

                            decoration: _inputDecoration(
                              label: "Full Name",
                              hint: "Enter your full name",
                              icon: Icons.person_outline_rounded,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ========================================
                          // MOBILE
                          // ========================================
                          TextFormField(
                            controller: mobileController,

                            keyboardType: TextInputType.phone,

                            maxLength: 10,

                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,

                            validator: _validateMobile,

                            onChanged: (_) {
                              if (serverError != null) {
                                setState(() {
                                  serverError = null;
                                });
                              }
                            },

                            decoration: _inputDecoration(
                              label: "Mobile Number",
                              hint: "Enter 10 digit mobile number",
                              icon: Icons.phone_rounded,
                            ).copyWith(counterText: ""),
                          ),

                          const SizedBox(height: 18),

                          // ========================================
                          // PASSWORD
                          // ========================================
                          TextFormField(
                            controller: passwordController,

                            obscureText: obscurePassword,

                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,

                            validator: _validatePassword,

                            onChanged: (_) {
                              if (serverError != null) {
                                setState(() {
                                  serverError = null;
                                });
                              }

                              // Refresh confirm password
                              // validation.
                              if (confirmPasswordController.text.isNotEmpty) {
                                _formKey.currentState?.validate();
                              }
                            },

                            decoration: _inputDecoration(
                              label: "Password",
                              hint: "Create a password",
                              icon: Icons.lock_outline_rounded,

                              suffixIcon: IconButton(
                                tooltip: obscurePassword
                                    ? "Show password"
                                    : "Hide password",

                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),

                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ========================================
                          // CONFIRM PASSWORD
                          // ========================================
                          TextFormField(
                            controller: confirmPasswordController,

                            obscureText: obscureConfirmPassword,

                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,

                            validator: _validateConfirmPassword,

                            onChanged: (_) {
                              if (serverError != null) {
                                setState(() {
                                  serverError = null;
                                });
                              }
                            },

                            decoration: _inputDecoration(
                              label: "Confirm Password",
                              hint: "Re-enter your password",
                              icon: Icons.lock_reset_rounded,

                              suffixIcon: IconButton(
                                tooltip: obscureConfirmPassword
                                    ? "Show password"
                                    : "Hide password",

                                icon: Icon(
                                  obscureConfirmPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),

                                onPressed: () {
                                  setState(() {
                                    obscureConfirmPassword =
                                        !obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 26),

                          // ========================================
                          // REGISTER BUTTON
                          // ========================================
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,

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

                          const SizedBox(height: 20),

                          // ========================================
                          // LOGIN
                          // ========================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(color: Color(0xff6B7280)),
                              ),

                              GestureDetector(
                                onTap: loading
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                      },

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

                  const SizedBox(height: 24),

                  const Text(
                    "Your information is securely handled",
                    textAlign: TextAlign.center,

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
