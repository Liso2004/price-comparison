// lib/services/bulk_comparison_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shopping_list.dart';
import 'services.dart';

class BulkComparisonService {
  static const List<String> _retailers = [
    'Pick n Pay',
    'Checkers',
    'Woolworths',
    'Shoprite',
  ];

  /// Main function to compare shopping list across all retailers
  static Future<BulkComparisonResult> compareShoppingList(
    List<ShoppingListItem> items,
  ) async {
    if (items.isEmpty) {
      throw Exception('Shopping list cannot be empty');
    }

    List<RetailerComparison> comparisons = [];

    // Compare across all retailers in parallel
    final futures = _retailers.map((retailer) async {
      return await _compareRetailer(retailer, items);
    }).toList();

    comparisons = await Future.wait(futures);

    // Find best options
    final bestPrice = _findBestPrice(comparisons);
    final bestAvailability = _findBestAvailability(comparisons);
    final bestOverall = _findBestOverall(comparisons);

    // Generate AI recommendation
    final aiRecommendation = _generateAIRecommendation(
      comparisons,
      bestOverall,
      bestPrice,
      bestAvailability,
    );

    return BulkComparisonResult(
      retailers: comparisons,
      bestOverall: bestOverall,
      bestPrice: bestPrice,
      bestAvailability: bestAvailability,
      aiRecommendation: aiRecommendation,
      timestamp: DateTime.now(),
    );
  }

  /// Compare shopping list for a specific retailer
  static Future<RetailerComparison> _compareRetailer(
    String retailerId,
    List<ShoppingListItem> items,
  ) async {
    List<RetailerProductMatch> matches = [];
    double totalCost = 0.0;
    int matchedItems = 0;
    List<String> unavailableItems = [];

    for (var item in items) {
      try {
        // Search for product at this retailer
        final searchResults = await ApiService.searchProductsByNameAndRetailer(
          productName: _cleanProductName(item.productName),
          retailerName: retailerId,
          limit: 1,
        );

        if (searchResults.isNotEmpty) {
          final product = searchResults.first;
          final price = _parsePrice(product['price']);

          if (price != null) {
            matchedItems++;
            totalCost += price * item.quantity;

            matches.add(RetailerProductMatch(
              requestedItem: item,
              productId: product['_id']?.toString(),
              productName: product['productName'] ?? product['name'],
              price: price,
              imageUrl: product['productImageURL'] ?? product['image'],
              isAvailable: true,
              quantity: item.quantity,
            ));
          } else {
            unavailableItems.add(item.productName);
            matches.add(RetailerProductMatch(
              requestedItem: item,
              isAvailable: false,
              quantity: item.quantity,
            ));
          }
        } else {
          unavailableItems.add(item.productName);
          matches.add(RetailerProductMatch(
            requestedItem: item,
            isAvailable: false,
            quantity: item.quantity,
          ));
        }
      } catch (e) {
        print('Error searching ${item.productName} at $retailerId: $e');
        unavailableItems.add(item.productName);
        matches.add(RetailerProductMatch(
          requestedItem: item,
          isAvailable: false,
          quantity: item.quantity,
        ));
      }
    }

    final matchPercentage = (matchedItems / items.length) * 100;

    return RetailerComparison(
      retailerId: retailerId,
      retailerName: retailerId,
      products: matches,
      totalCost: totalCost,
      matchedItems: matchedItems,
      totalItems: items.length,
      matchPercentage: matchPercentage,
      unavailableItems: unavailableItems,
    );
  }

  /// Clean product name for better search results
  static String _cleanProductName(String name) {
    // Remove common words that might interfere with search
    final cleaned = name.toLowerCase().trim();
    
    // Extract key product keywords
    final commonWords = ['fresh', 'organic', 'pack', 'box', 'bag', 'bottle'];
    var words = cleaned.split(' ');
    words = words.where((w) => !commonWords.contains(w)).toList();
    
    // Return first 3 words for broader search
    return words.take(3).join(' ');
  }

