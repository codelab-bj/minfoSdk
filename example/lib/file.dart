import 'package:flutter/material.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/minfo_web_view.dart';
import 'package:minfo_sdk/src/utils.dart' show ApiResult, MinfoAPIClient;
import 'package:minfo_sdk/src/models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minfo SDK Example',
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
  late final MinfoAPIClient _apiClient;

  bool _isAuthorized = true;
  String? _campaignUrl;

  @override
  void initState() {
    super.initState();

    // Initialisation du client API
    _apiClient = MinfoAPIClient(
      clientId: 'YOUR_CLIENT_ID',
      apiKey: 'YOUR_API_KEY',
      sdkVersion: '2.3.0',
      baseUrl: 'https://c4.minfo.com',
    );
  }

  /// Fonction pour lancer un connect request
  Future<void> _performConnect() async {
    try {
      print('[MINFO] Starting Connect request...');
      final deviceContext = await DeviceContext.current();
      print('[MINFO] DeviceContext: ${deviceContext.toJson()}');

      final request = ConnectRequest(
        requestingClientType: ClientType.sdkClient,
        requestingClientId: 'YOUR_CLIENT_ID',
        audioSignature: 'SIMULATED_AUDIO_SIGNATURE',
        deviceContext: deviceContext,
        sdkVersion: '2.3.0',
        engineVersion: '1.0.0-stub',
        supportedContentTypes: [ContentType.webUrl],
        activeFeatureFlags: ['audioqr_enabled'],
      );
      print('[MINFO] ConnectRequest prepared: ${request.toJson()}');

      final ApiResult<ConnectResponse> result = await _apiClient.connect(request);

      result.when(
        success: (connectResponse) {
          print('[MINFO] Connect success!');
          print('[MINFO] Outcome: ${connectResponse.outcome}');
          print('[MINFO] Payload: ${connectResponse.payload}');
          print('[MINFO] Message: ${connectResponse.message}');

          if (connectResponse.outcome == Outcome.allow &&
              connectResponse.payload?['url'] != null) {
            setState(() {
              _campaignUrl = connectResponse.payload!['url'] as String;
            });
            _openMinfoCampaign(_campaignUrl!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Outcome: ${connectResponse.outcome}, no URL')),
            );
          }
        },
        failure: (error) {
          print('[MINFO] Connect failed: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connect failed: $error')),
          );
        },
      );
    } catch (e, stackTrace) {
      print('[MINFO][EXCEPTION] $e');
      print('[MINFO][STACKTRACE] $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    }
  }



  void _openMinfoCampaign(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MinfoWebView(campaignUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isAuthorized
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Minfo SDK Example',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _performConnect,
              icon: const Icon(Icons.mic),
              label: const Text('Start Audio Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          Text('Access Denied',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

