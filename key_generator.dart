import 'package:flutter/material.dart';
import 'package:minfo_sdk/src/minfo_auth.dart';

void main() {
  runApp(KeyGeneratorApp());
}

class KeyGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minfo Key Generator',
      home: KeyGeneratorPage(),
    );
  }
}

class KeyGeneratorPage extends StatefulWidget {
  @override
  _KeyGeneratorPageState createState() => _KeyGeneratorPageState();
}

class _KeyGeneratorPageState extends State<KeyGeneratorPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController(text: 'http://localhost:8000');
  
  String _status = 'Entrez vos identifiants';
  String _publicKey = '';
  String _privateKey = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Générateur de Clés API Minfo')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(labelText: 'URL Serveur'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateKeys,
              child: _isLoading 
                ? CircularProgressIndicator() 
                : Text('Générer les Clés API'),
            ),
            SizedBox(height: 20),
            Text(_status, style: TextStyle(fontWeight: FontWeight.bold)),
            if (_publicKey.isNotEmpty) ...[
              SizedBox(height: 20),
              SelectableText('Public Key:\n$_publicKey'),
              SizedBox(height: 10),
              SelectableText('Private Key:\n$_privateKey'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _copyConfig,
                child: Text('Copier la Configuration'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateKeys() async {
    setState(() {
      _isLoading = true;
      _status = 'Génération en cours...';
    });

    final auth = MinfoAuth(baseUrl: _urlController.text);
    final keys = await auth.getApiKeys(
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
      if (keys != null) {
        _publicKey = keys['public_key']!;
        _privateKey = keys['private_key']!;
        _status = '✅ Clés générées avec succès!';
      } else {
        _status = '❌ Échec de la génération';
      }
    });
  }

  void _copyConfig() {
    final config = '''
class MinfoConfig {
  static const String PUBLIC_KEY = "$_publicKey";
  static const String PRIVATE_KEY = "$_privateKey";
  static const String BASE_URL = "${_urlController.text}";
}''';
    
    // Copier dans le presse-papier (nécessite clipboard package)
    print('Configuration à copier dans minfo_config.dart:');
    print(config);
  }
}
