import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiService {
  static const String baseUrl = baseUrlx; // backend IP

  static Future<bool> signup(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/signup"), // ✅ fixed path
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "email": email, "password": password}),
    );

    print("📤 Signup request: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["success"] == true;
    }
    return false;
  }

  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["success"] == true;
    }
    return false;
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["success"] == true;
    }
    return false;
  }
}
