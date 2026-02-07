import 'package:flutter/material.dart';
import 'package:minfo_sdk/minfo_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation globale
  await MinfoSdk.initialize(
    publicApiKey: "356489b34cc9f8662add531971e95256af8b332d9cc9ef4b76fca4a8971bd0c1",
    privateApiKey: "18811688785c60de5cded378d3a1a7d0efdc21e2e1594ba569fb62347fb08c1a",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minfo SDK Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MinfoPage(),
    );
  }
}

// AJOUT : La classe StatefulWidget qui manquait
class MinfoPage extends StatefulWidget {
  const MinfoPage({super.key});

  @override
  State<MinfoPage> createState() => _MinfoPageState();
}

class _MinfoPageState extends State<MinfoPage> {
  String _status = "Prêt à scanner";
  bool _isScanning = false;

  void _startMinfo() {
    setState(() {
      _status = "Écoute active...";
      _isScanning = true;
    });

    // On appelle startScan qui gère les permissions ET le démarrage
    MinfoSdk.instance.startScan(
      onResult: (campaign) {
        setState(() {
          _status = "Trouvé : ${campaign.name}";
          _isScanning = false;
        });
        _showMyDialog(campaign);
      },
      onError: (err) {
        setState(() {
          _status = "Erreur : $err";
          _isScanning = false;
        });
      },
    );
  }

  void _showMyDialog(CampaignResult result) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force l'utilisateur à cliquer sur OK
      builder: (ctx) => AlertDialog(
        title: Text(result.name ?? "Campagne détectée"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Image.network(result.image!, height: 100),
              ),
            Text(result.campaignDescription ?? "Aucune description disponible."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    MinfoSdk.instance.stop(); // Sécurité : on coupe le micro si on quitte la page
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Minfo Demo")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Un petit indicateur visuel
            Icon(
              _isScanning ? Icons.mic : Icons.mic_none,
              size: 80,
              color: _isScanning ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _startMinfo,
              icon: const Icon(Icons.search),
              label: Text(_isScanning ? "RECHERCHE..." : "DÉMARRER LE SCAN"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}