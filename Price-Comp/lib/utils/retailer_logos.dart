class RetailerLogos {
  static const Map<String, String> logos = {
    "checkers": "assets/retailers/checkers.png",
    "woolworths": "assets/retailers/woolworths.png",
    "pick n pay": "assets/retailers/picknpay.png",
    "game": "assets/retailers/game.png",
  };

  static String? getLogo(String retailer) {
    return logos[retailer.trim().toLowerCase()];
  }
}
