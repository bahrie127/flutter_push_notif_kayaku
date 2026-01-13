import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/product_response.dart';
import 'api_service.dart';

class ProductService {
  static String get baseUrl => ApiService.baseUrl;

  Future<ProductResponse> getProducts({
    int page = 1,
    int perPage = 20,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? search,
    String sortBy = 'id',
    String sortOrder = 'asc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };

    if (category != null) queryParams['category'] = category;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);

    // ========== DETAILED LOGGER START ==========
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 📤 PRODUCT API REQUEST');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 🌐 Base URL  : $baseUrl');
    debugPrint('║ 🔗 Full URL  : $uri');
    debugPrint('║ 📋 Method    : GET');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 📦 QUERY PARAMETERS:');
    debugPrint('║    • page      : $page');
    debugPrint('║    • per_page  : $perPage');
    debugPrint('║    • category  : ${category ?? "(none)"}');
    debugPrint('║    • search    : ${search ?? "(none)"}');
    debugPrint('║    • sort_by   : $sortBy');
    debugPrint('║    • sort_order: $sortOrder');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ ⏳ Sending request...');
    debugPrint('╚══════════════════════════════════════════════════════════════');

    developer.log(
      '📤 REQUEST: GET $uri',
      name: 'ProductService',
    );

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('');
          debugPrint('╔══════════════════════════════════════════════════════════════');
          debugPrint('║ ⏰ REQUEST TIMEOUT');
          debugPrint('╠══════════════════════════════════════════════════════════════');
          debugPrint('║ ❌ Request timed out after 30 seconds');
          debugPrint('║ 🔍 Possible causes:');
          debugPrint('║    • Server tidak berjalan');
          debugPrint('║    • IP address salah (current: $baseUrl)');
          debugPrint('║    • Device dan server tidak dalam network yang sama');
          debugPrint('║    • Firewall blocking connection');
          debugPrint('╚══════════════════════════════════════════════════════════════');
          throw TimeoutException('Connection timed out');
        },
      );
      stopwatch.stop();

      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════');
      debugPrint('║ 📥 PRODUCT API RESPONSE');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ ⏱️  Response Time : ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('║ 📊 Status Code   : ${response.statusCode}');
      debugPrint('║ 📝 Content-Type  : ${response.headers['content-type'] ?? 'unknown'}');
      debugPrint('║ 📏 Content-Length: ${response.contentLength ?? response.body.length} bytes');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final productResponse = ProductResponse.fromJson(jsonData);

        debugPrint('╠══════════════════════════════════════════════════════════════');
        debugPrint('║ ✅ SUCCESS - Data Received:');
        debugPrint('║    • Total Products : ${productResponse.meta.total}');
        debugPrint('║    • Current Page   : ${productResponse.meta.currentPage}');
        debugPrint('║    • Last Page      : ${productResponse.meta.lastPage}');
        debugPrint('║    • Per Page       : ${productResponse.meta.perPage}');
        debugPrint('║    • Items Loaded   : ${productResponse.data.length}');
        debugPrint('║    • Has More       : ${productResponse.meta.hasMore}');
        debugPrint('╠══════════════════════════════════════════════════════════════');
        if (productResponse.data.isNotEmpty) {
          debugPrint('║ 📦 First 3 Products:');
          for (var i = 0; i < productResponse.data.length && i < 3; i++) {
            final p = productResponse.data[i];
            debugPrint('║    ${i + 1}. ${p.name} (Rp ${p.price})');
          }
        }
        debugPrint('╚══════════════════════════════════════════════════════════════');
        debugPrint('');

        developer.log(
          '📥 RESPONSE: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms) - ${productResponse.data.length} items',
          name: 'ProductService',
        );

        return productResponse;
      } else {
        debugPrint('╠══════════════════════════════════════════════════════════════');
        debugPrint('║ ❌ ERROR - Non-200 Status Code');
        debugPrint('║ 📄 Response Body:');
        debugPrint('║ ${response.body}');
        debugPrint('╚══════════════════════════════════════════════════════════════');
        debugPrint('');

        developer.log(
          '❌ ERROR: ${response.statusCode} - ${response.body}',
          name: 'ProductService',
          error: 'Failed to load products',
        );
        throw Exception('Failed to load products: HTTP ${response.statusCode}');
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════');
      debugPrint('║ 🔌 SOCKET EXCEPTION - Network Error');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ ❌ Error: $e');
      debugPrint('║ 🔍 Possible causes:');
      debugPrint('║    • Server tidak berjalan di $baseUrl');
      debugPrint('║    • IP address tidak benar');
      debugPrint('║    • No internet connection');
      debugPrint('║    • Device tidak dalam WiFi yang sama dengan server');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ 💡 Solutions:');
      debugPrint('║    1. Cek apakah server Laravel berjalan');
      debugPrint('║    2. Jalankan: php artisan serve --host=0.0.0.0 --port=8000');
      debugPrint('║    3. Cek IP server dengan: ipconfig (Windows) / ifconfig (Mac)');
      debugPrint('║    4. Update IP di api_service.dart');
      debugPrint('╚══════════════════════════════════════════════════════════════');
      debugPrint('');

      developer.log(
        '🔌 SOCKET ERROR: $e',
        name: 'ProductService',
        error: e,
      );
      throw Exception('Network error: Unable to connect to server. Check if server is running at $baseUrl');
    } on TimeoutException catch (e) {
      debugPrint('');
      developer.log(
        '⏰ TIMEOUT: $e',
        name: 'ProductService',
        error: e,
      );
      throw Exception('Connection timeout: Server took too long to respond');
    } on FormatException catch (e) {
      stopwatch.stop();
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════');
      debugPrint('║ 📋 FORMAT EXCEPTION - Invalid JSON');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ ❌ Error: $e');
      debugPrint('║ 🔍 Server mungkin mengembalikan HTML bukan JSON');
      debugPrint('║    (misalnya error page atau login redirect)');
      debugPrint('╚══════════════════════════════════════════════════════════════');
      debugPrint('');

      developer.log(
        '📋 FORMAT ERROR: $e',
        name: 'ProductService',
        error: e,
      );
      throw Exception('Invalid response format from server');
    } catch (e) {
      stopwatch.stop();
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════');
      debugPrint('║ ⚠️ UNEXPECTED ERROR');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ ❌ Error Type: ${e.runtimeType}');
      debugPrint('║ ❌ Error     : $e');
      debugPrint('╚══════════════════════════════════════════════════════════════');
      debugPrint('');

      developer.log(
        '⚠️ UNEXPECTED ERROR: $e',
        name: 'ProductService',
        error: e,
      );
      rethrow;
    }
  }

  /// Get single product by ID (for deep link)
  Future<Product> getProductById(int id) async {
    final uri = Uri.parse('$baseUrl/products/$id');

    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 📤 PRODUCT DETAIL API REQUEST');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 🔗 URL: $uri');
    debugPrint('║ 🔍 Product ID: $id');
    debugPrint('╚══════════════════════════════════════════════════════════════');

    final stopwatch = Stopwatch()..start();

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('║ ⏰ Product detail request timed out');
          throw TimeoutException('Product detail request timed out');
        },
      );
      stopwatch.stop();

      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════');
      debugPrint('║ 📥 PRODUCT DETAIL API RESPONSE');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ ⏱️  Response Time: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('║ 📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Handle both {data: {...}} and direct {...} response
        final productJson = jsonData['data'] ?? jsonData;
        final product = Product.fromJson(productJson);

        debugPrint('║ ✅ SUCCESS - Product loaded:');
        debugPrint('║    • ID   : ${product.id}');
        debugPrint('║    • Name : ${product.name}');
        debugPrint('║    • Price: Rp ${product.price}');
        debugPrint('║    • Stock: ${product.stock}');
        debugPrint('╚══════════════════════════════════════════════════════════════');

        return product;
      } else if (response.statusCode == 404) {
        debugPrint('║ ❌ ERROR: Product not found');
        debugPrint('╚══════════════════════════════════════════════════════════════');
        throw Exception('Produk dengan ID $id tidak ditemukan');
      } else {
        debugPrint('║ ❌ ERROR: ${response.body}');
        debugPrint('╚══════════════════════════════════════════════════════════════');
        throw Exception('Gagal memuat produk: HTTP ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════');
      debugPrint('║ 🔌 PRODUCT DETAIL - Network Error');
      debugPrint('║ ❌ $e');
      debugPrint('╚══════════════════════════════════════════════════════════════');
      throw Exception('Network error: Tidak dapat terhubung ke server');
    }
  }

  Future<List<String>> getCategories() async {
    final uri = Uri.parse('$baseUrl/products/categories');

    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 📤 CATEGORIES API REQUEST');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 🔗 URL: $uri');
    debugPrint('╚══════════════════════════════════════════════════════════════');

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('║ ⏰ Categories request timed out');
          throw TimeoutException('Categories request timed out');
        },
      );

      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════');
      debugPrint('║ 📥 CATEGORIES API RESPONSE');
      debugPrint('╠══════════════════════════════════════════════════════════════');
      debugPrint('║ 📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categories = List<String>.from(data['data']);
        debugPrint('║ ✅ SUCCESS - ${categories.length} categories loaded');
        debugPrint('║ 📋 Categories: $categories');
        debugPrint('╚══════════════════════════════════════════════════════════════');
        return categories;
      } else {
        debugPrint('║ ❌ ERROR: ${response.body}');
        debugPrint('╚══════════════════════════════════════════════════════════════');
        throw Exception('Failed to load categories');
      }
    } on SocketException catch (e) {
      debugPrint('');
      debugPrint('╔══════════════════════════════════════════════════════════════');
      debugPrint('║ 🔌 CATEGORIES - Network Error');
      debugPrint('║ ❌ $e');
      debugPrint('╚══════════════════════════════════════════════════════════════');
      throw Exception('Network error loading categories');
    } catch (e) {
      debugPrint('');
      debugPrint('║ ⚠️ CATEGORIES ERROR: $e');
      rethrow;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}
