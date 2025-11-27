import 'package:flutter/material.dart';

class RetailerPlaceholder extends StatefulWidget {
  const RetailerPlaceholder({Key? key}) : super(key: key);

  @override
  _RetailerPlaceholderState createState() => _RetailerPlaceholderState();
}

class _RetailerPlaceholderState extends State<RetailerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6)
            ],
          ),
          child: Row(
            children: [
              // Avatar placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getShimmerColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Retailer name placeholder
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getShimmerColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Price placeholder
              Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: _getShimmerColor(),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getShimmerColor() {
    final value = _shimmerController.value;
    final opacity = (0.3 + (value * 0.2)).clamp(0.0, 1.0);
    return Colors.grey.withOpacity(opacity);
  }
}