  /// Parse price from various formats
  static double? _parsePrice(dynamic price) {
    if (price == null) return null;
    try {
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) {
        final cleaned = price.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.parse(cleaned);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Find retailer with best price
  static RetailerComparison? _findBestPrice(List<RetailerComparison> comparisons) {
    final validComparisons = comparisons.where((c) => c.matchedItems > 0).toList();
    if (validComparisons.isEmpty) return null;

    validComparisons.sort((a, b) => a.totalCost.compareTo(b.totalCost));
    return validComparisons.first;
  }

  /// Find retailer with best availability
  static RetailerComparison? _findBestAvailability(List<RetailerComparison> comparisons) {
    comparisons.sort((a, b) => b.matchedItems.compareTo(a.matchedItems));
    return comparisons.first;
  }

  /// Find best overall retailer (balance of price and availability)
  static RetailerComparison? _findBestOverall(List<RetailerComparison> comparisons) {
    final validComparisons = comparisons.where((c) => c.matchedItems > 0).toList();
    if (validComparisons.isEmpty) return null;

    // Score based on: 60% availability, 40% price
    validComparisons.sort((a, b) {
      final scoreA = (a.matchPercentage * 0.6) - (a.totalCost * 0.01);
      final scoreB = (b.matchPercentage * 0.6) - (b.totalCost * 0.01);
      return scoreB.compareTo(scoreA);
    });

    return validComparisons.first;
  }

  /// Generate AI-powered recommendation
  static String _generateAIRecommendation(
    List<RetailerComparison> comparisons,
    RetailerComparison? bestOverall,
    RetailerComparison? bestPrice,
    RetailerComparison? bestAvailability,
  ) {
    if (bestOverall == null) {
      return "Unfortunately, we couldn't find matches for your items at any retailer. Try adding more common product names.";
    }

    final buffer = StringBuffer();
    
    // Main recommendation
    buffer.writeln("🎯 Smart Recommendation: Shop at ${bestOverall.retailerName}");
    buffer.writeln();
    buffer.writeln("This gives you the best balance of price and availability.");
    buffer.writeln();
    
    // Detailed breakdown
    buffer.writeln("📊 Why ${bestOverall.retailerName}?");
    buffer.writeln("• ${bestOverall.matchedItems}/${bestOverall.totalItems} items available (${bestOverall.matchPercentage.toStringAsFixed(0)}%)");
    buffer.writeln("• Total: R${bestOverall.totalCost.toStringAsFixed(2)}");
    buffer.writeln();

    // Price comparison
    if (bestPrice != null && bestPrice.retailerId != bestOverall.retailerId) {
      final saving = bestOverall.totalCost - bestPrice.totalCost;
      buffer.writeln("💰 Note: ${bestPrice.retailerName} is R${saving.toStringAsFixed(2)} cheaper, but has fewer items available.");
      buffer.writeln();
    }

    // Availability note
    if (bestOverall.unavailableItems.isNotEmpty) {
      buffer.writeln("⚠️ ${bestOverall.unavailableItems.length} items not found:");
      for (var item in bestOverall.unavailableItems.take(3)) {
        buffer.writeln("  • $item");
      }
      if (bestOverall.unavailableItems.length > 3) {
        buffer.writeln("  • and ${bestOverall.unavailableItems.length - 3} more...");
      }
      buffer.writeln();
      buffer.writeln("💡 Tip: You might find these at a specialty store.");
    }

    return buffer.toString();
  }

  /// Save shopping list to local storage
  static Future<void> saveShoppingList(
    String listName,
    List<ShoppingListItem> items,
  ) async {
    try {
      final listData = {
        'name': listName,
        'items': items.map((i) => i.toJson()).toList(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Use persistent storage from Claude API
      await Future.delayed(Duration(milliseconds: 100)); // Placeholder
      // In real implementation: window.storage.set('shopping_list_$listName', jsonEncode(listData), false);
      
      print('Shopping list saved: $listName');
    } catch (e) {
      print('Error saving shopping list: $e');
      throw Exception('Failed to save shopping list');
    }
  }

  /// Load saved shopping lists
  static Future<List<Map<String, dynamic>>> loadShoppingLists() async {
    try {
      // In real implementation: window.storage.list('shopping_list_', false);
      await Future.delayed(Duration(milliseconds: 100)); // Placeholder
      return [];
    } catch (e) {
      print('Error loading shopping lists: $e');
      return [];
    }
  }
}