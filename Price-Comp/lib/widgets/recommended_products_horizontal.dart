import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/mock_database.dart';
import '../models/product.dart';
import 'product_card.dart';
import '../pages/comparison_page.dart';

class RecommendedProductsHorizontal extends StatelessWidget {
  const RecommendedProductsHorizontal({super.key});

  List<Product> _getRecommendedProducts() {
    return MockDatabase.products.take(7).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recommendedProducts = _getRecommendedProducts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 14),
          child: Text(
            'Recommended Products',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: Color(0xFF3D3D3D),
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: recommendedProducts.length,
                itemBuilder: (context, index) {
                  final product = recommendedProducts[index];
                  final price = MockDatabase.getMockPrice(product.id);
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 8),
                    child: ProductCard(
                      product: product,
                      price: price,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComparisonPage(product: product),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              // Right arrow overlay using SVG
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        //Colors.white.withOpacity(0.8),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.only(right: 4),
                  child: SvgPicture.asset(
                    'assets/icons/Arrow - Left 2.svg', // <-- your SVG path
                    width: 16,
                    height: 16,
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
