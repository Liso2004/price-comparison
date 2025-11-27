import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_placeholder.dart';
import 'comparison_page.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery;
  const SearchPage({this.initialQuery = ''});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _ctrl;
  List<Product> _results = [];
  bool _loading = false;
  String? _error;
  String _sort = 'none';

  String? _filterCategory;
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
    _ctrl.dispose();
    _quickScrollCtrl.dispose();
    super.dispose();
  }

  /// Performs product search + applies filters
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

      // Apply min/max price filters
      if (_filterMinPrice != null || _filterMaxPrice != null) {
        withPrices = withPrices.where((p) {
          final price = MockDatabase.getMockPrice(p.id);
          final okMin = _filterMinPrice == null || price >= _filterMinPrice!;
          final okMax = _filterMaxPrice == null || price <= _filterMaxPrice!;
          return okMin && okMax;
        }).toList();
      }

      setState(() => _results = withPrices);
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

  /// Opens filter modal bottom sheet
  void _openFilterModal() {
    final minCtrl = TextEditingController(
      text: _filterMinPrice?.toStringAsFixed(2) ?? '',
    );
    final maxCtrl = TextEditingController(
      text: _filterMaxPrice?.toStringAsFixed(2) ?? '',
    );
    String? selCat = _filterCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setModal) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category dropdown
                    DropdownButtonFormField<String?>(
                      value: selCat,
                      hint: const Text('Category (optional)'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Any'),
                        ),
                        ...MockDatabase.categories.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c['name'],
                            child: Text(c['name']!),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModal(() => selCat = v),
                    ),

                    const SizedBox(height: 12),

                    // Min price
                    TextFormField(
                      controller: minCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Min price (R)',
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Max price
                    TextFormField(
                      controller: maxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Max price (R)',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Buttons row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              selCat = null;
                              minCtrl.clear();
                              maxCtrl.clear();
                              setModal(() {});
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filterCategory = selCat;
                                _filterMinPrice = double.tryParse(
                                  minCtrl.text.trim(),
                                );
                                _filterMaxPrice = double.tryParse(
                                  maxCtrl.text.trim(),
                                );
                              });
                              Navigator.pop(ctx);
                              _submitSearch();
                            },
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Quick search chip widget 
  Widget _quickChip(String label) {
    final selected = _selectedQuickSearch == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedQuickSearch = label;
          _ctrl.text = label;
        });
        _submitSearch();
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 96),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2563EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: selected ? const Color(0xFF3D3D3D) : Colors.white,
          ),
        ),
      ),
    );
  }

  /// Round arrow button for scrolling the chip list
  Widget _arrowButton({required IconData icon, required VoidCallback onTap}) {
    // Keep the same spacing but remove the circular background — just show the arrow icon
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(icon, size: 16, color: Colors.grey),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        splashRadius: 20,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Search products...',
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitSearch(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _openFilterModal,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _submitSearch,
            ),
          ],
        ),

        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QUICK SEARCH TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick search',
                    style: Theme.of(context).textTheme.titleMedium,
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

              // SORT SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Sort:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sort == 'none' ? null : _sort,
                    hint: const Text('None'),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text('Price: Low → High'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('Price: High → Low'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _sort = v ?? 'none');
                      _sortResults();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // RESULTS SECTION
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
                    ? const Center(child: Text('No results found'))
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
    );
  }
}
