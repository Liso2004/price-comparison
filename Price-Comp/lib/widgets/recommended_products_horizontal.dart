import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../pages/comparison_page.dart';

class RecommendedProductsHorizontal extends StatelessWidget {
  const RecommendedProductsHorizontal({super.key});

  List<Product> _getRecommendedProducts() {
    return MockDatabase.products.take(6).toList();
  }

  /// Get retailer ID for a product (matches ProductCard's display logic)
  String _getRetailerIdForProduct(String productId) {
    const retailers = ['r2', 'r1', 'r3', 'r4']; // Checkers, Pick n Pay, Woolworths, Shoprite
    final index = productId.hashCode % retailers.length;
    return retailers[index];
  }

  @override
  Widget build(BuildContext context) {
    final recommendedProducts = _getRecommendedProducts();

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
          height: 200,
          child: Stack(
            children: [
              // --- Horizontal product list ---
              ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: recommendedProducts.length,
                itemBuilder: (context, index) {
                  final product = recommendedProducts[index];
                  final price = MockDatabase.getMockPrice(product.id);
                  final retailerId = _getRetailerIdForProduct(product.id);

                  return Container(
                    width: 155,
                    margin: const EdgeInsets.only(right: 12),
                    child: ProductCard(
                      product: product,
                      price: price,
                      retailerId: retailerId,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComparisonPage(
                              product: product,
                              initialRetailerId: retailerId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // --- Left scroll arrow (SVG) ---
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
