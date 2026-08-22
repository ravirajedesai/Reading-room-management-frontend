import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/library_model.dart';
import 'session_service.dart';
import 'auth_service.dart';

class LibraryService {
  static const String baseUrl = "${AuthService.serverUrl}/api/libraries";

  static Future<List<LibraryModel>> getMyLibraries() async {
    final token = await SessionService.getToken();
    final url = Uri.parse("$baseUrl/my-libraries");

    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LibraryModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load libraries");
    }
  }

  static Future<void> joinLibrary(String libraryCode) async {
    final token = await SessionService.getToken();
    final url = Uri.parse("$baseUrl/join");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"libraryCode": libraryCode}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to join library. Check the code and try again.");
    }
  }

  static Future<void> createLibrary(Map<String, dynamic> libraryData) async {
    final token = await SessionService.getToken();
    final url = Uri.parse(baseUrl);

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(libraryData),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to create library: ${response.body}");
    }
  }

  static Future<List<LibraryModel>> getAllLibrariesForAdmin() async {
    final token = await SessionService.getToken();
    final url = Uri.parse(baseUrl);

    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LibraryModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch all libraries");
    }
  }
  static Future<Map<String, dynamic>> assignOwner(int libraryId, String ownerMobile) async {
    final token = await SessionService.getToken();
    final url = Uri.parse("$baseUrl/$libraryId/assign-owner?ownerMobile=$ownerMobile");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      dynamic errorBody;
      try {
        errorBody = jsonDecode(response.body);
      } catch (_) {}
      String message = (errorBody is Map && errorBody['message'] != null)
          ? errorBody['message']
          : response.body;
      throw Exception(message);
    }
  }
}