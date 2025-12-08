// lib/models/product.dart
class Product {
  final String id;
  final String name;
  final String size;
  final String category;
  final String image;
  final String? retailerId; // NEW: Track which retailer this product is from
  final String? productUrl; // NEW: Direct URL to product
  Product({
    required this.id,
    required this.name,
    required this.size,
    required this.category,
    this.image = '',
    this.retailerId, // NEW
    this.productUrl, // NEW
  });
  // NEW: Method to create a copy with modified fields
  Product copyWith({
    String? id,
    String? name,
    String? size,
    String? category,
    String? image,
    String? retailerId,
    String? productUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      category: category ?? this.category,
      image: image ?? this.image,
      retailerId: retailerId ?? this.retailerId,
      productUrl: productUrl ?? this.productUrl,
    );
  }
}
