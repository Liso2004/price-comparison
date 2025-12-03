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
      appBar: AppBar(title: const Text('Legal Docs')),
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
                '''The information provided by SmartBasket we , us or our on our mobile application is for general informational purposes only. All information on our mobile application is provided in good faith, however we make no representation or warranty of any kind, express or implied, regarding the accuracy, adequacy, validity, reliability, availability, or completeness of any information on our mobile application. UNDER NO CIRCUMSTANCE SHALL WE HAVE ANY LIABILITY TO YOU FOR ANY LOSS OR DAMAGE OF ANY KIND INCURRED AS A RESULT OF THE USE OF OUR MOBILE APPLICATION OR RELIANCE ON ANY INFORMATION PROVIDED ON OUR MOBILE APPLICATION. YOUR USE OF OUR MOBILE APPLICATION AND YOUR RELIANCE ON ANY INFORMATION ON OUR MOBILE APPLICATION IS SOLELY AT YOUR OWN RISK.
''',
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
