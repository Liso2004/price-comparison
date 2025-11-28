import '../models/product.dart';
import '../models/retailer_price.dart';

class MockDatabase {
  static List<String> quickSearches = [
    'Milk',
    'Rice',
    'Dishwasher',
    'Toothpaste',
    'Olive Oil',
    'Chicken',
    'Bread',
    'Eggs',
    'Bananas',
    'Coke',
    'Potatoes',
    'Rice 1kg',
  ];

  static List<Map<String, String>> categories = [
    {'id': 'cat1', 'name': 'Beverages'},
    {'id': 'cat2', 'name': 'Groceries'},
    {'id': 'cat3', 'name': 'Household'},
    {'id': 'cat4', 'name': 'Personal Care'},
    {'id': 'cat5', 'name': 'Bakery'},
    {'id': 'cat6', 'name': 'Meat'},
    {'id': 'cat7', 'name': 'Snacks'},
  ];

  static List<Product> products = [
    Product(
      id: 'p1',
      name: 'Full Cream Milk',
      size: '2L',
      category: 'Beverages',
    ),
    Product(id: 'p2', name: 'Low Fat Milk', size: '1L', category: 'Beverages'),
    Product(
      id: 'p3',
      name: 'Full Cream Milk',
      size: '1L',
      category: 'Beverages',
    ),
    Product(id: 'p4', name: 'Organic Milk', size: '2L', category: 'Beverages'),
    Product(
      id: 'p5',
      name: 'Lactose Free Milk',
      size: '1L',
      category: 'Beverages',
    ),
    Product(
      id: 'p6',
      name: 'Flavored Milk',
      size: '500ml',
      category: 'Beverages',
    ),

    Product(
      id: 'p7',
      name: 'Long Grain Rice',
      size: '1kg',
      category: 'Groceries',
    ),
    Product(id: 'p8', name: 'Basmati Rice', size: '2kg', category: 'Groceries'),
    Product(id: 'p9', name: 'Brown Rice', size: '1kg', category: 'Groceries'),
    Product(
      id: 'p10',
      name: 'Jasmine Rice',
      size: '1kg',
      category: 'Groceries',
    ),
    Product(id: 'p11', name: 'Wild Rice', size: '500g', category: 'Groceries'),
    Product(id: 'p12', name: 'Sushi Rice', size: '1kg', category: 'Groceries'),

    Product(
      id: 'p13',
      name: 'Extra Virgin Olive Oil',
      size: '500ml',
      category: 'Groceries',
    ),
    Product(
      id: 'p14',
      name: 'Pure Olive Oil',
      size: '750ml',
      category: 'Groceries',
    ),
    Product(
      id: 'p15',
      name: 'Light Olive Oil',
      size: '1L',
      category: 'Groceries',
    ),
    Product(
      id: 'p16',
      name: 'Organic Olive Oil',
      size: '500ml',
      category: 'Groceries',
    ),
    Product(
      id: 'p17',
      name: 'Cold Pressed Olive Oil',
      size: '250ml',
      category: 'Groceries',
    ),
    Product(
      id: 'p18',
      name: 'Flavored Olive Oil',
      size: '500ml',
      category: 'Groceries',
    ),

    Product(id: 'p19', name: 'Large Eggs', size: '12 pack', category: 'Bakery'),
    Product(
      id: 'p20',
      name: 'Free Range Eggs',
      size: '6 pack',
      category: 'Bakery',
    ),
    Product(
      id: 'p21',
      name: 'Organic Eggs',
      size: '12 pack',
      category: 'Bakery',
    ),
    Product(id: 'p22', name: 'Jumbo Eggs', size: '18 pack', category: 'Bakery'),
    Product(id: 'p23', name: 'Brown Eggs', size: '12 pack', category: 'Bakery'),
    Product(id: 'p24', name: 'Quail Eggs', size: '24 pack', category: 'Bakery'),

    Product(id: 'p25', name: 'White Bread', size: '700g', category: 'Bakery'),
    Product(
      id: 'p26',
      name: 'Whole Wheat Bread',
      size: '600g',
      category: 'Bakery',
    ),
    Product(id: 'p27', name: 'Rye Bread', size: '500g', category: 'Bakery'),
    Product(
      id: 'p28',
      name: 'Gluten Free Bread',
      size: '400g',
      category: 'Bakery',
    ),
    Product(
      id: 'p29',
      name: 'Sourdough Bread',
      size: '800g',
      category: 'Bakery',
    ),
    Product(
      id: 'p30',
      name: 'Multigrain Bread',
      size: '750g',
      category: 'Bakery',
    ),

    Product(id: 'p31', name: 'Chicken Breast', size: '1kg', category: 'Meat'),
    Product(id: 'p32', name: 'Chicken Thighs', size: '500g', category: 'Meat'),
    Product(id: 'p33', name: 'Whole Chicken', size: '1.5kg', category: 'Meat'),
    Product(id: 'p34', name: 'Chicken Wings', size: '1kg', category: 'Meat'),
    Product(
      id: 'p35',
      name: 'Chicken Drumsticks',
      size: '800g',
      category: 'Meat',
    ),
    Product(
      id: 'p36',
      name: 'Free Range Chicken',
      size: '1.2kg',
      category: 'Meat',
    ),

    Product(
      id: 'p37',
      name: 'Fluoride Toothpaste',
      size: '100ml',
      category: 'Personal Care',
    ),
    Product(
      id: 'p38',
      name: 'Whitening Toothpaste',
      size: '75ml',
      category: 'Personal Care',
    ),
    Product(
      id: 'p39',
      name: 'Sensitive Teeth Paste',
      size: '90ml',
      category: 'Personal Care',
    ),
    Product(
      id: 'p40',
      name: 'Natural Toothpaste',
      size: '120ml',
      category: 'Personal Care',
    ),
    Product(
      id: 'p41',
      name: "Children's Toothpaste",
      size: '50ml',
      category: 'Personal Care',
    ),
    Product(
      id: 'p42',
      name: 'Charcoal Toothpaste',
      size: '100ml',
      category: 'Personal Care',
    ),

    Product(
      id: 'p43',
      name: 'Dishwasher Tablets',
      size: '30 tablets',
      category: 'Household',
    ),
    Product(
      id: 'p44',
      name: 'Dishwasher Salt',
      size: '2kg',
      category: 'Household',
    ),
    Product(
      id: 'p45',
      name: 'Dishwasher Liquid',
      size: '1L',
      category: 'Household',
    ),
    Product(id: 'p46', name: 'Rinse Aid', size: '500ml', category: 'Household'),
    Product(
      id: 'p47',
      name: 'Eco Dishwasher Powder',
      size: '1kg',
      category: 'Household',
    ),
    Product(
      id: 'p48',
      name: 'All-in-One Dishwasher',
      size: '40 tablets',
      category: 'Household',
    ),

    Product(id: 'p49', name: 'Coca-Cola 2L', size: '2L', category: 'Beverages'),
    Product(
      id: 'p50',
      name: 'Potatoes 2kg',
      size: '2kg',
      category: 'Groceries',
    ),
    Product(
      id: 'p51',
      name: 'Sunflower Oil 2L',
      size: '2L',
      category: 'Groceries',
    ),
    Product(id: 'p52', name: 'Savoury Chips', size: '150g', category: 'Snacks'),
  ];

