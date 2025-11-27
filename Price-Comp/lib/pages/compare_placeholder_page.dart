import 'package:flutter/material.dart';

class ComparePlaceholderPage extends StatefulWidget {
  const ComparePlaceholderPage({super.key});

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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.compare_arrows, size: 64),
            SizedBox(height: 12),
            Text(
              'Compare Page (placeholder)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Open a product from Search to view a detailed comparison.'),
          ],
        ),
      ),
    );
  }
}
