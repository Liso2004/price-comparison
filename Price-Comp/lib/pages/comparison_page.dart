import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../models/product.dart';
import '../models/retailer_price.dart';
import '../widgets/retailer_placeholder.dart';
import 'package:flutter/services.dart';
import 'home_page.dart'; 
import 'search_page.dart'; 



class ComparisonPage extends StatefulWidget {
  final Product product;
  final VoidCallback? onBackToResults;
  
  const ComparisonPage({super.key, 
    required this.product,
    this.onBackToResults,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ComparisonPageState createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  List<RetailerPrice> _prices = [];
  bool _loading = true;
  String? _error;
  Set<String> selectedRetailers = {'r1', 'r2', 'r3'};
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentBottomNavIndex = 2; 

  @override
  void initState() {
    super.initState();
    debugPrint('[ComparisonPage] started for ${widget.product.id}');
    _loadComparison();
    
    // Add scroll listener for performance monitoring
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    debugPrint('[ComparisonPage] stopped for ${widget.product.id}');
    super.dispose();
  }

  void _scrollListener() {
    // Performance monitoring - you can add analytics here
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      debugPrint('[Scroll] Reached bottom of comparison list');
    }
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
      // Simulate network delay for realistic loading
      await Future.delayed(const Duration(milliseconds: 300));
      
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

  Map<String, String> _retailerMap() {
    final map = <String, String>{};
    for (final r in MockDatabase.retailers) {
      map[r['id']!] = r['name']!;
    }
    return map;
  }

  String _retailerName(String id) {
    final map = _retailerMap();
    return map[id] ?? id;
  }

  // CTA Action Handlers
  void _handleBackToResults() {
    HapticFeedback.lightImpact();
    debugPrint('[Navigation] Back to results tapped');
    
    if (widget.onBackToResults != null) {
      widget.onBackToResults!();
    } else {
      Navigator.pop(context);
    }
  }

  void _handleSearch(String query) {
    HapticFeedback.lightImpact();
    debugPrint('[CTA] Search executed: $query');
    
    if (query.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for: $query'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleQuickSearch(String product) {
    HapticFeedback.lightImpact();
    debugPrint('[CTA] Quick search: $product');
    
    _searchController.text = product;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quick search: $product - Loading results...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleRetailerToggle(String retailerId) {
    HapticFeedback.lightImpact();
    debugPrint('[CTA] Retailer toggled: $retailerId');
    
    setState(() {
      if (selectedRetailers.contains(retailerId)) {
        selectedRetailers.remove(retailerId);
      } else {
        selectedRetailers.add(retailerId);
      }
    });
  }

  void _handleProceed() {
    HapticFeedback.mediumImpact();
    debugPrint('[CTA] Proceed to purchase tapped');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to purchase page...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Simulate navigation delay
    Future.delayed(const Duration(milliseconds: 500), () {
      debugPrint('[Navigation] Would navigate to purchase flow');
    });
  }

  void _handleLoadPartial() {
    HapticFeedback.lightImpact();
    debugPrint('[CTA] Load partial data tapped');
    
    _loadComparison(partial: true);
  }


  void _handleBottomNavTap(int index) {
    HapticFeedback.lightImpact();
    
    
    if (index == _currentBottomNavIndex) return;
    
    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0: // Home
        _navigateToHome();
        break;
      case 1: // Search
        _navigateToSearch();
        break;
      case 2: // Compare
        // Already on compare page, just update state
        debugPrint('[Navigation] Already on Compare page');
        break;
      case 3: 
        _navigateToSettings();
        break;
    }
  }

  void _navigateToHome() {
  debugPrint('[Navigation] Navigating to ACTUAL HomePage');
  Navigator.popUntil(context, (route) => route.isFirst);
}

  void _navigateToSearch() {
    debugPrint('[Navigation] Navigating to ACTUAL SearchPage');
    
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SearchPage()),
    );
  }

  void _navigateToSettings() {
    debugPrint('[Navigation] Navigating to Settings');
    
    // Keep placeholder for settings or create actual settings page later
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Settings Page - Placeholder')),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final best = getBestPrice();

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Compare',
            style: TextStyle(
              fontFamily: "Inter",
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF3D3D3D),
            ),
          ),
          leading: InkWell(
            onTap: _handleBackToResults,
            child: Row(
              children: const [
                SizedBox(width: 8),
                Icon(Icons.arrow_back, color: Color(0xFF2563EB)),
                SizedBox(width: 6),
                Text(
                  "Back",
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D3D3D),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Search Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 40,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'LOGO', // Updated to match your mockup
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search for products...',
                              hintStyle: TextStyle(
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF9CA3AF),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            style: const TextStyle(
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF3D3D3D),
                            ),
                            onSubmitted: _handleSearch,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: const Color(0xFFE5E7EB),
                        ),
                        IconButton(
                          onPressed: () => _handleSearch(_searchController.text),
                          icon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick Search Section
                  const Text(
                    'Quick Search',
                    style: TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Quick Search Chips
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      children: [
                        _quickSearchChip('Milk'),
                        const SizedBox(width: 8),
                        _quickSearchChip('Bread'),
                        const SizedBox(width: 8),
                        _quickSearchChip('Juice'),
                        const SizedBox(width: 8),
                        _quickSearchChip('Apples'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Results Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Showing results for ',
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          TextSpan(
                            text: '"${widget.product.name}"',
                            style: const TextStyle(
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF3D3D3D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Product header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name.isNotEmpty ? widget.product.name : 'Unknown Product',
                      style: const TextStyle(
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if ((widget.product.size.isNotEmpty) || (widget.product.category.isNotEmpty))
                      Text(
                        '${widget.product.size}${(widget.product.size.isNotEmpty) && (widget.product.category.isNotEmpty) ? ' • ' : ''}${widget.product.category}'
                            .replaceAll(RegExp(r'(^\s*•\s*)|(\s*•\s*$)'), ''),
                        style: const TextStyle(
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Avg mock price: R ${MockDatabase.getMockPrice(widget.product.id).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),

              // Retailer selection row
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  itemCount: MockDatabase.retailers.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final retailer = MockDatabase.retailers[index];
                    final id = retailer['id']!;
                    final name = retailer['name']!;
                    final selected = selectedRetailers.contains(id);
                    
                    return GestureDetector(
                      onTap: () => _handleRetailerToggle(id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF2563EB) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
                          ),
                        ),
                        child: Text(
                          name,
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: selected ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Price comparison section header
              const Text(
                'Price Comparison',
                style: TextStyle(
                  fontFamily: "Inter",
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF3D3D3D),
                ),
              ),

              const SizedBox(height: 12),

              // Main list area with smooth scrolling
              Expanded(
                child: _loading
                    ? ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        controller: _scrollController,
                        itemCount: 3,
                        itemBuilder: (_, __) => const RetailerPlaceholder(),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Error: $_error',
                                  style: const TextStyle(
                                    fontFamily: "Inter",
                                    color: Color(0xFF3D3D3D),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                  ),
                                  onPressed: _loadComparison,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _prices
                                .where((p) => selectedRetailers.contains(p.retailerId))
                                .isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.info_outline, size: 42, color: Color(0xFF9CA3AF)),
                                    SizedBox(height: 8),
                                    Text(
                                      'No comparison data available',
                                      style: TextStyle(
                                        fontFamily: "Inter",
                                        color: Color(0xFF3D3D3D),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                physics: const ClampingScrollPhysics(),
                                controller: _scrollController,
                                itemCount: _prices
                                    .where((p) => selectedRetailers.contains(p.retailerId))
                                    .length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final list = _prices
                                      .where((p) => selectedRetailers.contains(p.retailerId))
                                      .toList();
                                  final item = list[idx];
                                  final isBest = item.price != null &&
                                      best != null &&
                                      (item.price! - best).abs() < 0.001;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isBest ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB),
                                        width: isBest ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _retailerName(item.retailerId),
                                                style: const TextStyle(
                                                  fontFamily: "Inter",
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Color(0xFF3D3D3D),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                widget.product.name,
                                                style: const TextStyle(
                                                  fontFamily: "Inter",
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF6B7280),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          item.price != null ? 'R ${item.price!.toStringAsFixed(2)}' : '—',
                                          style: TextStyle(
                                            fontFamily: "Inter",
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                            color: isBest ? const Color(0xFF16A34A) : const Color(0xFF111827),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                      onPressed: _handleProceed,
                      child: const Text(
                        'Proceed',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                    onPressed: _handleLoadPartial,
                    child: const Text(
                      'Load Partial',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Fixed Bottom Navigation Bar
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _quickSearchChip(String text) {
    return GestureDetector(
      onTap: () => _handleQuickSearch(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // Fixed Bottom Navigation Bar with proper navigation
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(0, Icons.home_outlined, 'Home'),
          _buildBottomNavItem(1, Icons.search, 'Search'),
          _buildBottomNavItem(2, Icons.compare_arrows, 'Compare'),
          _buildBottomNavItem(3, Icons.settings_outlined, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label) {
    final isActive = _currentBottomNavIndex == index;
    
    return GestureDetector(
      onTap: () => _handleBottomNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: "Inter",
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}