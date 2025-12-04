import 'package:flutter/material.dart';
import '../data/mock_database.dart'; 
import '../models/product.dart'; 
import '../widgets/product_card.dart'; 
import '../widgets/product_placeholder.dart'; 
import 'comparison_page.dart'; 
import '../widgets/filter_page.dart'; // Import the new FilterPage

// --- Styling Constants ---
const Color _primaryColor = Color(0xFF2563EB); 
const Color _darkTextColor = Color(0xFF3D3D3D); 
const Color _lightTextColor = Color(0xFFFFFFFF); 

class SearchPage extends StatefulWidget {
  final String initialQuery;
  const SearchPage({super.key, this.initialQuery = ''});

  @override
  State<SearchPage> createState() => _SearchPageState();
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

  final ScrollController _quickScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint('[SearchPage] started');

    _ctrl = TextEditingController(text: widget.initialQuery);
    _ctrl.addListener(() => setState(() {})); 

    // (Quick search arrows removed) keep controller for potential future use

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
                          color: Colors.grey.withAlpha((0.1 * 255).round()),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ]
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
                                  color: _darkTextColor.withAlpha((0.6 * 255).round()),
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
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(
                                Icons.close,
                                color: _darkTextColor.withAlpha((0.8 * 255).round()),
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
              const SizedBox(height: 8),
              // --- Active Filters Display (UPDATED) ---
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
                        itemBuilder: (context, index) => const ProductPlaceholder(),
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
                    ? const Center(child: Text('No results found'))
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
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
    );
  }
}