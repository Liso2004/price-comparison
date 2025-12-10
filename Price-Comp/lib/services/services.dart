import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // API Configuration
  static const String baseUrl = 'http://127.0.0.1:8000'; // Change this to your API server URL
  static const String productsEndpoint = '/products';
  static const String categoriesEndpoint = '/categories';
  static const String retailersEndpoint = '/retailers';
  static const String scrapeStatusEndpoint = '/scrape/status';
  static const String scrapeStartEndpoint = '/scrape/start';
  static const String scrapeResultsEndpoint = '/scrape/results';
  static const String debugReseedEndpoint = '/debug/reseed';
  static const String fixMissingRetailersEndpoint = '/debug/fix-missing-retailers';

  // ==========================================
  // PRODUCT ENDPOINTS
  // ==========================================

  /// Get all products from the database
  /// Returns a list of all products
  static Future<List<dynamic>> getAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$productsEndpoint'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching all products: $e');
    }
  }

  /// Search products by query string
  /// [searchQuery] - The search term to filter products
  /// Returns a list of products matching the search query
  static Future<List<dynamic>> searchProducts(String searchQuery) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$productsEndpoint?search=$searchQuery'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  /// Filter products by retailer name
  /// [retailerName] - The name of the retailer to filter by
  /// Returns a list of products from the specified retailer
  static Future<List<dynamic>> filterByRetailer(String retailerName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$productsEndpoint?retailer=$retailerName'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to filter products by retailer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error filtering by retailer: $e');
    }
  }

  /// Search products and filter by retailer
  /// [searchQuery] - The search term to filter products
  /// [retailerName] - The name of the retailer to filter by
  /// Returns a list of products matching both filters
  static Future<List<dynamic>> searchAndFilterByRetailer(
      String searchQuery, String retailerName) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl$productsEndpoint?search=$searchQuery&retailer=$retailerName'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to search and filter products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching and filtering products: $e');
    }
  }

  /// Search products by product name and/or retailer using the dedicated
  /// `/products/search` endpoint in the backend.
  /// [productName] - partial or full product name to search for
  /// [retailerName] - optional retailer filter
  static Future<List<dynamic>> searchProductsByNameAndRetailer(
      {required String productName, String? retailerName, int skip = 0, int limit = 100}) async {
    try {
      final buffer = StringBuffer('$baseUrl/products/search?');
      buffer.write('product=${Uri.encodeQueryComponent(productName)}');
      if (retailerName != null && retailerName.isNotEmpty) {
        buffer.write('&retailer=${Uri.encodeQueryComponent(retailerName)}');
      }
      buffer.write('&skip=$skip&limit=$limit');

      final uri = Uri.parse(buffer.toString());
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching products by name+retailer: $e');
    }
  }

  /// Get all products from a specific category
  /// [categoryName] - The name of the category to filter by
  /// Returns a list of products in the specified category
  static Future<List<dynamic>> getProductsByCategory(
      String categoryName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$productsEndpoint/category/$categoryName'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get products by category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting products by category: $e');
    }
  }

  /// Get all products from a specific retailer
  /// [retailerName] - The name of the retailer
  /// Returns a list of products sorted by price (ascending)
  static Future<List<dynamic>> getProductsByRetailer(
      String retailerName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$productsEndpoint/retailer/$retailerName'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get products by retailer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting products by retailer: $e');
    }
  }

  // ==========================================
  // CATEGORY ENDPOINTS
  // ==========================================

  /// Get all product categories
  /// Returns a list of unique categories from all products
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$categoriesEndpoint'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // ==========================================
  // RETAILER ENDPOINTS
  // ==========================================

  /// Get all retailers
  /// Returns a list of all unique retailers
  static Future<List<dynamic>> getRetailers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$retailersEndpoint'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load retailers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching retailers: $e');
    }
  }

  // ==========================================
  // SCRAPER ENDPOINTS
  // ==========================================

  /// Get the current scraping status and time window
  /// Returns status, message, and current times (UTC and SAST)
  static Future<Map<String, dynamic>> getScrapeStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$scrapeStatusEndpoint'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get scrape status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching scrape status: $e');
    }
  }

  /// Start a new scraping job
  /// Only allowed within the crawl window (06:00-10:45 SAST)
  /// Returns task_id and status
  static Future<Map<String, dynamic>> startScraping() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$scrapeStartEndpoint'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 423) {
        throw Exception('Scraping not allowed: Outside crawl window');
      } else {
        throw Exception('Failed to start scraping: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error starting scraping: $e');
    }
  }

  /// Get the results of a completed scraping job
  /// Returns the count and list of products
  static Future<Map<String, dynamic>> getScrapeResults() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$scrapeResultsEndpoint'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get scrape results: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching scrape results: $e');
    }
  }

  /// Get the status of a specific scraping job
  /// [taskId] - The ID of the task to check
  /// Returns job status, products scraped, start/end times
  static Future<Map<String, dynamic>> getJobStatus(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/scrape/jobs/$taskId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get job status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching job status: $e');
    }
  }

  // ==========================================
  // DEBUG ENDPOINTS
  // ==========================================

  /// Debug: Clear database and reseed from cleaned JSON files
  /// Returns seeded count, total products, and sample document
  static Future<Map<String, dynamic>> debugReseed() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$debugReseedEndpoint'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to reseed database: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error reseeding database: $e');
    }
  }

  /// Debug: Add retailer field to documents missing it
  /// Returns count of fixed documents and updated retailer list
  static Future<Map<String, dynamic>> debugFixMissingRetailers() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$fixMissingRetailersEndpoint'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to fix missing retailers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fixing missing retailers: $e');
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Get the API base URL
  static String getBaseUrl() => baseUrl;

  /// Change the API base URL (useful for switching between environments)
  /// [newUrl] - The new base URL
  static void setBaseUrl(String newUrl) {
    // Note: This would require making baseUrl non-constant
    // For now, you can modify the constant directly
  }
}
