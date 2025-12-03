import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_placeholder.dart';
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

  @override
  void initState() {
    super.initState();
    debugPrint('[SearchPage] started');

    _ctrl = TextEditingController(text: widget.initialQuery);
    _ctrl.addListener(() => setState(() {}));

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
    final query = _ctrl.text.trim();
    
    // Don't search if query is empty
    if (query.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _results = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final res = await MockDatabase.searchProducts(query, fail: fail);
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

  void _onProductTap(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComparisonPage(product: p)),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB), // Blue background
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white, // White text
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    
    return SafeArea(
      child: Material(
        child: Column(
          children: [
            // Custom Search Header (not AppBar)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
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
                                _submitSearch(); // This will clear results and show "no results" UI
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

            // Main content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // === QUICK SEARCH SECTION ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Search',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // QUICK SEARCH WITH SCROLL ARROWS
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ListView.separated(
                              controller: _quickScrollCtrl,
                              scrollDirection: Axis.horizontal,
                              itemCount: MockDatabase.quickSearches.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final q = MockDatabase.quickSearches[index];
                                return _quickChip(q);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 48,
                          height: 40,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            splashRadius: 22,
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              const double amount = 120;
                              _quickScrollCtrl.animateTo(
                                _quickScrollCtrl.offset + amount,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        ),
                      ],
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
                          : _ctrl.text.isEmpty || _results.isEmpty
                          ? SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Show the "no results" UI when search is empty OR has no results
                                  const SizedBox(height: 8),

                                  // No results message
                                  Container(
                                    width: double.infinity,
                                    constraints: BoxConstraints(
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
                                      mainAxisSize: MainAxisSize.min,
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
                                            // Clear all search and filters
                                            _ctrl.clear();
                                            setState(() {
                                              _filterCategory = null;
                                              _filterMinPrice = null;
                                              _filterMaxPrice = null;
                                              _sort = 'none';
                                              _results.clear();
                                            });
                                          },
                                          child: const Text(
                                            'Clear Search',
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
                            )
                          : ListView.separated(
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}