  static List<Map<String, String>> retailers = [
    {'id': 'r1', 'name': 'Pick n Pay'},
    {'id': 'r2', 'name': 'Checkers'},
    {'id': 'r3', 'name': 'Woolworths'},
    {'id': 'r4', 'name': 'Game'},
  ];

  static double getMockPrice(String productId) {
    final n = int.tryParse(productId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 10 + (n * 1.75) % 120;
  }

  static Future<List<Product>> searchProducts(
    String query, {
    int delayMs = 600,
    bool fail = false,
  }) async {
    await Future.delayed(Duration(milliseconds: delayMs));
    if (fail) throw Exception('Network error (mock)');
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.size.toLowerCase().contains(q),
        )
        .toList();
  }

  static Future<List<RetailerPrice>> getComparison(
    String productId, {
    int delayMs = 900,
    bool fail = false,
    bool partial = false,
  }) async {
    await Future.delayed(Duration(milliseconds: delayMs));
    if (fail) throw Exception('Failed to fetch comparison (mock)');

    final basePrices = {'r1': 35.99, 'r2': 33.49, 'r3': 39.00, 'r4': 34.50};

    List<RetailerPrice> list = [];
    for (var r in retailers) {
      final id = r['id']!;
      final name = r['name']!;
      final base = getMockPrice(productId);
      double p = (base + (base * (id.hashCode % 7) / 100)).clamp(5.0, 999.0);
      if (partial && id == 'r3') {
        list.add(
          RetailerPrice(retailerId: id, retailerName: name, price: null),
        );
      } else {
        list.add(
          RetailerPrice(
            retailerId: id,
            retailerName: name,
            price: double.parse(p.toStringAsFixed(2)),
          ),
        );
      }
    }
    return list;
  }
}
