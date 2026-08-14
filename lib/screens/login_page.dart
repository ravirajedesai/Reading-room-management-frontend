import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_service.dart';
import 'register_page.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController mobileController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool loading = false;

  bool hidePassword = true;

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> login() async {
    final mobile = mobileController.text.trim();

    final password = passwordController.text;

    // ========================================================
    // VALIDATION
    // ========================================================

    if (mobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter mobile number and password"),
        ),
      );

      return;
    }

    if (mobile.length != 10 || int.tryParse(mobile) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 10 digit mobile number"),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // ======================================================
      // API LOGIN
      // ======================================================

      final response = await AuthService.login(
        mobile: mobile,
        password: password,
      );

      if (!mounted) return;

      debugPrint("LOGIN RESPONSE: $response");

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

      debugPrint("USER ID: $userId");

      debugPrint("USER NAME: $name");

      debugPrint("USER MOBILE: $responseMobile");

      // ======================================================
      // CHECK USER ID
      // ======================================================

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Login successful, but User ID was not received from server",
            ),
          ),
        );

        return;
      }

      // ======================================================
      // SAVE LOGIN SESSION
      // ======================================================

      await SessionService.saveLogin(
        userId: userId,
        name: name,
        mobile: responseMobile,
      );

      debugPrint("LOGIN SESSION SAVED");

      // ======================================================
      // GO TO DASHBOARD
      // ======================================================

      if (!mounted) return;

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(
          builder: (context) =>
              DashboardPage(userId: userId, name: name, mobile: responseMobile),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint("LOGIN ERROR: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
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
    mobileController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        title: const Text(
          "Reading Room Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        backgroundColor: Colors.indigo,

        foregroundColor: Colors.white,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // ==================================================
                // ICON
                // ==================================================
                const CircleAvatar(
                  radius: 50,

                  backgroundColor: Colors.indigo,

                  child: Icon(
                    Icons.local_library,
                    size: 55,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // TITLE
                // ==================================================
                const Text(
                  "Reading Room Management",

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Login to manage students and seats",

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // MOBILE
                // ==================================================
                TextField(
                  controller: mobileController,

                  keyboardType: TextInputType.phone,

                  maxLength: 10,

                  decoration: InputDecoration(
                    labelText: "Mobile Number",

                    hintText: "Enter mobile number",

                    prefixIcon: const Icon(Icons.phone),

                    counterText: "",

                    filled: true,

                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // PASSWORD
                // ==================================================
                TextField(
                  controller: passwordController,

                  obscureText: hidePassword,

                  decoration: InputDecoration(
                    labelText: "Password",

                    hintText: "Enter password",

                    prefixIcon: const Icon(Icons.lock),

                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility : Icons.visibility_off,
                      ),

                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
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

                const SizedBox(height: 25),

                // ==================================================
                // LOGIN BUTTON
                // ==================================================
                SizedBox(
                  width: double.infinity,

                  height: 52,

                  child: ElevatedButton(
                    onPressed: loading ? null : login,

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
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "LOGIN",

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                // ==================================================
                // REGISTER
                // ==================================================
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },

                  child: const Text("Don't have an account? Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
