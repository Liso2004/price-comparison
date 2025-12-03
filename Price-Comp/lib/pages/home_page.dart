import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../widgets/category_card.dart';
import 'legal_page.dart';

class HomePage extends StatefulWidget {
  final Function(String) onCategorySelected;
  const HomePage({super.key, required this.onCategorySelected});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _chipScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint("[HomePage] started");
  }

  @override
  void dispose() {
    debugPrint("[HomePage] stopped");
    _searchCtrl.dispose();
    _chipScrollCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final text = _searchCtrl.text.trim();
    if (text.isEmpty) return;

    // Use callback to switch to SearchPage tab with query
    widget.onCategorySelected(text);
  }

  void _onQuickTap(String q) {
    // Use callback to switch to SearchPage tab with query
    widget.onCategorySelected(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => _searchCtrl.clear()),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _onSearch(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _onSearch,
                    child: const Text(
                      "Search",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ------------------------ QUICK SEARCH ------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Quick search",
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

              const SizedBox(height: 22),

              // ------------------------ CATEGORIES ------------------------
              Text(
                "Product Categories",
                style: Theme.of(context).textTheme.titleMedium,
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
                  itemBuilder: (context, index) {
                    final cat = MockDatabase.categories[index];
                    return CategoryCard(
                      title: cat["name"] ?? "",
                      imagePath: cat["imagePath"],
                      onTap: () => widget.onCategorySelected(cat["name"] ?? ""),
                    );
                  },
                ),
              ),

              // ------------------------ LEGAL ------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Data shown is mock/demo only. "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LegalPage()),
                      );
                    },
                    child: const Text("Legal"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}