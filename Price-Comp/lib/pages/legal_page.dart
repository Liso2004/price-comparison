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
                '''The information provided by ShopWise we , us or our on our mobile application is for general informational purposes only. All information on our mobile application is provided in good faith, however we make no representation or warranty of any kind, express or implied, regarding the accuracy, adequacy, validity, reliability, availability, or completeness of any information on our mobile application. UNDER NO CIRCUMSTANCE SHALL WE HAVE ANY LIABILITY TO YOU FOR ANY LOSS OR DAMAGE OF ANY KIND INCURRED AS A RESULT OF THE USE OF OUR MOBILE APPLICATION OR RELIANCE ON ANY INFORMATION PROVIDED ON OUR MOBILE APPLICATION. YOUR USE OF OUR MOBILE APPLICATION AND YOUR RELIANCE ON ANY INFORMATION ON OUR MOBILE APPLICATION IS SOLELY AT YOUR OWN RISK.
''',
              ),
              const Text(
                'EXTERNAL LINKS DISCLAIMER ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                '''Our mobile application may contain (or you may be sent through our mobile application) links to other websites or content belonging to or originating from third parties or links to websites and features in banners or other advertising. Such external links are not investigated, monitored, or checked for accuracy, adequacy, validity, reliability, availability, or completeness by us. WE DO NOT WARRANT, ENDORSE, GUARANTEE, OR ASSUME RESPONSIBILITY FOR THE ACCURACY OR RELIABILITY OF ANY INFORMATION OFFERED BY THIRD PARTY WEBSITES LINKED THROUGH THE SITE OR ANY WEBSITE OR FEATURE LINKED IN ANY BANNER OR OTHER ADVERTISING. WE WILL NOT BE A PARTY TO OR IN ANY WAY BE RESPONSIBLE FOR MONITORING ANY TRANSACTION BETWEEN YOU AND THIRD-PARTY PROVIDERS OF PRODUCTS OR SERVICES.

''',
              ),
              const Text(
                'Cybercrimes Act',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                ''' This application's data acquisition methodology is strictly designed to operate within the technical parameters established by the target retail websites, specifically adhering to the robots.txt protocol. This includes:
Strict observation of all Disallow directives.
Honouring all Crawl-Delay directives, including the 10-second minimum delay established by Pick n Pay.
Operating solely on public-facing URL paths and never attempting to access restricted areas (e.g., user accounts, checkout, or login interfaces)
''',
              ),
              const Text(
                'Data Scope Limitation ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                '''All data retrieved by this application is limited to public, factual information necessary for price comparison:
Factual Data Only: Extraction is restricted to product names, current prices, and stock indicators, in line with Intellectual Property clauses. Graphical assets, extensive text descriptions, and branding are excluded from the dataset.
POPIA Compliance: The system is engineered to categorically avoid the collection, storage, or processing of any Personal Identifiable Information (PII), ensuring full compliance with the Protection of Personal Information Act (POPIA).
 ''',
              ),
              const Text(
                'Data Accuracy and Liability Disclaimer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                '''The pricing data presented is a snapshot derived from a specific, compliant scrape window. Users acknowledge the following limitations:
Non-Real-Time Data: Prices, availability, and promotional details may change on the retailer's site between scraping cycles. The application does not provide real-time data.
Verification Required: Users are solely responsible for verifying the accuracy and currency of all pricing and product information directly on the respective retailer's official platform prior to purchase.
No Warranties: The application provides its data "as is" and disclaims all liability for any purchasing decisions, financial loss, or contractual issues arising from the use of its data.
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
