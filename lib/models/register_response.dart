class RegisterResponse {
  final bool success;
  final String message;
  final String? phone;

  RegisterResponse({
    required this.success,
    required this.message,
    this.phone,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      phone: json['phone'],
    );
  }
}
