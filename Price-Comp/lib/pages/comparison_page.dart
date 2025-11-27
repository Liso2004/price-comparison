import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../models/product.dart';
import '../models/retailer_price.dart';
import '../widgets/retailer_card.dart';
import '../widgets/retailer_placeholder.dart';

class ComparisonPage extends StatefulWidget {
  final Product product;
  const ComparisonPage({required this.product});

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

  @override
  Widget build(BuildContext context) {
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
                        if (v)
                          selectedRetailers.add(id);
                        else
                          selectedRetailers.remove(id);
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
                    : _prices
                          .where(
                            (p) => selectedRetailers.contains(p.retailerId),
                          )
                          .isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: _prices
                            .where(
                              (p) => selectedRetailers.contains(p.retailerId),
                            )
                            .length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final list = _prices
                              .where(
                                (p) => selectedRetailers.contains(p.retailerId),
                              )
                              .toList();
                          
                          // Sort list so best price is first
                          list.sort((a, b) {
                            if (a.price == null) return 1;
                            if (b.price == null) return -1;
                            return a.price!.compareTo(b.price!);
                          });
                          
                          final item = list[idx];
                          final isBest =
                              item.price != null &&
                              best != null &&
                              (item.price! - best).abs() < 0.001;
                          return RetailerCard(price: item, highlight: isBest);
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, size: 64, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.product.size} • ${widget.product.category}',
                  style: const TextStyle(
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Avg mock price: R ${MockDatabase.getMockPrice(widget.product.id).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Product Placeholder (Loading State with Shimmer)
  Widget _buildProductPlaceholder() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerColor = _getShimmerColor();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 150,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
