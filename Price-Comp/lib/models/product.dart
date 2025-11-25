class Product {
  final String id;
  final String name;
  final String size;
  final String category;
  final String image;

  Product({
    required this.id,
    required this.name,
    required this.size,
    required this.category,
    this.image = '',
  });
}
