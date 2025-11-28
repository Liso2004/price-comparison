import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../widgets/category_card.dart';
import 'search_page.dart';
import 'legal_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _chipScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint('[HomePage] started');
  }

  @override
  void dispose() {
    debugPrint('[HomePage] stopped');
    _searchCtrl.dispose();
    _chipScrollCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final text = _searchCtrl.text.trim();
    if (text.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage(initialQuery: text)),
    );
  }

  void _onQuickTap(String q) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage(initialQuery: q)),
    );
  }

  // Scroll helper
  void _scrollChips(bool forward) {
    const double amount = 120;
    if (forward) {
      _chipScrollCtrl.animateTo(
        _chipScrollCtrl.offset + amount,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _chipScrollCtrl.animateTo(
        _chipScrollCtrl.offset - amount,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ADDED: Scaffold to provide Material widget
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------ SEARCH BAR ------------------------
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search products, e.g. "Milk"',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _searchCtrl.clear()),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: (_) => _onSearch(),
                      onChanged: (_) => setState(() {}),
                    ),

                    // Clear button
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                            onPressed: () => setState(() => _searchCtrl.clear()),
                          ),
                  ),

                  onSubmitted: (_) => _onSearch(),
                  onChanged: (_) => setState(() {}),
                ),
              ),

                const SizedBox(width: 10),
                ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // primary color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _onSearch,
                child: const Text(
                  'Search',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick search',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockDatabase.quickSearches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final q = MockDatabase.quickSearches[index];
                  return ActionChip(
                    label: Text(q),
                    onPressed: () => _onQuickTap(q),
                  );
                },
              ),

              const SizedBox(height: 18),

              // ------------------------ QUICK SEARCH ------------------------
              // REMOVED: The duplicate quick search section with arrow
              const Text(
                'Quick Searches', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )
              ),
              const SizedBox(height: 8),
              
              SizedBox(
                height: 50, // Fixed height to prevent overflow
                child: ListView.separated(
                  controller: _chipScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  itemCount: MockDatabase.quickSearches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final q = MockDatabase.quickSearches[index];
                    return ActionChip(
                      label: Text(q),
                      onPressed: () => _onQuickTap(q),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // ------------------------ CATEGORIES ------------------------
              Text(
                'Product Category', 
                style: Theme.of(context).textTheme.titleMedium
              ),
              const SizedBox(height: 8),

              Expanded(
                child: GridView.builder(
                  itemCount: MockDatabase.categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 4,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, idx) {
                    final cat = MockDatabase.categories[idx];
                    return CategoryCard(
                      title: cat['name'] ?? '',
                      imagePath: cat['imagePath'], 
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SearchPage(initialQuery: cat['name'] ?? ''),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ------------------------ LEGAL NOTICE ------------------------
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Data shown is mock/demo only. '),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LegalPage()),
                      ),
                      child: const Text('Legal'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}