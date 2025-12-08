import 'package:flutter/material.dart';
import '../data/mock_database.dart';
import '../widgets/category_card.dart';
import 'search_page.dart';
import 'legal_page.dart';

//comment
class HomePage extends StatefulWidget {
  final void Function(String)? onNavigateToSearch;
  const HomePage({super.key, this.onNavigateToSearch});

  @override
  State<HomePage> createState() => _HomePageState();
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

    if (widget.onNavigateToSearch != null) {
      widget.onNavigateToSearch!(text);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage(initialQuery: text)),
    );
  }

  void _onQuickTap(String q) {
    if (widget.onNavigateToSearch != null) {
      widget.onNavigateToSearch!(q);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage(initialQuery: q)),
    );
  }

  void _scrollChips(bool forward) {
    const double amount = 120;
    _chipScrollCtrl.animateTo(
      _chipScrollCtrl.offset + (forward ? amount : -amount),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------ LOGO ------------------------
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 44,
                        offset: Offset(2, 0),
                      ),
                    ],
                  ),
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ShopWise',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: Color(0xFF2563EB),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ------------------------ SEARCH BAR ------------------------
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Search for products...',
                            hintStyle: TextStyle(
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF9CA3AF),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF3D3D3D),
                          ),
                          onSubmitted: (_) => _onSearch(),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF6B7280),
                          ),
                          onPressed: () => setState(() => _searchCtrl.clear()),
                        ),
                      Container(
                        width: 1,
                        height: 24,
                        color: const Color(0xFFE5E7EB),
                      ),
                      IconButton(
                        onPressed: _onSearch,
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------ QUICK SEARCH ------------------------
                const Text(
                  "Quick Search",
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Search Chips with Scroll Arrow
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ListView.separated(
                          controller: _chipScrollCtrl,
                          scrollDirection: Axis.horizontal,
                          itemCount: MockDatabase.quickSearches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final q = MockDatabase.quickSearches[index];
                            return GestureDetector(
                              onTap: () => _onQuickTap(q),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  q,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: "Inter",
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 48,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
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
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF6B7280),
                        ),
                        onPressed: () => _scrollChips(true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ------------------------ CATEGORIES ------------------------
                const Text(
                  "Categories",
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                const SizedBox(height: 12),

                // Categories Grid - Using shrinkWrap instead of Expanded
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: MockDatabase.categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 4 / 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, idx) {
                    final cat = MockDatabase.categories[idx];
                    return CategoryCard(
                      title: cat['name'] ?? '',
                      imagePath: cat['imagePath'],
                      onTap: () {
                        final name = cat['name'] ?? '';
                        if (widget.onNavigateToSearch != null) {
                          widget.onNavigateToSearch!(name);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchPage(initialQuery: name),
                          ),
                        );
                      },
                    );
                  },
                ),

                // ------------------------ FOOTER ------------------------
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LegalPage()),
                        );
                      },
                      child: const Text(
                        "Legal",
                        style: TextStyle(
                          fontFamily: "Inter",
                          color: Color(0xFF2563EB),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
