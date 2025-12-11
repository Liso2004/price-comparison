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
                '''Disclaimer: ShopWise we, us, or our mobile application's content is only intended for general informational reasons. We provide all of the information on our mobile application in good faith, but we make no express or implied representations or warranties about its correctness, sufficiency, validity, dependability, availability, or completeness. Under no circumstances will we be liable to you for any loss or damage of any kind that results from using our mobile application or relying on any information it provides. It is entirely your responsibility to use our mobile application and to rely on any information found on it.
''',
              ),
              const Text(
                'EXTERNAL LINKS DISCLAIMER ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                '''External Links Disclaimer: Our mobile application may include (or send you through it) links to other websites or information that is owned by or originates from third parties, as well as links to websites and features in banners or other forms of advertising. We do not investiage, monitor, or verify these external links for correctness, sufficiency, validity, dependability, accessibility, or completeness. The accuracy and dependability of any information provided by third-party websites linked through the website, as well as any website or feature included in any banner or other advertising, are not warranted, endorsed, guaranteed, or assumed by us. We will not monitor any transactions between you and third-party suppliers of goods or services, nor will we be involved in any way.
''',
              ),
              const Text(
                'Cybercrime Act:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                '''This application's data collecting methodology is rigorously designed to work inside the technological parameters established by the target retail websites, notably the robots.txt protocol. This includes:
Strict adherence to all Disallow orders.
Honoring all Crawl-Delay directives, including Pick n Pay's 10-second minimum delay.
Operating only on public-facing URL pathways and never attempting to access privileged regions (such as user accounts, checkout, or login interfaces).''',
              ),
              const Text(
                'Data scope limitation:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                ''' All data retrieved by this application is confined to public, factual information required for pricing comparison.
Factual Data Only: Extraction is limited to product names, current prices, and stock indicators, in accordance with Intellectual Property restrictions. The dataset excludes graphic assets, detailed language descriptions, and branding.
POPIA Compliance: The system is designed to completely avoid collecting, storing, or processing any personally identifiable information (PII), assuring full compliance with the Protection of Personal Information Act (POPIA).''',
              ),
              const Text(
                'Data Accuracy and Liability Disclaimer:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                ''' The pricing information shown is a snapshot obtained from a specified, compliant scrape window. Users understand the following limitations:
Non-Real Time Data: Prices, availability, and promotional information may change on the retailer's website between scraping rounds. The app does not provide real-time information.
Verification Required: Users are completely responsible for validating the accuracy and currency of all price and product information directly on the respective retailer's official platform before making a purchase.
No warranties: The program delivers its data in its current form and expressly disclaims any obligation for any purchasing decisions, financial loss, or contractual issues resulting from its use.
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
