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
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _ctrl;
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
    _ctrl = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      _submitSearch();
    }
  }

  @override
  void dispose() {
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

      var filtered = res;

      if (_filterCategory != null && _filterCategory!.isNotEmpty) {
        filtered = filtered.where((p) => p.category == _filterCategory).toList();
      }

      if (_filterMinPrice != null || _filterMaxPrice != null) {
        filtered = filtered.where((p) {
          final price = MockDatabase.getMockPrice(p.id);
          final minOk = _filterMinPrice == null || price >= _filterMinPrice!;
          final maxOk = _filterMaxPrice == null || price <= _filterMaxPrice!;
          return minOk && maxOk;
        }).toList();
      }

      setState(() => _results = filtered);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onProductTap(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComparisonPage(product: product)),
    );
  }

  void _sortResults() {
    setState(() {
      if (_sort == 'low') {
        _results.sort((a, b) => MockDatabase.getMockPrice(a.id)
            .compareTo(MockDatabase.getMockPrice(b.id)));
      } else if (_sort == 'high') {
        _results.sort((a, b) => MockDatabase.getMockPrice(b.id)
            .compareTo(MockDatabase.getMockPrice(a.id)));
      }
    });
  }

  Widget _buildSortDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          "Sort:",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        DropdownButton<String>(
          value: _sort == 'none' ? null : _sort,
          hint: const Text(
            "None",
            style: TextStyle(fontFamily: 'Inter'),
          ),
          items: const [
            DropdownMenuItem(
              value: "low",
              child: Text("Price: Low → High",
                  style: TextStyle(fontFamily: 'Inter')),
            ),
            DropdownMenuItem(
              value: "high",
              child: Text("Price: High → Low",
                  style: TextStyle(fontFamily: 'Inter')),
            ),
          ],
          onChanged: (value) {
            setState(() => _sort = value ?? 'none');
            _sortResults();
          },
        ),
      ],
    );
  }

  Widget _buildGrid() {
    if (_loading) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.95, // <--- UPDATED (wider / less tall)
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const ProductPlaceholder(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          "Error: $_error",
          style: const TextStyle(fontFamily: 'Inter'),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          "No results found",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,                // <--- 3 CARDS PER ROW
        childAspectRatio: 0.95,           // <--- WIDER CARDS
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final product = _results[index];
        final price = MockDatabase.getMockPrice(product.id);
        return ProductCard(
          product: product,
          price: price,
          onTap: () => _onProductTap(product),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Search products...",
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitSearch(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: _submitSearch,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildSortDropdown(),
              const SizedBox(height: 8),
              Expanded(child: _buildGrid()),
            ],
          ),
        ),
      ),
    );
  }
}
