class Product {
  final int id;
  final String name;
  final String sku;
  final String? description;
  final double price;
  final double? discountPrice;
  final String? image;
  final String category;
  final int stock;
  final double rating;
  final int reviewCount;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    required this.price,
    this.discountPrice,
    this.image,
    required this.category,
    required this.stock,
    required this.rating,
    required this.reviewCount,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      discountPrice: json['discount_price'] != null
          ? double.parse(json['discount_price'].toString())
          : null,
      image: json['image'],
      category: json['category'],
      stock: json['stock'],
      rating: double.parse(json['rating'].toString()),
      reviewCount: json['review_count'],
      isActive: json['is_active'] ?? true,
    );
  }

  bool get hasDiscount => discountPrice != null;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((price - discountPrice!) / price * 100).roundToDouble();
  }
}
