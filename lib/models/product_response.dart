import 'product.dart';

class ProductResponse {
  final bool success;
  final List<Product> data;
  final ProductMeta meta;

  ProductResponse({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      success: json['success'],
      data: (json['data'] as List)
          .map((item) => Product.fromJson(item))
          .toList(),
      meta: ProductMeta.fromJson(json['meta']),
    );
  }
}

class ProductMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  ProductMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });

  factory ProductMeta.fromJson(Map<String, dynamic> json) {
    return ProductMeta(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
      hasMore: json['has_more'],
    );
  }
}
