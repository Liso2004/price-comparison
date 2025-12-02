import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/mock_database.dart';
import '../models/product.dart';
import '../models/retailer_price.dart';
import '../widgets/retailer_placeholder.dart';

class ComparisonPage extends StatefulWidget {
  final Product product;
  const ComparisonPage({super.key, required this.product});

  @override
  _ComparisonPageState createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage>
    with SingleTickerProviderStateMixin {
  List<RetailerPrice> _prices = [];
  bool _loading = true;
  String? _error;
  Set<String> selectedRetailers = {'r1', 'r2'};
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    debugPrint('[ComparisonPage] started for ${widget.product.id}');
    _loadComparison();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    debugPrint('[ComparisonPage] stopped for ${widget.product.id}');
    super.dispose();
  }

  Future<void> _loadComparison({
    bool partial = false,
    bool fail = false,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await MockDatabase.getComparison(
        widget.product.id,
        partial: partial,
        fail: fail,
      );
      setState(() => _prices = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
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
    return _prices
        .where((p) => selectedRetailers.contains(p.retailerId))
        .toList();
  }

  // Function to launch retailer website
  Future<void> _launchRetailerWebsite(String retailerId) async {
    final Map<String, String> retailerWebsites = {
      'r1': 'https://www.pnp.co.za',
      'r2': 'https://www.checkers.co.za',
      'r3': 'https://www.woolworths.co.za',
      'r4': 'https://www.shoprite.co.za',
    };

    final website = retailerWebsites[retailerId] ?? 'https://www.google.com';
    final Uri url = Uri.parse(website);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $website';
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
                      onTap: () => _loadComparison(),
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
              _loading ? _buildProductPlaceholder() : _buildProductCard(),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: MockDatabase.retailers.map((r) {
                    final id = r['id']!;
                    final name = r['name']!;
                    final sel = selectedRetailers.contains(id);
                    return FilterChip(
                      label: Text(name),
                      selected: sel,
                      onSelected: (v) => setState(() {
                        if (v) {
                          selectedRetailers.add(id);
                        } else {
                          selectedRetailers.remove(id);
                        }
                      }),
                    );
                  }).toList(),
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
                    : filteredPrices.isEmpty
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
    final hasBestPrice = bestPrice != null;

    // Find the retailer with the best price
    final bestRetailerPrice = _getFilteredPrices().firstWhere(
      (p) => p.price != null && p.price == bestPrice,
      orElse: () => _prices.firstWhere(
        (p) => p.price != null,
        orElse: () => _prices.first,
      ),
    );

    final bestRetailerName = _getRetailerName(bestRetailerPrice.retailerId);
    final bestRetailerId = bestRetailerPrice.retailerId;

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
                    image: const DecorationImage(
                      image: AssetImage('assets/product_image.png'),
                      fit: BoxFit.cover,
                    ),
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
                widget.product.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D3D3D),
                  fontFamily: 'Inter',
                ),
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
                hasBestPrice
                    ? 'R ${bestPrice.toStringAsFixed(2)}'
                    : 'Price not available',
                style: TextStyle(
                  color: hasBestPrice ? const Color(0xFF2563EB) : Colors.grey,
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
                        onTap: hasBestPrice
                            ? () => _launchRetailerWebsite(bestRetailerId)
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
                              color: hasBestPrice
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

        // Lowest Price Badge - Top Right Corner
        if (hasBestPrice)
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
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(8),
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
              'This product is not available at the selected retailers.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetailerCard(RetailerPrice price, bool isBest) {
    // Updated retailer mapping with Shoprite
    final Map<String, Map<String, String>> retailerMapping = {
      'r1': {'logo': 'assets/picknpay.png', 'name': 'Pick n Pay'},
      'r2': {'logo': 'assets/checkers.png', 'name': 'Checkers'},
      'r3': {'logo': 'assets/woolworths.png', 'name': 'Woolworths'},
      'r4': {'logo': 'assets/shoprite.png', 'name': 'Shoprite'},
    };

    // Get retailer info from mapping
    final retailerInfo =
        retailerMapping[price.retailerId] ??
        {'logo': 'assets/shoprite.png', 'name': 'Shoprite'};
    final String logoAsset = retailerInfo['logo']!;
    final String retailerName = retailerInfo['name']!;

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
              image: const DecorationImage(
                image: AssetImage('assets/product_image.png'),
                fit: BoxFit.cover,
              ),
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
                // Product Name
                Text(
                  widget.product.name,
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
                'Lowest',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getRetailerName(String retailerId) {
    switch (retailerId) {
      case 'r1':
        return 'Pick n Pay';
      case 'r2':
        return 'Checkers';
      case 'r3':
        return 'Woolworths';
      case 'r4':
        return 'Shoprite';
      default:
        return 'Shoprite';
    }
  }
}
