import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://automatic-library-management-git-409107405882.asia-south1.run.app/api/libraries');
  try {
    final response = await http.get(url);
    print('Status: ${response.statusCode}');
  } catch (e) {
    print('Error: $e');
  }
}
