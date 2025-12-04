class RetailerPrice {
  final String retailerId;
  final String retailerName;
  final double? price;
  final String? productUrl;

  RetailerPrice({
    required this.retailerId,
    required this.retailerName,
    this.price,
    this.productUrl,
  });
}
