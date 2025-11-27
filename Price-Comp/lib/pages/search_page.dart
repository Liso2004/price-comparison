import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_placeholder.dart';
import 'comparison_page.dart';
import '../widgets/recommended_products_horizontal.dart';
import 'home_page.dart';


class SearchPage extends StatefulWidget {
  final String initialQuery;
  const SearchPage({super.key, this.initialQuery = ''});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _ctrl;
  late FocusNode _searchFocusNode;
  List<Product> _results = [];
  bool _loading = false;
  String? _error;
  String _sort = 'none';

  String? _filterCategory;
  double? _filterMinPrice;
  double? _filterMaxPrice;

  @override
  void initState() {
    super.initState();
    debugPrint('[SearchPage] started');
    _ctrl = TextEditingController(text: widget.initialQuery);
    _searchFocusNode = FocusNode();
    if (widget.initialQuery.isNotEmpty) _submitSearch();
  }

  @override
  void dispose() {
    debugPrint('[SearchPage] stopped');
    _ctrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitSearch({bool fail = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });
    try {
      final res = await MockDatabase.searchProducts(_ctrl.text, fail: fail);
      List<Product> withPrices = res;
      if (_filterCategory != null && _filterCategory!.isNotEmpty) {
        withPrices = withPrices
            .where((p) => p.category == _filterCategory)
            .toList();
      }
      if (_filterMinPrice != null || _filterMaxPrice != null) {
        withPrices = withPrices.where((p) {
          final price = MockDatabase.getMockPrice(p.id);
          final minOk = _filterMinPrice == null
              ? true
              : price >= _filterMinPrice!;
          final maxOk = _filterMaxPrice == null
              ? true
              : price <= _filterMaxPrice!;
          return minOk && maxOk;
        }).toList();
      }
      setState(() {
        _results = withPrices;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
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

  void _focusOnSearch() {
    // Clear the search and focus on the search field
    setState(() {
      _ctrl.clear();
      _results = [];
      _filterCategory = null;
      _filterMinPrice = null;
      _filterMaxPrice = null;
      _sort = 'none';
      _error = null;
    });
    
    // Focus on the search field and open keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

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
            builder: (ctx2, setStateModal) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
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
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selCat,
                      hint: const Text(
                        'Category (optional)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                      items:
                          [
                            null,
                            ...MockDatabase.categories.map((c) => c['name']),
                          ].map((v) {
                            if (v == null) {
                              return const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'Any',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF3D3D3D),
                                  ),
                                ),
                              );
                            }
                            return DropdownMenuItem<String>(
                              value: v,
                              child: Text(
                                v,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3D3D3D),
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (v) => setStateModal(() => selCat = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: minCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Min price (R)',
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: maxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Max price (R)',
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFF2563EB)),
                            ),
                            onPressed: () {
                              selCat = null;
                              minCtrl.clear();
                              maxCtrl.clear();
                              setStateModal(() {});
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                            ),
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
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          title: TextField(
            controller: _ctrl,
            focusNode: _searchFocusNode,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Color(0xFF3D3D3D),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Search products...',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                color: Color(0xFF3D3D3D),
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitSearch(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Color(0xFF2563EB)),
              onPressed: _openFilterModal,
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF2563EB)),
              onPressed: _submitSearch,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Sort:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sort == 'none' ? null : _sort,
                    hint: const Text(
                      'None',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Text(
                          'Price: Low→High',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text(
                          'Price: High→Low',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _sort = v ?? 'none';
                      _sortResults();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_filterCategory != null ||
                  _filterMinPrice != null ||
                  _filterMaxPrice != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      const Chip(
                        label: Text(
                          'Filters active',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_filterCategory != null)
                        Chip(
                          label: Text(
                            'Category: ${_filterCategory!}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (_filterMinPrice != null)
                        Chip(
                          label: Text(
                            'Min: R${_filterMinPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (_filterMaxPrice != null)
                        Chip(
                          label: Text(
                            'Max: R${_filterMaxPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filterCategory = null;
                            _filterMinPrice = null;
                            _filterMaxPrice = null;
                          });
                          _submitSearch();
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
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
                            Text(
                              'Error: $_error',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3D3D3D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                              ),
                              onPressed: () => _submitSearch(),
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
    ? Column(
        children: [
          // No results message
          Container(
            width: double.infinity,
            height: 280,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No results found',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFFFFFFF).withOpacity(0.3),
                ),
                const SizedBox(height: 13),
                const Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Helpful tips:\n',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFFFFFFFF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Be sure to use correct spelling for keywords\n• Try using general keywords',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Color(0xFFFFFFFF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF000000),
                    side: const BorderSide(color: Color(0xFFFFFFFF)),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) =>  HomePage()),
    (route) => false,
  );
},

                  child: const Text(
                    'Home',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xFF000000),
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
    );
  }

} 