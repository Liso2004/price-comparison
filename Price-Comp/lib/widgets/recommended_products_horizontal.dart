import 'package:flutter/material.dart';
import '../services/services.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../pages/comparison_page.dart';
import '../models/retailer_price.dart';

class RecommendedProductsHorizontal extends StatefulWidget {
  const RecommendedProductsHorizontal({super.key});
  @override
  State<RecommendedProductsHorizontal> createState() =>
      _RecommendedProductsHorizontalState();
}

class _RecommendedProductsHorizontalState
    extends State<RecommendedProductsHorizontal> {
  List<Product> _recommendedProducts = [];
  Map<String, double> _productPrices = {}; // Store productId -> best price
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _loadRecommendedProducts();
  }

  Future<void> _loadRecommendedProducts() async {
    setState(() => _loading = true);
    try {
      final products = await ApiService.getAllProducts();
      List<Product> loadedProducts = [];
      for (var item in products.take(6)) {
        if (item is Map<String, dynamic>) {
          loadedProducts.add(
            Product(
              id:
                  item['_id']?.toString() ??
                  item['id']?.toString() ??
                  'unknown',
              name: item['productName'] ?? item['name'] ?? 'Unknown Product',
              size: item['size'] ?? 'N/A',
              image: item['productImageURL'] ?? item['image'] ?? '',
              category: item['category'] ?? 'Unknown',
              retailerId: item['retailer'] ?? 'Unknown',
              productUrl: item['productURL'] ?? item['url'],
            ),
          );
        }
      }
      setState(() {
        _recommendedProducts = loadedProducts;
      });
      // Fetch prices for each product in parallel
      await _loadProductPrices();
    } catch (e) {
      debugPrint('Error loading recommended products: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProductPrices() async {
    Map<String, double> prices = {};
    for (var product in _recommendedProducts) {
      try {
        // You can choose a retailer or search across multiple
        final searchResults = await ApiService.searchProductsByNameAndRetailer(
          productName: product.name,
          retailerName: product.retailerId,
        );
        if (searchResults.isNotEmpty) {
          final item = searchResults.first;
          final priceStr = item['price'] ?? item['priceString'] ?? '0';
          final price =
              double.tryParse(
                priceStr.toString().replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              0.0;
          prices[product.id] = price;
        } else {
          prices[product.id] = 0.0;
        }
      } catch (e) {
        prices[product.id] = 0.0;
      }
    }
    if (mounted) {
      setState(() {
        _productPrices = prices;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Text(
            'Recommended Products',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF3D3D3D),
            ),
          ),
        ),
        SizedBox(
          height: 175,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _recommendedProducts.isEmpty
              ? const Center(child: Text('No products available'))
              : Stack(
                  children: [
                    ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _recommendedProducts.length,
                      itemBuilder: (context, index) {
                        final product = _recommendedProducts[index];
                        final price = _productPrices[product.id] ?? 0.0;
                        return Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 12),
                          child: ProductCard(
                            product: product,
                            price: price,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ComparisonPage(
                                    product: product,
                                    initialRetailerId: product.retailerId,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 0,
                      top: 70,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(31, 158, 30, 30),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
