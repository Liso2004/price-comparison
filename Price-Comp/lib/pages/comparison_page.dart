import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/services.dart';
import '../models/product.dart';
import '../models/retailer_price.dart';
import '../widgets/retailer_placeholder.dart';

// --- NEW CONSTANT KEYWORD LIST ---
// You will need to populate this list with the common, short, and accurate 
// keywords that your backend search index is built around.
const List<String> _PRODUCT_KEYWORDS = [
  'milk', // Example for dairy
  'bread', // Example for bakery
  'eggs', // Example for perishables
  'cola', // Example for soft drinks
  'soup', // Example for canned goods
];
// ---------------------------------

class ComparisonPage extends StatefulWidget {
  final Product product;
  final String? initialRetailerId;
  const ComparisonPage({
    super.key,
    required this.product,
    this.initialRetailerId,
  });

  @override
  _ComparisonPageState createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage>
    with SingleTickerProviderStateMixin {
  List<RetailerPrice> _prices = [];
  // Map of retailer -> product data for that retailer
  final Map<String, Product> _retailerProducts = {};
  bool _loading = true;
  String? _error;
  Set<String> selectedRetailers = {}; // Empty by default - no auto-selection
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    debugPrint('[ComparisonPage] started for ${widget.product.id}');
    // UPDATED: Auto-select the initial retailer if provided
    if (widget.initialRetailerId != null) {
      selectedRetailers.add(widget.initialRetailerId!);
      debugPrint(
        '[ComparisonPage] Auto-selected retailer: ${widget.initialRetailerId}',
      );
    } else {
      // If no retailer specified, select all retailers by default
      selectedRetailers.addAll(
        ['Pick n Pay', 'Checkers', 'Woolworths', 'Shoprite'],
      );
    }
    _loadComparison();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    debugPrint('[ComparisonPage] stopped for ${widget.product.id}');
    super.dispose();
  }
  
  // --- CORE FUNCTIONS ---

  // 1. Initial Load/Refresh function
  Future<void> _loadComparison({
    bool isRefresh = false,
  }) async {
    // Clear old data and set loading state
    setState(() {
      _loading = true;
      _error = null;
      _prices.clear();
      _retailerProducts.clear();

      // Reset retailer selection only if refreshing, otherwise keep the current selection
      if (isRefresh) {
        selectedRetailers.clear();
        if (widget.initialRetailerId != null) {
          selectedRetailers.add(widget.initialRetailerId!);
        } else {
          // If no initial retailer, select all
          selectedRetailers.addAll(
            ['Pick n Pay', 'Checkers', 'Woolworths', 'Shoprite'],
          );
        }
      }
    });

    try {
      final retailers = ['Pick n Pay', 'Checkers', 'Woolworths', 'Shoprite'];

      // Use Future.wait to load all products in parallel
      final futures = retailers.map((retailer) {
        // Pass isInitialLoad: true to prevent multiple setState calls during startup
        return _searchRetailerProduct(retailer, isInitialLoad: true);
      }).toList();

      // Wait for all searches to complete
      await Future.wait(futures);
    } catch (e) {
      setState(() => _error = e.toString());
      debugPrint('Comparison load error: $e');
    } finally {
      // Final setState to ensure UI updates when all loading is complete
      setState(() => _loading = false);
    }
  }

