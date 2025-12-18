# Flutter Integration - Registrasi dengan OTP WhatsApp

Dokumentasi integrasi fitur registrasi dengan verifikasi OTP via WhatsApp untuk tim Flutter.

## Overview

Flow registrasi menggunakan 2 step:
1. User submit data registrasi → Backend kirim OTP ke WhatsApp
2. User input OTP → Backend verifikasi → Jika valid, akun dibuat dan user login

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Register Page  │ ──► │  OTP Verify Page │ ──► │    Home Page    │
│                 │     │                 │     │                 │
│ - Nama          │     │ - Input 6 digit │     │ (User logged in)│
│ - Email         │     │ - Resend OTP    │     │                 │
│ - No. WhatsApp  │     │ - Countdown     │     │                 │
│ - Password      │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

## Base URL

```
Production: https://your-domain.com/api
Local: http://localhost:8000/api
```

---

## API Endpoints

### 1. Register (Step 1)

Kirim data registrasi. Jika berhasil, OTP akan dikirim ke WhatsApp user.

**Endpoint:** `POST /api/register`

**Headers:**
```
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@email.com",
  "phone": "6281234567890",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Catatan untuk field `phone`:**
- Gunakan format internasional tanpa tanda `+` (contoh: `6281234567890`)
- Pastikan nomor aktif WhatsApp

**Success Response (200):**
```json
{
  "success": true,
  "message": "Kode OTP telah dikirim ke WhatsApp Anda. Silakan verifikasi.",
  "phone": "6281234567890"
}
```

**Error Response - Validation (422):**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email has already been taken."],
    "phone": ["The phone has already been taken."]
  }
}
```

**Error Response - Failed to Send OTP (500):**
```json
{
  "success": false,
  "message": "Gagal mengirim OTP: [error detail]"
}
```

---

### 2. Verify OTP (Step 2)

Verifikasi kode OTP. Jika berhasil, akun dibuat dan token dikembalikan.

**Endpoint:** `POST /api/verify-otp`

**Headers:**
```
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "phone": "6281234567890",
  "otp": "123456"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Verifikasi berhasil. Registrasi selesai.",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@email.com",
    "phone": "6281234567890"
  },
  "token": "1|abcdef123456..."
}
```

**Error Response - Invalid OTP (400):**
```json
{
  "success": false,
  "message": "Kode OTP tidak valid."
}
```

**Error Response - Expired OTP (400):**
```json
{
  "success": false,
  "message": "Kode OTP sudah kadaluarsa. Silakan minta kode baru."
}
```

**Error Response - Data Not Found (400):**
```json
{
  "success": false,
  "message": "Data registrasi tidak ditemukan. Silakan registrasi ulang."
}
```

---

### 3. Resend OTP

Kirim ulang kode OTP ke WhatsApp.

**Endpoint:** `POST /api/resend-otp`

**Headers:**
```
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "phone": "6281234567890"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Kode OTP baru telah dikirim ke WhatsApp Anda."
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Data registrasi tidak ditemukan. Silakan registrasi ulang."
}
```

---

## Flutter Implementation Guide

### 1. Model Classes

```dart
// lib/models/register_response.dart
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

// lib/models/verify_otp_response.dart
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

// lib/models/user.dart
class User {
  final int id;
  final String name;
  final String email;
  final String phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }
}
```

### 2. API Service

```dart
// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://your-api-url.com/api';

  // Step 1: Register dan kirim OTP
  Future<RegisterResponse> register({
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

  // Step 2: Verify OTP
  Future<VerifyOtpResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return VerifyOtpResponse.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Verifikasi gagal');
    }
  }

  // Resend OTP
  Future<void> resendOtp({required String phone}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/resend-otp'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Gagal mengirim ulang OTP');
    }
  }
}
```

### 3. Register Page Example

```dart
// lib/pages/register_page.dart
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (response.success) {
        // Navigate ke halaman OTP verification
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              phone: response.phone!,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama'),
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Email wajib diisi' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'No. WhatsApp',
                  hintText: '6281234567890',
                  prefixText: '+',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'No. WhatsApp wajib diisi' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Password minimal 6 karakter' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Konfirmasi Password'),
                obscureText: true,
                validator: (v) => v != _passwordController.text
                    ? 'Password tidak sama'
                    : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4. OTP Verification Page Example

```dart
// lib/pages/otp_verification_page.dart
import 'package:flutter/material.dart';
import 'dart:async';

class OtpVerificationPage extends StatefulWidget {
  final String phone;

  OtpVerificationPage({required this.phone});

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masukkan 6 digit kode OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.verifyOtp(
        phone: widget.phone,
        otp: _otp,
      );

      if (response.success && response.token != null) {
        // Simpan token ke local storage
        // await SecureStorage.saveToken(response.token!);

        // Navigate ke Home dan clear stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await _authService.resendOtp(phone: widget.phone);
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode OTP baru telah dikirim')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verifikasi OTP')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Masukkan kode OTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Kode OTP telah dikirim ke WhatsApp\n${widget.phone}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 32),

            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  child: TextFormField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      // Auto submit when all filled
                      if (_otp.length == 6) {
                        _verifyOtp();
                      }
                    },
                  ),
                );
              }),
            ),

            SizedBox(height: 32),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Verifikasi'),
              ),
            ),

            SizedBox(height: 16),

            // Resend OTP
            if (_resendCountdown > 0)
              Text(
                'Kirim ulang kode dalam ${_resendCountdown}s',
                style: TextStyle(color: Colors.grey),
              )
            else
              TextButton(
                onPressed: _resendOtp,
                child: Text('Kirim Ulang Kode OTP'),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Important Notes

### OTP Expiration
- OTP berlaku selama **5 menit**
- Setelah expired, user harus request OTP baru via "Resend OTP"

### Phone Number Format
- Gunakan format internasional tanpa `+`
- Contoh Indonesia: `6281234567890` (bukan `081234567890` atau `+6281234567890`)

### Token Storage
- Setelah verifikasi berhasil, simpan `token` dengan aman (gunakan `flutter_secure_storage`)
- Token digunakan untuk request ke endpoint yang memerlukan autentikasi
- Format header: `Authorization: Bearer {token}`

### Error Handling
- Tampilkan pesan error yang user-friendly
- Jika OTP expired, arahkan user untuk resend
- Jika data registrasi tidak ditemukan (session timeout), arahkan kembali ke halaman register

### UX Recommendations
1. Tampilkan countdown timer untuk resend OTP (60 detik)
2. Auto-focus ke input field berikutnya saat user mengetik digit OTP
3. Auto-submit ketika 6 digit sudah terisi
4. Tampilkan nomor WhatsApp yang dikirimi OTP untuk konfirmasi
5. Berikan opsi untuk kembali ke halaman register jika nomor salah

---

## Testing

### Test Credentials (Development)
Untuk testing, gunakan nomor WhatsApp yang valid dan terdaftar.

### Common Test Cases
1. Register dengan data valid → OTP terkirim
2. Register dengan email/phone yang sudah terdaftar → Error validation
3. Verify dengan OTP yang benar → Registrasi sukses
4. Verify dengan OTP yang salah → Error message
5. Verify setelah OTP expired → Error, perlu resend
6. Resend OTP → OTP baru terkirim, timer reset

---

## Questions?

Hubungi tim Backend jika ada pertanyaan terkait integrasi API.
