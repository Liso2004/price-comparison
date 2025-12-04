import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_placeholder.dart';
import '../app/main_scaffold.dart';
import 'comparison_page.dart';
import '../widgets/filter_page.dart';
import '../widgets/recommended_products_horizontal.dart';

// --- Styling Constants ---
const Color _primaryColor = Color(0xFF2563EB);
const Color _darkTextColor = Color(0xFF3D3D3D);
const Color _lightTextColor = Color(0xFFFFFFFF);

class SearchPage extends StatefulWidget {
  final String initialQuery;
  const SearchPage({super.key, this.initialQuery = ''});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _ctrl;
  List<Product> _results = [];
  bool _loading = false;
  String? _error;

  // State variables for Filtering and Sorting
  String _sort = 'none';
  String? _filterCategory;
  // Price range variables are kept but will only be set to null by FilterPage
  double? _filterMinPrice;
  double? _filterMaxPrice;

  String? _selectedQuickSearch;

  /// Controller + state for horizontal quick search scrolling
  final ScrollController _quickScrollCtrl = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = true;

  @override
  void initState() {
    super.initState();
    debugPrint('[SearchPage] started');

    _ctrl = TextEditingController(text: widget.initialQuery);
    _ctrl.addListener(() => setState(() {}));

    // Listen for scroll position changes to show/hide arrow buttons
    _quickScrollCtrl.addListener(() {
      final max = _quickScrollCtrl.position.maxScrollExtent;
      final offset = _quickScrollCtrl.offset;

      setState(() {
        _showLeftArrow = offset > 10;
        _showRightArrow = offset < max - 10;
      });
    });

    // Auto-run search if the page was opened with a pre-filled query
    if (widget.initialQuery.isNotEmpty) _submitSearch();
  }

  @override
  void dispose() {
    debugPrint('[SearchPage] stopped');
    _ctrl.removeListener(() => setState(() {}));
    _ctrl.dispose();
    _quickScrollCtrl.dispose();
    super.dispose();
  }

