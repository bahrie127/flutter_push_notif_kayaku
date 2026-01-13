import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/register_response.dart';
import '../models/verify_otp_response.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.18.113:8000/api'; // untuk emulator
  // static const String baseUrl = 'http://192.168.1.100:8000/api'; // untuk device fisik

  // Simpan auth token
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get auth token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Clear auth token (logout)
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Headers dengan auth
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    return jsonDecode(response.body);
  }

  // Simpan FCM Token ke server
  static Future<bool> storeFcmToken(String fcmToken) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/store-token'),
        headers: headers,
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        print('✅ FCM Token berhasil disimpan ke server');
        return true;
      } else {
        print('❌ Gagal simpan FCM Token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error simpan FCM Token: $e');
      return false;
    }
  }

  // Hapus FCM Token dari server (saat logout)
  static Future<bool> removeFcmToken() async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/remove-token'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error hapus FCM Token: $e');
      return false;
    }
  }

  // Logout
  static Future<bool> logout() async {
    try {
      final headers = await _getHeaders();

      // Hapus FCM token dari server dulu
      await removeFcmToken();

      // Logout dari server
      await http.post(Uri.parse('$baseUrl/logout'), headers: headers);

      // Clear local token
      await clearAuthToken();

      return true;
    } catch (e) {
      print('❌ Error logout: $e');
      return false;
    }
  }

  // Register - Step 1: Kirim data registrasi, OTP akan dikirim ke WhatsApp
  static Future<RegisterResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return RegisterResponse.fromJson(data);
    } else if (response.statusCode == 422) {
      // Validation error
      final errors = data['errors'] as Map<String, dynamic>;
      final firstError = errors.values.first[0];
      throw Exception(firstError);
    } else {
      throw Exception(data['message'] ?? 'Registrasi gagal');
    }
  }

  // Verify OTP - Step 2: Verifikasi kode OTP
  static Future<VerifyOtpResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return VerifyOtpResponse.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Verifikasi gagal');
    }
  }

  // Resend OTP - Kirim ulang kode OTP
  static Future<void> resendOtp({required String phone}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/resend-otp'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'phone': phone}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Gagal mengirim ulang OTP');
    }
  }
}
