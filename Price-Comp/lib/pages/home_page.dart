import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../widgets/category_card.dart';
import 'search_page.dart';
import 'legal_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('[HomePage] started');
  }

  @override
  void dispose() {
    debugPrint('[HomePage] stopped');
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final text = _searchCtrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage(initialQuery: text)),
    );
  }

  void _onQuickTap(String q) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage(initialQuery: q)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                              onPressed: () =>
                                  setState(() => _searchCtrl.clear()),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
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

        // removed prefix icon
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () => setState(() => _searchCtrl.clear()),
              ),

        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onSubmitted: (_) => _onSearch(),
      onChanged: (_) => setState(() {}),
    ),
  ),

  const SizedBox(width: 12),

  SizedBox(
    height: 48,
    child: ElevatedButton(
      onPressed: _onSearch,
      style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // primary color
                  foregroundColor: Colors.white,              // text color
        minimumSize: const Size(72, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Search',
        style: TextStyle(
          color: Colors.white, // button text white 
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
]
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
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockDatabase.quickSearches.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                itemCount: MockDatabase.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 1.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, idx) {
                  final cat = MockDatabase.categories[idx];
                  return CategoryCard(
                    title: cat['name'] ?? '',
                    imagePath: cat['imagePath'],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchPage(initialQuery: cat['name']!),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Data shown is mock/demo only. '),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LegalPage()),
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
