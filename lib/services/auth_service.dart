import 'api_service.dart';
import 'fcm_service.dart';
import '../models/register_response.dart';
import '../models/verify_otp_response.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get currentUser => _currentUser;

  // Login + Simpan FCM Token
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // 1. Login ke server
      final response = await ApiService.login(email, password);

      if (response['success'] == true || response['token'] != null) {
        // 2. Simpan auth token
        await ApiService.saveAuthToken(response['token']);
        
        _isLoggedIn = true;
        _currentUser = response['user'];

        // 3. Kirim FCM Token ke server
        await _sendFcmTokenToServer();

        return {'success': true, 'user': response['user']};
      } else {
        return {'success': false, 'message': response['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Kirim FCM Token ke server
  Future<void> _sendFcmTokenToServer() async {
    final fcmToken = await FcmService().getToken();
    if (fcmToken != null) {
      await ApiService.storeFcmToken(fcmToken);
    }
  }

  // Refresh FCM Token (dipanggil saat token refresh)
  Future<void> refreshFcmToken(String newToken) async {
    if (_isLoggedIn) {
      await ApiService.storeFcmToken(newToken);
    }
  }

  // Logout + Hapus FCM Token
  Future<void> logout() async {
    await ApiService.logout();
    _isLoggedIn = false;
    _currentUser = null;
  }

  // Check login status saat app start
  Future<bool> checkLoginStatus() async {
    final token = await ApiService.getAuthToken();
    _isLoggedIn = token != null;

    // Jika sudah login, pastikan FCM token terupdate
    if (_isLoggedIn) {
      await _sendFcmTokenToServer();
    }

    return _isLoggedIn;
  }

  // Register - Step 1: Kirim data registrasi, OTP dikirim ke WhatsApp
  Future<RegisterResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await ApiService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  // Verify OTP - Step 2: Verifikasi OTP, simpan token, dan login
  Future<VerifyOtpResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await ApiService.verifyOtp(phone: phone, otp: otp);

    if (response.success && response.token != null) {
      // Simpan token ke local storage
      await ApiService.saveAuthToken(response.token!);

      // Set login state
      _isLoggedIn = true;
      _currentUser = response.user?.toJson();

      // Kirim FCM token ke server
      await _sendFcmTokenToServer();
    }

    return response;
  }

  // Resend OTP
  Future<void> resendOtp({required String phone}) async {
    await ApiService.resendOtp(phone: phone);
  }
}