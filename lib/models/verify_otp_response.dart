import 'user.dart';

class VerifyOtpResponse {
  final bool success;
  final String message;
  final User? user;
  final String? token;

  VerifyOtpResponse({
    required this.success,
    required this.message,
    this.user,
    this.token,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'],
    );
  }
}
