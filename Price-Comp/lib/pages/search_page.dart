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

  @override
  void initState() {
    super.initState();
    debugPrint('[SearchPage] started');
    _ctrl = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) _submitSearch();
  }

  @override
  void dispose() {
    debugPrint('[SearchPage] stopped');
    _ctrl.dispose();
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
                            fontWeight: FontWeight.bold,
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
                      value: selCat,
                      hint: const Text('Category (optional)'),
                      items:
                          [
                            null,
                            ...MockDatabase.categories.map((c) => c['name']),
                          ].map((v) {
                            if (v == null)
                              return const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Any'),
                              );
                            return DropdownMenuItem<String>(
                              value: v,
                              child: Text(v),
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              selCat = null;
                              minCtrl.clear();
                              maxCtrl.clear();
                              setStateModal(() {});
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
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
                        child: Text('Price: Low→High'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('Price: High→Low'),
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
                      const Chip(label: Text('Filters active')),
                      if (_filterCategory != null)
                        Chip(label: Text('Category: ${_filterCategory!}')),
                      if (_filterMinPrice != null)
                        Chip(
                          label: Text(
                            'Min: R${_filterMinPrice!.toStringAsFixed(2)}',
                          ),
                        ),
                      if (_filterMaxPrice != null)
                        Chip(
                          label: Text(
                            'Max: R${_filterMaxPrice!.toStringAsFixed(2)}',
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
                        child: const Text('Clear'),
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
                            Text('Error: $_error'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _submitSearch(),
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
