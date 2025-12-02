import 'package:flutter/material.dart';

class ComparePlaceholderPage extends StatefulWidget {
  final VoidCallback? onHomePressed;
  const ComparePlaceholderPage({super.key, this.onHomePressed});

  @override
  _ComparePlaceholderPageState createState() => _ComparePlaceholderPageState();
}

class _ComparePlaceholderPageState extends State<ComparePlaceholderPage> {
  @override
  void initState() {
    super.initState();
    debugPrint('[ComparePlaceholderPage] started');
  }

  @override
  void dispose() {
    debugPrint('[ComparePlaceholderPage] stopped');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No results found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(horizontal: 20),
            ),
            const SizedBox(height: 16),
            const Text(
              'Helpful tips:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Open a product from Search to view a detailed comparison',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                debugPrint('[ComparePlaceholderPage] Home button pressed');
                if (widget.onHomePressed != null) {
                  debugPrint('[ComparePlaceholderPage] Calling onHomePressed callback');
                  widget.onHomePressed!();
                } else {
                  debugPrint('[ComparePlaceholderPage] No callback, using Navigator');
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Home',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}