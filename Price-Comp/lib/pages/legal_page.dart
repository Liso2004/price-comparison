import 'package:flutter/material.dart';

class LegalPage extends StatefulWidget {
  const LegalPage({super.key});

  @override
  _LegalPageState createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  @override
  void initState() {
    super.initState();
    debugPrint('[LegalPage] started');
  }

  @override
  void dispose() {
    debugPrint('[LegalPage] stopped');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal & Data Disclaimer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Disclaimer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'This application is a demonstration using mock data only. Prices and availability are simulated for development and testing purposes and do not reflect live retailer data.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Data Handling',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'No background or automated data retrieval is performed. Data is retrieved only when you explicitly trigger search or check prices.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Contact',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'For more information, refer to the project documentation.',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
