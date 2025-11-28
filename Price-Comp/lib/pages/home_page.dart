import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../widgets/category_card.dart';
import 'search_page.dart';
import 'legal_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
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
      MaterialPageRoute(builder: (_) => SearchPage(initialQuery: text)),
    );
  }

  void _onQuickTap(String q) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage(initialQuery: q)),
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
                  style: const TextStyle(
                    color: Color(0xFF3D3D3D), // dark text
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search for products...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF), // light grey hint
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),

                    // Rounded white box
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB), // light border
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB), // primary blue
                        width: 1.7,
                      ),
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
            ),
            const SizedBox(height: 18),
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),
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
                    title: cat['name']!,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchPage(initialQuery: cat['name']!),
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