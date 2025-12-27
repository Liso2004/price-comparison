import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';
import '../pages/compare_placeholder_page.dart';
import '../pages/settings_page.dart';
import '../pages/bulk_list_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  String _searchInitialQuery = '';
  
  @override
  void initState() {
    super.initState();
    debugPrint('[MainScaffold] started');
  }

  @override
  void dispose() {
    debugPrint('[MainScaffold] stopped');
    super.dispose();
  }

  void _onTap(int idx) => setState(() => _currentIndex = idx);
  
  void _navigateToBulkList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BulkListPage()),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Recreate pages here so we can pass a dynamic initial query
    final pages = <Widget>[
      HomePage(
        onNavigateToSearch: (q) {
          setState(() {
            _searchInitialQuery = q;
            _currentIndex = 1;
          });
        },
        onNavigateToBulkList: _navigateToBulkList,
      ),
      SearchPage(initialQuery: _searchInitialQuery),
      const BulkListPage(),
      ComparePlaceholderPage(
        onHomePressed: () {
          debugPrint(
            '[MainScaffold] Home button callback triggered, switching to index 0',
          );
          setState(() => _currentIndex = 0);
        },
      ),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'Bulk List',
          ),
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