// lib/pages/bulk_results_page.dart

import 'package:flutter/material.dart';
import '../models/shopping_list.dart';

class BulkResultsPage extends StatefulWidget {
  final BulkComparisonResult result;
  final List<ShoppingListItem> items;

  const BulkResultsPage({
    super.key,
    required this.result,
    required this.items,
  });

  @override
  State<BulkResultsPage> createState() => _BulkResultsPageState();
}

class _BulkResultsPageState extends State<BulkResultsPage> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('[BulkResultsPage] started');
  }

  @override
  void dispose() {
    debugPrint('[BulkResultsPage] stopped');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bestOverall = widget.result.bestOverall;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparison Results'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // AI Recommendation Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AI Recommendation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.result.aiRecommendation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),

          // Tab Navigation
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab('Overview', 0),
                ),
                Expanded(
                  child: _buildTab('Details', 1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildOverviewTab()
                : _buildDetailsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Retailer Comparison Cards
        ...widget.result.retailers.map((retailer) {
          final isBest = retailer.retailerId == widget.result.bestOverall?.retailerId;
          return _buildRetailerCard(retailer, isBest);
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRetailerCard(RetailerComparison retailer, bool isBest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isBest
            ? Border.all(color: const Color(0xFF2563EB), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isBest
                  ? const Color(0xFF2563EB).withOpacity(0.1)
                  : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isBest
                      ? const Color(0xFF2563EB)
                      : Colors.grey[300],
                  child: Text(
                    retailer.retailerName[0],
                    style: TextStyle(
                      color: isBest ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            retailer.retailerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                              color: Color(0xFF3D3D3D),
                            ),
                          ),
                          if (isBest) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BEST',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${retailer.matchedItems}/${retailer.totalItems} items (${retailer.matchPercentage.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  'Total Cost',
                  'R${retailer.totalCost.toStringAsFixed(2)}',
                  Icons.payments,
                  const Color(0xFF2563EB),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStat(
                  'Available',
                  '${retailer.matchedItems}',
                  Icons.check_circle,
                  Colors.green,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStat(
                  'Missing',
                  '${retailer.unavailableItems.length}',
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.result.retailers.length,
      itemBuilder: (context, index) {
        final retailer = widget.result.retailers[index];
        return ExpansionTile(
          title: Text(
            retailer.retailerName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          subtitle: Text(
            'R${retailer.totalCost.toStringAsFixed(2)} • ${retailer.matchedItems} items',
            style: const TextStyle(fontFamily: 'Inter'),
          ),
          children: [
            ...retailer.products.map((product) {
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: product.isAvailable
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    product.isAvailable ? Icons.check : Icons.close,
                    color: product.isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  product.requestedItem.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
                subtitle: product.isAvailable
                    ? Text(
                        '${product.quantity}x • R${product.price?.toStringAsFixed(2) ?? "0.00"} each',
                        style: const TextStyle(fontFamily: 'Inter'),
                      )
                    : const Text(
                        'Not available',
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Inter',
                        ),
                      ),
                trailing: product.isAvailable
                    ? Text(
                        'R${product.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2563EB),
                          fontFamily: 'Inter',
                        ),
                      )
                    : null,
              );
            }).toList(),
          ],
        );
      },
    );
  }
}