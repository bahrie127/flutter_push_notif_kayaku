import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _selectedCategory;
  String? _searchQuery;
  String _sortBy = 'id';
  String _sortOrder = 'asc';
  String? _error;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadProducts(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _products = [];
      _hasMore = true;
    });

    try {
      final response = await _productService.getProducts(
        page: _currentPage,
        perPage: 20,
        category: _selectedCategory,
        search: _searchQuery,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      setState(() {
        _products = response.data;
        _hasMore = response.meta.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final response = await _productService.getProducts(
        page: _currentPage,
        perPage: 20,
        category: _selectedCategory,
        search: _searchQuery,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      setState(() {
        _products.addAll(response.data);
        _hasMore = response.meta.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      setState(() => _categories = categories);
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = value.isEmpty ? null : value);
      _loadProducts();
    });
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _SortBottomSheet(
        currentSortBy: _sortBy,
        currentSortOrder: _sortOrder,
        onSort: (sortBy, sortOrder) {
          setState(() {
            _sortBy = sortBy;
            _sortOrder = sortOrder;
          });
          _loadProducts();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortBottomSheet,
            tooltip: 'Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = null);
                    _loadProducts();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip('Semua', null);
          }
          final category = _categories[index - 1];
          return _buildCategoryChip(category, category);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = value);
          _loadProducts();
        },
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat produk',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada produk ditemukan',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _products.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return ProductListTile(product: _products[index]);
        },
      ),
    );
  }
}

class ProductListTile extends StatelessWidget {
  final Product product;

  const ProductListTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: product.image ?? '',
                  fit: BoxFit.cover,
                  width: 70,
                  height: 70,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
                if (product.stock == 0)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Text(
                        'Habis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        title: Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Category & Rating
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '${product.rating} (${_formatCount(product.reviewCount)})',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Price
            if (product.hasDiscount) ...[
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-${product.discountPercentage.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Rp ${_formatPrice(product.price)}',
                    style: TextStyle(
                      fontSize: 11,
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
                ],
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Stok: ${product.stock}',
              style: TextStyle(
                fontSize: 11,
                color: product.stock > 0 ? Colors.green : Colors.red,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: product,
          );
        },
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

class _SortBottomSheet extends StatelessWidget {
  final String currentSortBy;
  final String currentSortOrder;
  final Function(String sortBy, String sortOrder) onSort;

  const _SortBottomSheet({
    required this.currentSortBy,
    required this.currentSortOrder,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      {'label': 'Terbaru', 'sortBy': 'created_at', 'sortOrder': 'desc'},
      {'label': 'Terlama', 'sortBy': 'created_at', 'sortOrder': 'asc'},
      {'label': 'Nama A-Z', 'sortBy': 'name', 'sortOrder': 'asc'},
      {'label': 'Nama Z-A', 'sortBy': 'name', 'sortOrder': 'desc'},
      {'label': 'Harga Termurah', 'sortBy': 'price', 'sortOrder': 'asc'},
      {'label': 'Harga Termahal', 'sortBy': 'price', 'sortOrder': 'desc'},
      {'label': 'Rating Tertinggi', 'sortBy': 'rating', 'sortOrder': 'desc'},
      {'label': 'Rating Terendah', 'sortBy': 'rating', 'sortOrder': 'asc'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Urutkan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...sortOptions.map((option) {
            final isSelected = currentSortBy == option['sortBy'] &&
                currentSortOrder == option['sortOrder'];
            return ListTile(
              title: Text(option['label']!),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => onSort(option['sortBy']!, option['sortOrder']!),
              tileColor: isSelected ? Colors.blue.shade50 : null,
            );
          }),
        ],
      ),
    );
  }
}
