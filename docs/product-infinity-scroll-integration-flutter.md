# Product Infinity Scroll - Flutter Integration

Dokumentasi integrasi API Products dengan Infinity Scroll di Flutter.

## API Endpoints

### Base URL
```
http://your-domain.com/api
```

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/products` | List products dengan pagination |
| GET | `/products/{id}` | Detail product |
| GET | `/products/categories` | List semua kategori |

### Query Parameters untuk `/products`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | int | 1 | Nomor halaman |
| `per_page` | int | 20 | Jumlah item per halaman (max: 100) |
| `category` | string | - | Filter berdasarkan kategori |
| `min_price` | number | - | Filter harga minimum |
| `max_price` | number | - | Filter harga maksimum |
| `search` | string | - | Pencarian berdasarkan nama |
| `sort_by` | string | id | Field sorting (id, name, price, rating, created_at) |
| `sort_order` | string | asc | Urutan sorting (asc, desc) |

### Response Format

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Premium Smartphone #1",
      "sku": "SKU-00000001",
      "description": "High-quality Premium Smartphone.",
      "price": "35198.26",
      "discount_price": null,
      "image": "https://picsum.photos/seed/1/400/400",
      "category": "Electronics",
      "stock": 643,
      "rating": "4.1",
      "review_count": 2452,
      "is_active": true,
      "created_at": "2025-12-17T11:33:56.000000Z",
      "updated_at": "2025-12-17T11:33:56.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 50000,
    "per_page": 20,
    "total": 1000000,
    "has_more": true
  }
}
```

---

## Flutter Integration

### 1. Tambahkan Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  cached_network_image: ^3.3.0
```

### 2. Model Product

```dart
// lib/models/product.dart
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
```

### 3. Product Response Model

```dart
// lib/models/product_response.dart
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
```

### 4. Product Service

```dart
// lib/services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_response.dart';

class ProductService {
  static const String baseUrl = 'http://your-domain.com/api';

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

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return ProductResponse.fromJson(json.decode(response.body));
    } else {
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
```

### 5. Product Provider (State Management)

```dart
// lib/providers/product_provider.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/product_response.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _selectedCategory;
  String? _searchQuery;
  String _sortBy = 'id';
  String _sortOrder = 'asc';

  // Getters
  List<Product> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;

  // Initialize
  Future<void> init() async {
    await Future.wait([
      loadProducts(),
      loadCategories(),
    ]);
  }

  // Load products (reset)
  Future<void> loadProducts() async {
    _currentPage = 1;
    _products = [];
    _hasMore = true;
    await _fetchProducts();
  }

  // Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;
    _currentPage++;
    await _fetchProducts();
  }

  // Fetch products from API
  Future<void> _fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.getProducts(
        page: _currentPage,
        perPage: 20,
        category: _selectedCategory,
        search: _searchQuery,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      _products.addAll(response.data);
      _hasMore = response.meta.hasMore;
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  // Set category filter
  void setCategory(String? category) {
    _selectedCategory = category;
    loadProducts();
  }

  // Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    loadProducts();
  }

  // Set sorting
  void setSorting(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    loadProducts();
  }

  // Refresh products
  Future<void> refresh() async {
    await loadProducts();
  }
}
```

### 6. Product List Screen dengan Infinity Scroll

```dart
// lib/screens/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().init();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildSearchBar(),
        ),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<ProductProvider>().setSearchQuery(null);
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onSubmitted: (value) {
          context.read<ProductProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: provider.categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChip('All', null, provider);
              }
              final category = provider.categories[index - 1];
              return _buildCategoryChip(category, category, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, String? value, ProductProvider provider) {
    final isSelected = provider.selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setCategory(value),
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      ),
    );
  }

  Widget _buildProductList() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.products.isEmpty && provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.products.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: provider.products.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.products.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return ProductCard(product: provider.products[index]);
            },
          ),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to product detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: product.image ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${product.discountPercentage.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${product.rating} (${product.reviewCount})',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Price
                    if (product.hasDiscount) ...[
                      Text(
                        'Rp ${_formatPrice(product.price)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        'Rp ${_formatPrice(product.discountPrice!)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ] else
                      Text(
                        'Rp ${_formatPrice(product.price)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
```

### 7. Main App Setup

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/product_provider.dart';
import 'screens/product_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        title: 'Product Infinity Scroll',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const ProductListScreen(),
      ),
    );
  }
}
```

---

## Contoh Penggunaan API

### Get Products (Page 1)
```
GET /api/products?page=1&per_page=20
```

### Get Products dengan Filter Category
```
GET /api/products?page=1&per_page=20&category=Electronics
```

### Get Products dengan Search
```
GET /api/products?page=1&per_page=20&search=smartphone
```

### Get Products dengan Sorting
```
GET /api/products?page=1&per_page=20&sort_by=price&sort_order=desc
```

### Get Products dengan Multiple Filters
```
GET /api/products?page=1&per_page=20&category=Electronics&min_price=10000&max_price=50000&sort_by=rating&sort_order=desc
```

---

## Tips Optimasi

1. **Gunakan `per_page` yang wajar** - 20-30 items per request sudah cukup untuk infinity scroll
2. **Cache images** - Gunakan `cached_network_image` untuk caching gambar
3. **Debounce search** - Tambahkan delay saat user mengetik di search field
4. **Preload next page** - Load page berikutnya sebelum user scroll sampai bawah (lihat `maxScrollExtent - 200`)
5. **Show loading indicator** - Tampilkan loading di bawah list saat memuat data baru

## Kategori yang Tersedia

- Electronics
- Fashion
- Home & Garden
- Sports
- Books
- Toys
- Beauty
- Automotive
- Food & Beverages
- Health