  // --- Search and Filter Logic ---
  Future<void> _submitSearch({bool fail = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final res = await MockDatabase.searchProducts(_ctrl.text, fail: fail);
      List<Product> withPrices = res;

      // Apply category filter
      if (_filterCategory != null && _filterCategory!.isNotEmpty) {
        withPrices = withPrices
            .where((p) => p.category == _filterCategory)
            .toList();
      }

      // Price Range Filter logic is kept, but since FilterPage always passes null, it's effectively disabled
      if (_filterMinPrice != null || _filterMaxPrice != null) {
        withPrices = withPrices.where((p) {
          final price = MockDatabase.getMockPrice(p.id);
          final okMin = _filterMinPrice == null || price >= _filterMinPrice!;
          final okMax = _filterMaxPrice == null || price <= _filterMaxPrice!;
          return okMin && okMax;
        }).toList();
      }

      setState(() {
        _results = withPrices;
        _sortResults();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onProductTap(Product p, {String? retailerId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComparisonPage(
          product: p,
          initialRetailerId: retailerId,
        ),
      ),
    );
  }

  /// Get retailer ID for a product (matches ProductCard's display logic)
  String _getRetailerIdForProduct(String productId) {
    const retailers = ['r2', 'r1', 'r3', 'r4']; // Checkers, Pick n Pay, Woolworths, Shoprite
    final index = productId.hashCode % retailers.length;
    return retailers[index];
  }

  /// Sorts results based on selected sort type
  void _sortResults() {
    setState(() {
      if (_sort == 'low') {
        _results.sort(
          (a, b) => MockDatabase.getMockPrice(
            a.id,
          ).compareTo(MockDatabase.getMockPrice(b.id)),
        );
      } else if (_sort == 'high') {
        _results.sort(
          (a, b) => MockDatabase.getMockPrice(
            b.id,
          ).compareTo(MockDatabase.getMockPrice(a.id)),
        );
      }
    });
  }

  // --- Filter Page Navigation (UPDATED) ---
  void _openFilterModal() async {
    final results = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => FilterPage(
          initialCategory: _filterCategory,
          // Removed initialMinPrice and initialMaxPrice
          initialSort: _sort,
        ),
        fullscreenDialog: true,
      ),
    );

    if (results != null) {
      setState(() {
        _filterCategory = results['category'];
        _filterMinPrice = results['minPrice'];
        _filterMaxPrice = results['maxPrice'];
        _sort = results['sort'];
      });
      _submitSearch();
    }
  }

  // ----------- Quick Search Methods ----------
  Widget _quickChip(String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _ctrl.text = text;
          _selectedQuickSearch = text;
        });
        _submitSearch();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedQuickSearch == text ? _lightTextColor : _primaryColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: _selectedQuickSearch == text ? _primaryColor : _primaryColor,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: _selectedQuickSearch == text
                ? _primaryColor // Blue text when selected (white background)
                : _lightTextColor,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: _primaryColor),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                Expanded(
                  // Search Text Field container (Input field)
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: TextField(
                              controller: _ctrl,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Groceries',
                                hintStyle: TextStyle(
                                  color: _darkTextColor.withOpacity(0.6),
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                color: _darkTextColor,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _submitSearch(),
                            ),
                          ),
                        ),
                        // Clear Button (x)
                        if (_ctrl.text.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _ctrl.clear();
                              _submitSearch(); //This will clear results and show "no results" UI
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Icon(
                                Icons.close,
                                color: _darkTextColor.withOpacity(0.8),
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Button (Icon: tune)
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _openFilterModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: _lightTextColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Search Action Button (Text: Search)
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(
                        color: _lightTextColor,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === QUICK SEARCH SECTION ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick search',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // QUICK SEARCH WITH SCROLL ARROWS
              SizedBox(
                height: 41,
                child: Stack(
                  children: [
                    // Scrollable chips (leave extra horizontal padding so arrows
                    // sit on the page background and do not overlap chip text)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ListView.separated(
                        controller: _quickScrollCtrl,
                        scrollDirection: Axis.horizontal,
                        itemCount: MockDatabase.quickSearches.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) =>
                            _quickChip(MockDatabase.quickSearches[index]),
                      ),
                    ),

                    // LEFT ARROW
                    if (_showLeftArrow)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _arrowButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () {
                            _quickScrollCtrl.animateTo(
                              (_quickScrollCtrl.offset - 140).clamp(
                                0,
                                _quickScrollCtrl.position.maxScrollExtent,
                              ),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      ),

                    // RIGHT ARROW
                    if (_showRightArrow)
                      Align(
                        alignment: Alignment.centerRight,
                        child: _arrowButton(
                          icon: Icons.arrow_forward_ios,
                          onTap: () {
                            _quickScrollCtrl.animateTo(
                              (_quickScrollCtrl.offset + 140).clamp(
                                0,
                                _quickScrollCtrl.position.maxScrollExtent,
                              ),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // === ADD "SHOWING RESULTS FOR" TEXT HERE ===
              if (_ctrl.text.isNotEmpty && _results.isNotEmpty && !_loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'Showing results for "${_ctrl.text}"',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                ),

              // --- Active Filters Display  ---
              // Only show active filter chips for Category and Sort
              if (_filterCategory != null || _sort != 'none')
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      const Chip(label: Text('Filters/Sort active')),
                      if (_filterCategory != null)
                        Chip(label: Text('Category: ${_filterCategory!}')),
                      // Price range chips removed here
                      if (_sort != 'none')
                        Chip(
                          label: Text(
                            'Sort: ${_sort == 'low' ? 'Low→High' : 'High→Low'}',
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterCategory = null;
                            _filterMinPrice = null; // Clear all
                            _filterMaxPrice = null; // Clear all
                            _sort = 'none';
                          });
                          _submitSearch();
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),

              // --- Results List / Loading / Error ---
              Expanded(
                child: _loading
                    ? ListView.builder(
                        itemCount: 6,
                        itemBuilder: (_, __) => const ProductPlaceholder(),
                      )
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error: $_error'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _submitSearch,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                    ? Expanded(
                        child: SingleChildScrollView(
                          // Add scrolling for safety
                          child: Column(
                            children: [
                              //-- no results test showing message ---
                              if (_ctrl.text.isNotEmpty && !_loading)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 0,
                                      bottom: 12.0,
                                    ),
                                    child: Text(
                                      'Showing results for "${_ctrl.text}"',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: Color(0xFF3D3D3D),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),

                              // No results message
                              Container(
                                width: double.infinity,
                                constraints: BoxConstraints(
                                  // Add constraints instead of fixed height
                                  minHeight: 230,
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.5,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                ),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize
                                      .min, // Important: use min here
                                  children: [
                                    const Text(
                                      'No results found',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                        color: _lightTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      height: 1,
                                      color: _lightTextColor.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 15),
                                    // Remove the Expanded from this inner Column
                                    Column(
                                      children: [
                                        const Text(
                                          'Helpful tips:',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            color: _lightTextColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          '• Be sure to use correct spelling for keywords\n• Try using general keywords',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12,
                                            color: _lightTextColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        side: const BorderSide(
                                          color: _lightTextColor,
                                        ),
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 7,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        // Navigate back to the first route (MainScaffold) and pop the search page
                                        Navigator.popUntil(
                                          context,
                                          (route) => route.isFirst,
                                        );
                                      },
                                      child: const Text(
                                        'Home',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Recommended Products Section
                              const RecommendedProductsHorizontal(),
                            ],
                          ),
                        ),
                      )
                     : Container(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 items per row
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                            childAspectRatio: 0.70, // Adjust this for card proportions
                          ),
                          itemCount: _results.length,
                          itemBuilder: (context, idx) {
                            final p = _results[idx];
                            final price = MockDatabase.getMockPrice(p.id);
                            return ProductCard(
                              product: p,
                              price: price,
                              onTap: () => _onProductTap(p),
                            );
                          },
                        ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
