import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();

  Product? _product;
  bool _isLoading = true;
  String? _error;
  int _quantity = 1;

  // Data dari deep link / notification
  Map<String, dynamic>? _deepLinkData;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Prevent multiple initialization
    if (_initialized) return;
    _initialized = true;

    final settings = ModalRoute.of(context)?.settings;
    final args = settings?.arguments;
    final routeName = settings?.name ?? '';

    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 📱 PRODUCT DETAIL SCREEN');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 📍 Route: $routeName');
    debugPrint('║ 📦 Arguments: $args');
    debugPrint('╚══════════════════════════════════════════════════════════════');

    if (args is Product) {
      // Dari navigation biasa (ProductListScreen)
      setState(() {
        _product = args;
        _isLoading = false;
      });
    } else if (args is Map<String, dynamic>) {
      // Dari push notification
      _deepLinkData = args;
      _loadProductFromDeepLink();
    } else {
      // Dari URL deep link - parse dari route name
      // Format: kayaku://product/123 atau /product/123
      final uri = Uri.parse(routeName);
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'product') {
        final productId = uri.pathSegments[1];
        _deepLinkData = {'product_id': productId, ...uri.queryParameters};
        _loadProductFromDeepLink();
      } else {
        setState(() {
          _error = 'Invalid route atau product ID tidak ditemukan';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProductFromDeepLink() async {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ 🔗 DEEP LINK - Loading Product Detail');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ 📦 Data received: $_deepLinkData');

    final productId = _deepLinkData?['product_id'] ?? _deepLinkData?['id'];

    if (productId == null) {
      debugPrint('║ ❌ ERROR: product_id not found in deep link data');
      debugPrint('╚══════════════════════════════════════════════════════════════');
      setState(() {
        _error = 'Product ID tidak ditemukan';
        _isLoading = false;
      });
      return;
    }

    debugPrint('║ 🔍 Fetching product with ID: $productId');
    debugPrint('╚══════════════════════════════════════════════════════════════');

    try {
      final product = await _productService.getProductById(int.parse(productId.toString()));
      setState(() {
        _product = product;
        _isLoading = false;
      });
      debugPrint('✅ Product loaded: ${product.name}');
    } catch (e) {
      debugPrint('❌ Error loading product: $e');
      setState(() {
        _error = 'Gagal memuat produk: $e';
        _isLoading = false;
      });
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _buildBody(),
      bottomNavigationBar: _product != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat produk...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
              ),
              if (_deepLinkData != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Debug - Deep Link Data:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _deepLinkData.toString(),
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_product == null) {
      return const Center(child: Text('Produk tidak ditemukan'));
    }

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductInfo(),
              const SizedBox(height: 8),
              _buildPriceSection(),
              const SizedBox(height: 8),
              _buildStockInfo(),
              const SizedBox(height: 8),
              _buildDescription(),
              const SizedBox(height: 8),
              _buildDeepLinkInfo(),
              const SizedBox(height: 100), // Space for bottom bar
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Product Image
            _product!.image != null
                ? CachedNetworkImage(
                    imageUrl: _product!.image!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 64),
                  ),
            // Discount Badge
            if (_product!.hasDiscount)
              Positioned(
                top: 100,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '-${_product!.discountPercentage.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            // Out of stock overlay
            if (_product!.stock == 0)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Text(
                    'STOK HABIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Share: https://kayaku.com/product/${_product!.id}'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _product!.category,
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Product name
          Text(
            _product!.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // SKU
          Text(
            'SKU: ${_product!.sku}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          // Rating
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < _product!.rating.floor()
                      ? Icons.star
                      : index < _product!.rating
                          ? Icons.star_half
                          : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                '${_product!.rating}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${_product!.reviewCount} ulasan)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Harga',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (_product!.hasDiscount) ...[
            Text(
              'Rp ${_formatPrice(_product!.price)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rp ${_formatPrice(_product!.discountPrice!)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Hemat Rp ${_formatPrice(_product!.price - _product!.discountPrice!)}',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else
            Text(
              'Rp ${_formatPrice(_product!.price)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockInfo() {
    final inStock = _product!.stock > 0;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            inStock ? Icons.check_circle : Icons.cancel,
            color: inStock ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            inStock ? 'Stok tersedia: ${_product!.stock}' : 'Stok habis',
            style: TextStyle(
              color: inStock ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (inStock && _product!.stock <= 10) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sisa sedikit!',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi Produk',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _product!.description ?? 'Tidak ada deskripsi',
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeepLinkInfo() {
    if (_deepLinkData == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Dibuka dari Deep Link',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data yang diterima:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ..._deepLinkData!.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${e.key}:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final inStock = _product!.stock > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: inStock && _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    iconSize: 20,
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: inStock && _quantity < _product!.stock
                        ? () => setState(() => _quantity++)
                        : null,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add to cart button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: inStock
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$_quantity x ${_product!.name} ditambahkan ke keranjang',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(
                  inStock ? 'Tambah ke Keranjang' : 'Stok Habis',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
