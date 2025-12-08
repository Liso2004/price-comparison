import '../models/product.dart';
import '../models/retailer_price.dart';

class MockDatabase {
  // NOTE: Removed hardcoded mock quick-searches. Replace with API data.
  // TODO: connect API to populate quickSearches
  static List<String> quickSearches = [];

  // ---------------------- UPDATED WITH IMAGES ----------------------
  // NOTE: Removed hardcoded categories. Replace with API data.
  // TODO: connect API to populate categories
  static List<Map<String, String>> categories = [];

  // NOTE: Removed all hardcoded products. Replace with API data.
  // TODO: connect API to populate products
  static List<Product> products = [];

  // TODO: replace with real retailers endpoint
  static List<Map<String, String>> retailers = [];

  static double getMockPrice(String productId) {
    // TODO: connect API to return real prices
    // While API is not connected, return 0.0 to avoid displaying fake data
    return 0.0;
  }

  static Future<List<Product>> searchProducts(
    String query, {
    int delayMs = 600,
    bool fail = false,
  }) async {
    // TODO: connect to backend search API and remove this mock implementation
    await Future.delayed(Duration(milliseconds: delayMs));
    if (fail) throw Exception('Network error (mock)');
    // Current implementation returns no results until API is connected
    return [];
  }

  static Future<List<RetailerPrice>> getComparison(
    String productId, {
    int delayMs = 900,
    bool fail = false,
    bool partial = false,
  }) async {
    // TODO: connect to comparison API
    await Future.delayed(Duration(milliseconds: delayMs));
    if (fail) throw Exception("Network failed to load product comparison");
    // Return empty list until API is connected to avoid showing fake data
    return [];
  }
}
