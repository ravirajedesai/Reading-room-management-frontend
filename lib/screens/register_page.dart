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

  // ==========================================================
  // VARIABLES
  // ==========================================================

  bool loading = false;

  bool obscurePassword = true;

  bool obscureConfirmPassword = true;

  // ==========================================================
  // REGISTER
  // ==========================================================

  Future<void> register() async {
    final name = nameController.text.trim();

    final mobile = mobileController.text.trim();

    final password = passwordController.text;

    final confirmPassword = confirmPasswordController.text;

    // ========================================================
    // VALIDATION - EMPTY FIELDS
    // ========================================================

    if (name.isEmpty ||
        mobile.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));

      return;
    }

    // ========================================================
    // VALIDATION - MOBILE NUMBER
    // ========================================================

    if (mobile.length != 10 || int.tryParse(mobile) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 10 digit mobile number"),
        ),
      );

      return;
    }

    // ========================================================
    // VALIDATION - PASSWORD LENGTH
    // ========================================================

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must contain at least 6 characters"),
        ),
      );

      return;
    }

    // ========================================================
    // VALIDATION - PASSWORD MATCH
    // ========================================================

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password and Confirm Password must be same"),
        ),
      );

      return;
    }

    // ========================================================
    // START LOADING
    // ========================================================

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

      // ======================================================
      // SUCCESS MESSAGE
      // ======================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Registration successful for "
            "${response['name'] ?? name}",
          ),
        ),
      );

      // ======================================================
      // GO BACK TO LOGIN
      // ======================================================

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      // ======================================================
      // ERROR MESSAGE
      // ======================================================

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registration failed: $e")));
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
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
      backgroundColor: const Color(0xffF6F7FB),

      // ======================================================
      // APP BAR
      // ======================================================
      appBar: AppBar(
        title: const Text(
          "Register",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        backgroundColor: Colors.indigo,

        foregroundColor: Colors.white,
      ),

      // ======================================================
      // BODY
      // ======================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            const SizedBox(height: 30),

            // ==================================================
            // ICON
            // ==================================================
            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.indigo.shade50,

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.person_add,
                size: 60,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // TITLE
            // ==================================================
            const Text(
              "Create Account",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // ==================================================
            // SUBTITLE
            // ==================================================
            const Text(
              "Register to reserve your study room seat",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // NAME
            // ==================================================
            TextField(
              controller: nameController,

              textCapitalization: TextCapitalization.words,

              decoration: InputDecoration(
                labelText: "Name",

                hintText: "Enter your name",

                prefixIcon: const Icon(Icons.person),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // MOBILE
            // ==================================================
            TextField(
              controller: mobileController,

              keyboardType: TextInputType.phone,

              maxLength: 10,

              decoration: InputDecoration(
                labelText: "Mobile Number",

                hintText: "Enter 10 digit mobile number",

                prefixIcon: const Icon(Icons.phone),

                counterText: "",

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // PASSWORD
            // ==================================================
            TextField(
              controller: passwordController,

              obscureText: obscurePassword,

              decoration: InputDecoration(
                labelText: "Password",

                hintText: "Enter password",

                prefixIcon: const Icon(Icons.lock),

                // SHOW / HIDE PASSWORD
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? "Show password" : "Hide password",

                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),

                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // CONFIRM PASSWORD
            // ==================================================
            TextField(
              controller: confirmPasswordController,

              obscureText: obscureConfirmPassword,

              decoration: InputDecoration(
                labelText: "Confirm Password",

                hintText: "Re-enter password",

                prefixIcon: const Icon(Icons.lock_outline),

                // SHOW / HIDE CONFIRM PASSWORD
                suffixIcon: IconButton(
                  tooltip: obscureConfirmPassword
                      ? "Show password"
                      : "Hide password",

                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),

                  onPressed: () {
                    setState(() {
                      obscureConfirmPassword = !obscureConfirmPassword;
                    });
                  },
                ),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // REGISTER BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,

              height: 52,

              child: ElevatedButton(
                onPressed: loading ? null : register,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,

                  foregroundColor: Colors.white,

                  disabledBackgroundColor: Colors.grey.shade300,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: loading
                    ? const SizedBox(
                        width: 24,

                        height: 24,

                        child: CircularProgressIndicator(
                          strokeWidth: 2,

                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "REGISTER",
                        style: TextStyle(
                          fontSize: 16,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // LOGIN BUTTON
            // ==================================================
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      Navigator.pop(context);
                    },

              child: const Text("Already have an account? Login"),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