  // 2. UPDATED Search function to use one of the predefined keywords
  Future<void> _searchRetailerProduct(String retailerId, {bool isInitialLoad = false}) async {
    
    // --- UPDATED KEYWORD EXTRACTION LOGIC ---
    String searchName = widget.product.name;
    String? finalSearchTerm;
    
    // 1. Check if the product name contains any of the defined keywords.
    final originalNameLower = searchName.toLowerCase();
    for (var keyword in _PRODUCT_KEYWORDS) {
      if (originalNameLower.contains(keyword)) {
        finalSearchTerm = keyword;
        debugPrint('[Search Debug] Found matching keyword: $finalSearchTerm');
        break; 
      }
    }
    
    // 2. If no keyword is found, fall back to the broad search (first three words)
    if (finalSearchTerm == null) {
      final words = searchName.split(' ');
      if (words.length > 3) {
        finalSearchTerm = words.sublist(0, 3).join(' ');
        debugPrint('[Search Debug] Falling back to broad search: $finalSearchTerm');
      } else {
        finalSearchTerm = searchName;
        debugPrint('[Search Debug] Searching with full name: $finalSearchTerm');
      }
    }
    searchName = finalSearchTerm;
    // ----------------------------------------
    
    debugPrint('[ComparisonPage] Searching for product in retailer: $retailerId (Initial Load: $isInitialLoad)');
    
    try {
      // Use the new determined searchName
      final searchResults = await ApiService.searchProductsByNameAndRetailer(
        productName: searchName,
        retailerName: retailerId,
      );

      final retailerResults = searchResults.where((item) => item is Map<String, dynamic>).toList();
      
      if (retailerResults.isNotEmpty) {
        final item = retailerResults.first;
        final price = _parsePrice(item['price']);
        
        // Prepare the new product objects
        final newRetailerPrice = RetailerPrice(
          retailerId: retailerId,
          retailerName: retailerId,
          price: price,
          productUrl: item['productURL'] ?? item['url'],
        );

        final newProduct = Product(
          id: item['_id']?.toString() ?? item['id']?.toString() ?? 'unknown',
          name: item['productName'] ?? item['name'] ?? 'Unknown Product',
          size: item['size'] ?? 'N/A',
          image: item['productImageURL'] ?? item['image'] ?? '',
          category: item['category'] ?? 'Unknown',
          retailerId: retailerId,
          productUrl: item['productURL'] ?? item['url'],
        );

        // Update state with the found product data
        if (!isInitialLoad) {
          setState(() {
            _prices.removeWhere((p) => p.retailerId == retailerId);
            _prices.add(newRetailerPrice);
            _retailerProducts[retailerId] = newProduct;
          });
          debugPrint('[ComparisonPage] Price loaded (Chip Click): ${newRetailerPrice.retailerName} - R${newRetailerPrice.price}');
        } else {
           // During initial load, just update the data structures
           _prices.removeWhere((p) => p.retailerId == retailerId);
           _prices.add(newRetailerPrice);
           _retailerProducts[retailerId] = newProduct;
           debugPrint('[ComparisonPage] Price loaded (Initial): ${newRetailerPrice.retailerName} - R${newRetailerPrice.price}');
        }
        
      } else {
        debugPrint('[ComparisonPage] No product found for $retailerId');
        // Clear old entry if no product is found for this retailer upon search
        if (!isInitialLoad) {
           setState(() {
             _prices.removeWhere((p) => p.retailerId == retailerId);
             _retailerProducts.remove(retailerId);
           });
           if(mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('No similar product found at $retailerId'),
                 backgroundColor: Colors.orange,
               ),
             );
           }
        }
      }
    } catch (e) {
      debugPrint('[ComparisonPage] Error searching $retailerId: $e');
      if (!isInitialLoad && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching at $retailerId: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 3. Price parsing helper
  double? _parsePrice(dynamic price) {
    if (price == null) return null;
    try {
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) {
        // This handles "R99.99" and similar formats
        final cleaned = price.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.parse(cleaned);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 4. Chip building logic
  List<Widget> _buildRetailerChips() {
    const retailers = [
      {'id': 'Pick n Pay', 'name': 'Pick n Pay'},
      {'id': 'Checkers', 'name': 'Checkers'},
      {'id': 'Woolworths', 'name': 'Woolworths'},
      {'id': 'Shoprite', 'name': 'Shoprite'},
    ];

    return retailers.map((r) {
      final id = r['id']!;
      final name = r['name']!;
      final sel = selectedRetailers.contains(id);
      final isInitialRetailer = id == widget.initialRetailerId;

      return FilterChip(
        label: Text(name),
        selected: sel,
        backgroundColor:
            isInitialRetailer ? const Color(0xFFEFF6FF) : null,
        selectedColor: isInitialRetailer ? const Color(0xFF2563EB) : null,
        onSelected: (v) async {
          setState(() {
            if (v) {
              selectedRetailers.add(id);
            } else {
              selectedRetailers.remove(id);
            }
          });
          
          // Only trigger a new product search if the chip is selected (v == true)
          // AND we don't already have the product data cached for this retailer.
          if (v && !_retailerProducts.containsKey(id)) {
            await _searchRetailerProduct(id);
          }
        },
      );
    }).toList();
  }


  double? getBestPrice() {
    final prices = _prices
        .where(
          (p) => p.price != null && selectedRetailers.contains(p.retailerId),
        )
        .map((p) => p.price!)
        .toList();
    if (prices.isEmpty) return null;
    prices.sort();
    return prices.first;
  }

  List<RetailerPrice> _getFilteredPrices() {
    // If no retailers selected, return empty list to show empty state
    if (selectedRetailers.isEmpty) {
      return [];
    }
    return _prices
        .where((p) => selectedRetailers.contains(p.retailerId))
        .toList();
  }

  // Function to launch retailer website or product page
  Future<void> _launchRetailerWebsite(
    String retailerId, {
    String? productUrl,
  }) async {
    final Map<String, String> retailerWebsites = {
      'Pick n Pay': 'https://www.pnp.co.za',
      'Checkers': 'https://www.checkers.co.za',
      'Woolworths': 'https://www.woolworths.co.za',
      'Shoprite': 'https://www.shoprite.co.za',
    };

    // Use product URL if available, otherwise fall back to retailer website
    final website =
        productUrl ?? retailerWebsites[retailerId] ?? 'https://www.google.com';
    final Uri url = Uri.parse(website);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // For Android, if canLaunchUrl fails, try anyway as a fallback
        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          throw 'Could not launch $website';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $website'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper to get the retailer name (simple lookup since ID and name are the same strings here)
  String _getRetailerName(String retailerId) {
    return retailerId;
  }

  /// Build product image widget with fallback
  Widget _buildProductImage({double size = 120, Product? product}) {
    final productToDisplay = product ?? widget.product;
    final img = productToDisplay.image;
    
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
  }

  @override
  Widget build(BuildContext context) {
    final filteredPrices = _getFilteredPrices();
    final best = getBestPrice();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Compare'),
          leading: BackButton(onPressed: () => Navigator.pop(context)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(6),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => _loadComparison(isRefresh: true),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: const Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Only show product card when loading or when retailers are selected
              if (_loading)
                _buildProductPlaceholder()
              else if (selectedRetailers.isNotEmpty)
                _buildProductCard(),
              if (_loading || selectedRetailers.isNotEmpty)
                const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _loading
                    ? _buildFilterChipsPlaceholder()
                    : Wrap(
                        spacing: 8,
                        children: _buildRetailerChips(),
                      ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? ListView.builder(
                        itemCount: 4,
                        itemBuilder: (_, __) => const RetailerPlaceholder(),
                      )
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Color(0xFF3D3D3D),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: $_error',
                              style: const TextStyle(
                                color: Color(0xFF3D3D3D),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadComparison(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : selectedRetailers.isEmpty || filteredPrices.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: filteredPrices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          // Sort list so best price is first
                          final sortedList = List<RetailerPrice>.from(
                            filteredPrices,
                          );
                          sortedList.sort((a, b) {
                            if (a.price == null) return 1;
                            if (b.price == null) return -1;
                            return a.price!.compareTo(b.price!);
                          });

                          final item = sortedList[idx];
                          final isBest =
                              item.price != null &&
                              best != null &&
                              (item.price! - best).abs() < 0.001;
                          return _buildRetailerCard(item, isBest);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Product Card (Normal State)
  Widget _buildProductCard() {
    final bestPrice = getBestPrice();
    final filteredPrices = _getFilteredPrices();

    // Handle case where filteredPrices might be empty or only contain null prices
    if (filteredPrices.isEmpty) {
        // Fallback to displaying the original product details if no retailer data is available
        return _buildProductPlaceholder(); 
    }

    // Determine which retailer to display
    RetailerPrice displayRetailerPrice;
    
    if (selectedRetailers.length == 1) {
      // Single retailer selected - show that one
      final selectedRetailerId = selectedRetailers.first;
      displayRetailerPrice = filteredPrices.firstWhere(
        (p) => p.retailerId == selectedRetailerId,
        orElse: () => filteredPrices.first,
      );
    } else {
      // Multiple retailers selected - show best price
      // Need a price entry to display a card, so find the lowest priced one available
      displayRetailerPrice = filteredPrices.firstWhere(
        (p) => p.price != null && p.price == bestPrice,
        orElse: () => filteredPrices.firstWhere(
          (p) => selectedRetailers.contains(p.retailerId),
          orElse: () => _prices.isNotEmpty ? _prices.first : RetailerPrice(retailerId: 'N/A', retailerName: 'N/A', price: null, productUrl: null),
        ),
      );
    }

    final bestRetailerName = _getRetailerName(displayRetailerPrice.retailerId);
    final bestRetailerId = displayRetailerPrice.retailerId;
    
    // Get the product from this retailer (or use original if not found)
    final displayProduct = _retailerProducts[bestRetailerId] ?? widget.product;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image at top
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildProductImage(product: displayProduct),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Retailer Name
              Text(
                bestRetailerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D3D3D),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),

              // Product Name
              Text(
                displayProduct.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                  fontFamily: 'Inter',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Product Description
              Text(
                '${widget.product.size} • ${widget.product.category}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),

              // Price
              Text(
                displayRetailerPrice.price != null
                    ? 'R ${displayRetailerPrice.price!.toStringAsFixed(2)}'
                    : 'Price not available',
                style: TextStyle(
                  color: displayRetailerPrice.price != null ? const Color(0xFF2563EB) : Colors.grey,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),

              const SizedBox(height: 16),

              // Proceed to Buy Button - Launches retailer website
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: displayRetailerPrice.price != null
                            ? () => _launchRetailerWebsite(
                                  bestRetailerId,
                                  productUrl: displayRetailerPrice.productUrl ?? '',
                                )
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            'PROCEED TO BUY',
                            style: TextStyle(
                              color: displayRetailerPrice.price != null
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lowest Price Badge - Top Right Corner (only if this retailer has the best price)
        if (displayRetailerPrice.price != null && 
            bestPrice != null && 
            (displayRetailerPrice.price! - bestPrice).abs() < 0.001)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LOWEST',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Product Placeholder (Loading State with Shimmer)
  Widget _buildProductPlaceholder() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerColor = _getShimmerColor();
        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildProductImage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Retailer name placeholder
                  Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Product name placeholder
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description placeholder
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price placeholder
                  Container(
                    height: 28,
                    width: 100,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Button placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 120,
                        height: 36,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Badge placeholder
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Shimmer Color Generator
  Color _getShimmerColor() {
    final value = _shimmerController.value;
    final opacity = (0.3 + (value * 0.2)).clamp(0.0, 1.0);
    return Colors.grey.withOpacity(opacity);
  }

  // Filter Chips Placeholder (Skeleton)
  Widget _buildFilterChipsPlaceholder() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerColor = _getShimmerColor();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            4,
            (index) => Container(
              height: 32,
              width: 80 + (index * 10.0), // Varying widths
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No comparison data available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please select a retailer to view prices and compare.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetailerCard(RetailerPrice price, bool isBest) {
    // Get retailer name - use the stored retailer name directly
    final String retailerName = _getRetailerName(price.retailerId);
    
    // Get the product data for this retailer
    final retailerProduct = _retailerProducts[price.retailerId];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBest ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isBest
            ? Border.all(color: const Color(0xFF2563EB), width: 2)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildProductImage(size: 70, product: retailerProduct),
            ),
          ),
          const SizedBox(width: 12),
          // Retailer and Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Retailer Name
                Text(
                  retailerName,
                  style: const TextStyle(
                    color: Color(0xFF3D3D3D),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Product Name (use retailer-specific product name if available)
                Text(
                  retailerProduct?.name ?? widget.product.name,
                  style: const TextStyle(
                    color: Color(0xFF3D3D3D),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Price
                Text(
                  price.price != null
                      ? 'R${price.price!.toStringAsFixed(2)}'
                      : 'Price not available',
                  style: TextStyle(
                    color: const Color(0xFF2563EB),
                    fontSize: isBest ? 18 : 16,
                    fontFamily: 'Inter',
                    fontWeight: isBest ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Lowest Price Badge
          if (isBest && price.price != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'BEST PRICE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}