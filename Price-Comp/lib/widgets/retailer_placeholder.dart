import 'package:flutter/material.dart';

class RetailerPlaceholder extends StatelessWidget {
  const RetailerPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
