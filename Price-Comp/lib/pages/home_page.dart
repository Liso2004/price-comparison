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
    // Use scaffold background color for arrow container so it blends nicely
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return SafeArea(
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
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _onSearch,
                  child: const Row(
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 6),
                      Text('Search'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ------------------------ QUICK SEARCH ------------------------
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42, // height of the chips
                    child: ListView.separated(
                      controller: _chipScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 0, right: 110),
                      itemCount: MockDatabase.quickSearches.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final q = MockDatabase.quickSearches[index];
                        return GestureDetector(
                          onTap: () => _onQuickTap(q),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 80),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              q,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow container
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
                    color: Colors.black87,
                    onPressed: () => _scrollChips(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 40,
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
            ),

            const SizedBox(height: 18),

            // ------------------------ CATEGORIES ------------------------
            Text('Product Category', style: Theme.of(context).textTheme.titleMedium),
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
    );
  }
}
