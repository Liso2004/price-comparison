// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final double price;
  final VoidCallback onTap;
  final String? retailerId; // Optional retailer ID for backward compatibility
  const ProductCard({
    super.key,
    required this.product,
    required this.price,
    required this.onTap,
    this.retailerId,
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
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Builder(builder: (context) {
                    final img = product.image;
                    if (img.isEmpty) {
                      return const Center(
                        child: Icon(
                          Icons.shopping_bag,
                          size: 40,
                          color: Colors.grey,
                        ),
                      );
                    }

                    // Network image if looks like a URL
                    if (img.startsWith('http')) {
                      return Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.shopping_bag,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    // Otherwise try asset
                    return Image.asset(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.shopping_bag,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 5),
              // 2. RETAILER - Below picture
              Text(
                _getRetailerName(),
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
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: Color(0xFF3D3D3D),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 1),
              // 4. PRICE - Bottom
              Text(
                'R ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
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

  // UPDATED: Now prioritizes product's retailerId field
  String _getRetailerName() {
    // First check if product has retailerId (NEW products with retailer info)
    if (product.retailerId != null) {
      const retailerMap = {
        'r1': 'Pick n Pay',
        'r2': 'Checkers',
        'r3': 'Woolworths',
        'r4': 'Shoprite',
      };
      final val = product.retailerId!;
      // If value is a known short id, map it
      if (retailerMap.containsKey(val)) return retailerMap[val]!;
      // If value already looks like a full retailer name, return it
      if (retailerMap.containsValue(val)) return val;
      // Case-insensitive match to known names
      final lower = val.toLowerCase();
      for (final name in retailerMap.values) {
        if (name.toLowerCase() == lower) return name;
      }
      // Otherwise return the raw value (best-effort)
      return val;
    }
    // Fallback to retailerId parameter (for backward compatibility)
    if (retailerId != null) {
      const retailerMap = {
        'r1': 'Pick n Pay',
        'r2': 'Checkers',
        'r3': 'Woolworths',
        'r4': 'Shoprite',
      };
      final val = retailerId!;
      if (retailerMap.containsKey(val)) return retailerMap[val]!;
      if (retailerMap.containsValue(val)) return val;
      final lower = val.toLowerCase();
      for (final name in retailerMap.values) {
        if (name.toLowerCase() == lower) return name;
      }
      return val;
    }
    // Last fallback: use hash (for old products without retailer info)
    final retailers = ['Checkers', 'Pick n Pay', 'Woolworths', 'Shoprite'];
    final index = product.id.hashCode % retailers.length;
    return retailers[index];
  }
}
