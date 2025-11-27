import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/retailer_logos.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final double price;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(9),
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PRODUCT IMAGE
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 1),

              // 2. RETAILER LOGO ONLY
              Align(
                alignment: Alignment.centerLeft,
                child: _buildRetailerLogo(_getRetailerName(product.id)),
              ),

              const SizedBox(height: 0),

              // 3. PRODUCT NAME
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: Color(0xFF3D3D3D),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 4),

              // 4. PRICE
              Text(
                'R ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetailerLogo(String retailer) {
    final logo = RetailerLogos.getLogo(retailer);

    if (logo == null) {
      return const Icon(Icons.store, size: 18, color: Colors.grey);
    }

    // Assign custom size for each retailer
    double width;
    double height;
    EdgeInsets margin = EdgeInsets.zero;

    switch (retailer.toLowerCase()) {
      case 'game':
        width = 40;
        height = 40;
        margin = const EdgeInsets.only(bottom: 7); // optional spacing
        break;
      case 'checkers':
        width = 70;
        height = 50;
        margin = const EdgeInsets.only(bottom: 0);
        break;
      case 'pick n pay':
        width = 74;
        height = 50;
        margin = const EdgeInsets.only(bottom: 2);
        break;
      case 'woolworths':
        width = 80;
        height = 52;
        margin = const EdgeInsets.only(bottom: 2);
        break;
      default:
        width = 28;
        height = 28;
    }

    return Container(
      margin: margin,
      child: Image.asset(
        logo,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }

  String _getRetailerName(String productId) {
    final retailers = ['Checkers', 'Pick n Pay', 'Woolworths', 'Game'];
    final index = productId.hashCode % retailers.length;
    return retailers[index];
  }
}
