import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}
//simulation
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minfo SDK Example (MOCK)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MinfoExamplePage(),
    );
  }
}

class MinfoExamplePage extends StatefulWidget {
  const MinfoExamplePage({super.key});

  @override
  State<MinfoExamplePage> createState() => _MinfoExamplePageState();
}

class _MinfoExamplePageState extends State<MinfoExamplePage> {
  bool _isAuthorized = true;
  String? _campaignUrl;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    print('🎭 [MOCK] App initialized');
  }

  /// Fonction MOCKÉE pour simuler un connect request
  Future<void> _performConnect() async {
    setState(() => _isConnecting = true);

    try {
      print('🎭 [MOCK] Starting Connect request...');

      // Simuler la collecte du DeviceContext
      await Future.delayed(const Duration(milliseconds: 300));
      print('🎭 [MOCK] DeviceContext: {osVersion: Android 13, deviceModel: Infinix X6528}');

      // Simuler la préparation de la requête
      await Future.delayed(const Duration(milliseconds: 200));
      print('🎭 [MOCK] ConnectRequest prepared');

      // Simuler la détection AudioQR
      print('🎭 [MOCK] 🎤 Detecting AudioQR signal...');
      await Future.delayed(const Duration(seconds: 2));
      print('🎭 [MOCK] 📡 Signal detected!');

      // Simuler l'appel API
      print('🎭 [MOCK] 🌐 Calling /v1/connect...');
      await Future.delayed(const Duration(milliseconds: 800));

      // MOCK: Simuler une réponse "allow" avec URL de campagne
      final mockResponse = {
        'outcome': 'allow',
        'requestId': 'mock-${DateTime.now().millisecondsSinceEpoch}',
        'payload': {
          'url': 'https://app.minfo.com'
        },
        'message': 'Connect successful (MOCK)',
      };

      print('🎭 [MOCK] ✅ Connect success!');
      print('🎭 [MOCK] Outcome: allow');
      print('🎭 [MOCK] Payload: ${mockResponse['payload']}');

      // Extraire l'URL et ouvrir la campagne
      final url = (mockResponse['payload'] as Map)['url'] as String;

      setState(() {
        _campaignUrl = url;
        _isConnecting = false;
      });

      _openMinfoCampaign(url);

    } catch (e, stackTrace) {
      print('🎭 [MOCK] ❌ Exception: $e');
      print('🎭 [MOCK] StackTrace: $stackTrace');

      setState(() => _isConnecting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exception: $e')),
        );
      }
    }
  }

  void _openMinfoCampaign(String url) {
    print('🎭 [MOCK] 🌐 Opening campaign: $url');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MockMinfoWebView(campaignUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minfo SDK (MOCK)'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isAuthorized
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.campaign,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Minfo SDK Example',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '🎭 MOCK MODE',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            if (_isConnecting)
              Column(
                children: const [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Detecting AudioQR signal...'),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _performConnect,
                icon: const Icon(Icons.mic),
                label: const Text('Start Audio Connect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),

            const SizedBox(height: 24),

            if (_campaignUrl != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Last campaign URL:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _campaignUrl!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        )
            : _buildUnauthorizedView(),
      ),
    );
  }

  Widget _buildUnauthorizedView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.error_outline, size: 64, color: Colors.orange),
          SizedBox(height: 24),
          Text(
            'Access Denied',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Mock WebView pour afficher la campagne
class MockMinfoWebView extends StatelessWidget {
  final String campaignUrl;

  const MockMinfoWebView({
    Key? key,
    required this.campaignUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign (MOCK)'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.web,
                size: 100,
                color: Colors.orange,
              ),
              const SizedBox(height: 32),
              const Text(
                '🎭 MOCK Campaign View',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This is where the real MinfoWebView would display the campaign.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Campaign URL:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      campaignUrl,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Simuler un contenu de campagne
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'content',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎭 MOCK: Button clicked!'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          'clic here',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}