import 'package:flutter/material.dart';

class ProductPlaceholder extends StatelessWidget {
  const ProductPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
