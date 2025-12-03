import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';
import '../pages/compare_placeholder_page.dart';
import '../pages/settings_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late final List<Widget> pages;
  String _searchQuery = ''; // Track search query

  @override
  void initState() {
    super.initState();
    pages = <Widget>[
      HomePage(
        onCategorySelected: (query) {
          // When category is selected from HomePage
          setState(() {
            _searchQuery = query;
            _currentIndex = 1; // Switch to SearchPage tab
          });
        },
      ),
      SearchPage(
        initialQuery: _searchQuery,
        key: ValueKey(_searchQuery), // Key helps rebuild when query changes
      ),
      ComparePlaceholderPage(
        onHomePressed: () {
          debugPrint('[MainScaffold] Home button callback triggered');
          setState(() => _currentIndex = 0);
        },
      ),
      const SettingsPage(),
    ];
    debugPrint('[MainScaffold] started');
  }

  @override
  void dispose() {
    debugPrint('[MainScaffold] stopped');
    super.dispose();
  }

  void _onTap(int idx) {
    if (idx == 1 && _searchQuery.isNotEmpty) {
      // If switching to SearchPage and we have a query, ensure it's passed
      setState(() {
        _currentIndex = idx;
        // Update the SearchPage widget with current query
        pages[1] = SearchPage(
          initialQuery: _searchQuery,
          key: ValueKey(_searchQuery),
        );
      });
    } else {
      setState(() => _currentIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Compare',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}