import 'package:flutter/material.dart';
import 'legal_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    debugPrint('[SettingsPage] started');
  }

  @override
  void dispose() {
    debugPrint('[SettingsPage] stopped');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ListTile(
              title: const Text('Legal & Disclaimer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LegalPage()),
              ),
            ),

            const ListTile(
              title: Text('About'),
              subtitle: Text(
                'This app helps you compare product prices across multiple retailers '
                'Easily view detailed product information, track price '
                'changes, and make smarter purchasing decisions with a simple, '
                'user-friendly interface.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
