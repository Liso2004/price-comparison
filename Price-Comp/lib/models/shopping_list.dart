// lib/models/shopping_list.dart

class ShoppingListItem {
  final String id;
  final String productName;
  final int quantity;
  final String? category;
  
  ShoppingListItem({
    required this.id,
    required this.productName,
    required this.quantity,
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productName': productName,
    'quantity': quantity,
    'category': category,
  };

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 1,
      category: json['category'],
    );
  }

  ShoppingListItem copyWith({
    String? id,
    String? productName,
    int? quantity,
    String? category,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
    );
  }
}

class RetailerComparison {
  final String retailerId;
  final String retailerName;
  final List<RetailerProductMatch> products;
  final double totalCost;
  final int matchedItems;
  final int totalItems;
  final double matchPercentage;
  final List<String> unavailableItems;

  RetailerComparison({
    required this.retailerId,
    required this.retailerName,
    required this.products,
    required this.totalCost,
    required this.matchedItems,
    required this.totalItems,
    required this.matchPercentage,
    required this.unavailableItems,
  });
}

class RetailerProductMatch {
  final ShoppingListItem requestedItem;
  final String? productId;
  final String? productName;
  final double? price;
  final String? imageUrl;
  final bool isAvailable;
  final int quantity;

  RetailerProductMatch({
    required this.requestedItem,
    this.productId,
    this.productName,
    this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.quantity,
  });

  double get totalPrice => (price ?? 0.0) * quantity;
}

class BulkComparisonResult {
  final List<RetailerComparison> retailers;
  final RetailerComparison? bestOverall;
  final RetailerComparison? bestPrice;
  final RetailerComparison? bestAvailability;
  final String aiRecommendation;
  final DateTime timestamp;

  BulkComparisonResult({
    required this.retailers,
    this.bestOverall,
    this.bestPrice,
    this.bestAvailability,
    required this.aiRecommendation,
    required this.timestamp,
  });
}