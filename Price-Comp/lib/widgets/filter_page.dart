import 'package:flutter/material.dart';
import '../services/services.dart';

// --- Styling Constants ---
const Color _primaryColor = Color(0xFF2563EB);
const Color _darkTextColor = Color(0xFF3D3D3D);
const Color _lightTextColor = Color(0xFFFFFFFF);

class FilterPage extends StatefulWidget {
  final String? initialCategory;
  // REMOVED: final double? initialMinPrice;
  // REMOVED: final double? initialMaxPrice;
  final String initialSort;

  const FilterPage({super.key, 
    this.initialCategory,
    // REMOVED: this.initialMinPrice,
    // REMOVED: this.initialMaxPrice,
    required this.initialSort,
  });

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  // Filter options from API
  final List<String> _retailers = [
    'Woolworths',
    'Checkers',
    'Pick n Pay',
    'Shoprite',
  ];
  final List<String> _sortOptions = [
    'Low → High',
    'High → Low',
    'Best Value',
    'Most Popular',
  ];
  List<dynamic> _categories = [];
  bool _loadingCategories = false;

  // Local state variables for selections
  String? _selectedRetailer;
  String? _selectedCategory;
  late String _selectedSort = 'none';

  @override
  void initState() {
    super.initState();
    // Initialize local state from passed initial values
    _selectedRetailer = null;
    _selectedCategory = widget.initialCategory;

    // Map the initial sort code ('low', 'high') to the label for display
    if (widget.initialSort == 'low') {
      _selectedSort = 'Low → High';
    } else if (widget.initialSort == 'high') {
      _selectedSort = 'High → Low';
    } else {
      _selectedSort = 'none';
    }

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() => _loadingCategories = false);
      debugPrint('Error loading categories: $e');
    }
  }

  // Helper method to build the filter chips
  Widget _buildChipGroup({
    required String title,
    required List<String> options,
    required bool Function(String) isSelected,
    required void Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _darkTextColor,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: options.map((option) {
            final selected = isSelected(option);
            return FilterChip(
              label: Text(option),
              labelStyle: TextStyle(
                color: selected ? _lightTextColor : _darkTextColor,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
              selected: selected,
              backgroundColor: Colors.grey.shade100,
              selectedColor: _primaryColor,
              onSelected: (_) => onSelected(option),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: selected ? _primaryColor : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- Apply and Return Results ---
  void _applyFilters() {
    String finalSortCode = 'none';

    if (_selectedSort == 'Low → High') {
      finalSortCode = 'low';
    } else if (_selectedSort == 'High → Low') {
      finalSortCode = 'high';
    }
    // If _selectedSort is 'Best Value', 'Most Popular', or 'none', it defaults to finalSortCode = 'none'.

    // ... (rest of the function remains the same)
    final Map<String, dynamic> results = {
      'category': _selectedCategory,
      'minPrice': null,
      'maxPrice': null,
      'sort': finalSortCode,
    };

    Navigator.pop(context, results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Mimic the mockup header
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _darkTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filters',
          style: TextStyle(
            color: _darkTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: false,
        actions: [],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // --- RETAILERS ---
                _buildChipGroup(
                  title: 'Retailers',
                  options: _retailers,
                  isSelected: (option) => option == _selectedRetailer,
                  onSelected: (option) {
                    setState(() {
                      _selectedRetailer = option == _selectedRetailer
                          ? null
                          : option; // toggle select/deselect
                    });
                  },
                ),

                // --- CATEGORY ---
                _buildChipGroup(
                  title: 'Category',
                  options: _loadingCategories
                      ? []
                      : _categories
                          .map((c) => c['name']?.toString() ?? 'Unknown')
                          .toList(),
                  isSelected: (option) => option == _selectedCategory,
                  onSelected: (option) {
                    setState(() {
                      _selectedCategory = option == _selectedCategory
                          ? null
                          : option; // toggle select/deselect
                    });
                  },
                ),

                // --- PRICE (Sort Options) ---
                _buildChipGroup(
                  title: 'Price',
                  options: _sortOptions,
                  isSelected: (option) => option == _selectedSort,
                  onSelected: (option) {
                    setState(() {
                      _selectedSort = option == _selectedSort ? 'none' : option;
                    });
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // --- FIXED APPLY BUTTON AT THE BOTTOM ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.black12, width: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: SizedBox(
                    width: 160,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
