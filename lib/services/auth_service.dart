import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'session_service.dart';

class AuthService {
  static const String serverUrl =
      "https://automatic-library-management-git-409107405882.asia-south1.run.app";

  static const String baseUrl = "$serverUrl/users";

  // ==========================================================
  // PRIVATE ERROR HANDLER
  // ==========================================================

  static String _getErrorMessage(
    int statusCode,
    String responseBody, {
    required bool isLogin,
  }) {
    // ----------------------------------------------------------
    // LOGIN AUTHENTICATION ERRORS
    // ----------------------------------------------------------

    if (isLogin) {
      // Do not reveal whether mobile or password is incorrect.
      if (statusCode == 401 || statusCode == 403 || statusCode == 404) {
        return "Invalid mobile number or password";
      }
    }

    // ----------------------------------------------------------
    // REGISTRATION ERRORS
    // ----------------------------------------------------------

    if (!isLogin) {
      if (statusCode == 409) {
        return "Mobile number is already registered";
      }

      if (statusCode == 400) {
        final message = _extractBackendMessage(responseBody);

        if (message != null) {
          return message;
        }

        return "Please check your registration details";
      }
    }

    // ----------------------------------------------------------
    // SERVER ERRORS
    // ----------------------------------------------------------

    if (statusCode >= 500) {
      return "Server error. Please try again later.";
    }

    // ----------------------------------------------------------
    // TRY TO READ BACKEND MESSAGE
    // ----------------------------------------------------------

    final backendMessage = _extractBackendMessage(responseBody);

    if (backendMessage != null) {
      return backendMessage;
    }

    // ----------------------------------------------------------
    // DEFAULT MESSAGE
    // ----------------------------------------------------------

    if (isLogin) {
      return "Unable to login. Please try again.";
    }

    return "Unable to register. Please try again.";
  }

  // ==========================================================
  // EXTRACT MESSAGE FROM JSON RESPONSE
  // ==========================================================

  static String? _extractBackendMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        final possibleMessage =
            decoded['message'] ??
            decoded['error'] ??
            decoded['detail'] ??
            decoded['msg'];

        if (possibleMessage != null) {
          final message = possibleMessage.toString().trim();

          if (message.isNotEmpty) {
            return message;
          }
        }
      }

      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded.trim();
      }
    } catch (_) {
      // Response is not JSON.
    }

    return null;
  }

  // ==========================================================
  // REGISTER
  // ==========================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String mobile,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/register"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              "name": name,
              "mobile": mobile,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        throw Exception("Invalid registration response from server");
      }

      throw Exception(
        _getErrorMessage(response.statusCode, response.body, isLogin: false),
      );
    } on SocketException {
      throw Exception(
        "Unable to connect to server. Please check your internet connection.",
      );
    } on HttpException {
      throw Exception(
        "Unable to communicate with the server. Please try again.",
      );
    } on FormatException {
      throw Exception("Invalid response received from server.");
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception("Something went wrong. Please try again.");
    }
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  static Future<Map<String, dynamic>> login({
    required String mobile,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({"mobile": mobile, "password": password}),
          )
          .timeout(const Duration(seconds: 30));

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN RESPONSE BODY: ${response.body}");

      // ========================================================
      // SUCCESS
      // ========================================================

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw Exception("Invalid login response received from server.");
        }

        final Map<String, dynamic> data = decoded;

        print("LOGIN DATA: $data");

        // ======================================================
        // CHECK ROLE
        // ======================================================

        if (data['role'] == null || data['role'].toString().trim().isEmpty) {
          throw Exception("Login response does not contain user role.");
        }

        // ======================================================
        // CHECK JWT
        // ======================================================

        if (data['token'] == null || data['token'].toString().trim().isEmpty) {
          throw Exception("Login response does not contain JWT token.");
        }

        return data;
      }

      // ========================================================
      // LOGIN FAILURE
      // ========================================================

      throw Exception(
        _getErrorMessage(response.statusCode, response.body, isLogin: true),
      );
    } on SocketException {
      throw Exception(
        "Unable to connect to server. Please check your internet connection.",
      );
    } on HttpException {
      throw Exception(
        "Unable to communicate with the server. Please try again.",
      );
    } on FormatException {
      throw Exception("Invalid response received from server.");
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception("Something went wrong. Please try again.");
    }
  }

  // ==========================================================
  // SAVE FCM TOKEN
  // ==========================================================

  static Future<void> saveFcmToken({
    required int userId,
    required String token,
  }) async {
    print("======================================");
    print("SAVING FCM TOKEN");
    print("USER ID: $userId");
    print("FCM TOKEN: $token");

    final uri = Uri.parse(
      "$baseUrl/$userId/fcm-token",
    ).replace(queryParameters: {"fcmToken": token});

    print("FCM TOKEN URL: $uri");

    try {
            final tokenValue = await SessionService.getToken();
      final headers = {
        'Content-Type': 'application/json',
      };
      if (tokenValue != null) {
        headers['Authorization'] = 'Bearer $tokenValue';
      }
      final response = await http.put(uri, headers: headers).timeout(const Duration(seconds: 30));

      print("FCM TOKEN SAVE STATUS: ${response.statusCode}");
      print("FCM TOKEN SAVE RESPONSE: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to save FCM token: "
          "${response.statusCode} ${response.body}",
        );
      }

      print("FCM TOKEN SAVED SUCCESSFULLY");
    } on SocketException {
      throw Exception("Unable to connect while saving FCM token.");
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception("Unable to save FCM token.");
    }
  }

  // ==========================================================
  // FORGOT PASSWORD - REQUEST OTP
  // ==========================================================

  static Future<Map<String, dynamic>> requestForgotPasswordOtp(String mobile) async {
    final cleanMobile = mobile.trim();
    final uri = Uri.parse("$baseUrl/forgot-password/request-otp").replace(
      queryParameters: {"mobile": cleanMobile},
    );

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 25));

      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body is Map<String, dynamic> ? body : <String, dynamic>{};
      }

      final errorMsg = _extractBackendMessage(response.body) ??
          "Unable to send OTP. Please check mobile number.";
      throw Exception(errorMsg);
    } on SocketException {
      throw Exception("Unable to connect to server. Check internet connection.");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Unable to request OTP. Please try again.");
    }
  }

  // ==========================================================
  // FORGOT PASSWORD - VERIFY OTP & RESET
  // ==========================================================

  static Future<Map<String, dynamic>> verifyOtpAndResetPassword({
    required String mobile,
    required String otp,
    required String newPassword,
  }) async {
    final uri = Uri.parse("$baseUrl/forgot-password/verify-and-reset");

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile.trim(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 25));

      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body is Map<String, dynamic> ? body : <String, dynamic>{};
      }

      final errorMsg = _extractBackendMessage(response.body) ??
          "Failed to reset password. Please check your OTP.";
      throw Exception(errorMsg);
    } on SocketException {
      throw Exception("Unable to connect to server. Check internet connection.");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Failed to reset password. Please try again.");
    }
  }
}
