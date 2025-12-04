import 'package:flutter/material.dart';
import '../models/product.dart';

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
          height: 175,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. PICTURE - Top
              Container(
                width: double.infinity,
                height: 70, // Good size for product image
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.shopping_bag, // Or use Icons.image
                  size: 40,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 5),

              // 2. RETAILER - Below picture
              Text(
                _getRetailerName(product.id),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Inter',
                  color: Color(0xFF3D3D3D),
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // 3. PRODUCT NAME - Below retailer
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600, // Semi-bold
                    height: 1,
                    color: Color(0xFF3D3D3D), // Dark text
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 1),

              // Spacer to push price to bottom
              // const Spacer(),

              // 4. PRICE - Bottom
              Text(
                'R ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600, // Semi-bold
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRetailerName(String productId) {
    final retailers = ['Checkers', 'Pick n Pay', 'Woolworths', 'Game'];
    final index = productId.hashCode % retailers.length;
    return retailers[index];
  }
}