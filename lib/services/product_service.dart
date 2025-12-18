import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
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

    // Log request
    developer.log(
      '📤 REQUEST: GET $uri',
      name: 'ProductService',
    );
    developer.log(
      '   Params: page=$page, perPage=$perPage, category=$category, search=$search, sortBy=$sortBy, sortOrder=$sortOrder',
      name: 'ProductService',
    );

    final stopwatch = Stopwatch()..start();
    final response = await http.get(uri);
    stopwatch.stop();

    if (response.statusCode == 200) {
      final productResponse = ProductResponse.fromJson(json.decode(response.body));

      // Log response
      developer.log(
        '📥 RESPONSE: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)',
        name: 'ProductService',
      );
      developer.log(
        '   Page: ${productResponse.meta.currentPage}/${productResponse.meta.lastPage} | '
        'Items: ${productResponse.data.length} | '
        'Total: ${productResponse.meta.total} | '
        'HasMore: ${productResponse.meta.hasMore}',
        name: 'ProductService',
      );

      return productResponse;
    } else {
      developer.log(
        '❌ ERROR: ${response.statusCode} - ${response.body}',
        name: 'ProductService',
        error: 'Failed to load products',
      );
      throw Exception('Failed to load products');
    }
  }

  Future<List<String>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/products/categories'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['data']);
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
