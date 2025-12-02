import 'package:flutter/material.dart';
import '../models/retailer_price.dart';

class RetailerCard extends StatelessWidget {
  final RetailerPrice price;
  final bool highlight;
  const RetailerCard({super.key, required this.price, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text(price.retailerName[0])),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              price.retailerName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          price.price == null
              ? const Text('N/A')
              : Text(
                  'R ${price.price!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ],
      ),
    );
  }
}
