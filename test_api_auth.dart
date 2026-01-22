 import 'package:flutter/material.dart';
import 'package:minfo_sdk/minfo_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test API Auth',
      home: TestApiAuth(),
    );
  }
}

class TestApiAuth extends StatefulWidget {
  @override
  _TestApiAuthState createState() => _TestApiAuthState();
}

class _TestApiAuthState extends State<TestApiAuth> {
  String status = "Non initialisé";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test API Auth')),
      body: Column(
        children: [
          Text('Status: $status'),
          ElevatedButton(
            onPressed: testJwtAuth,
            child: Text('Test JWT Auth'),
          ),
          ElevatedButton(
            onPressed: testApiKeysAuth,
            child: Text('Test API Keys Auth'),
          ),
          ElevatedButton(
            onPressed: testGenerateKeys,
            child: Text('Generate API Keys'),
          ),
        ],
      ),
    );
  }

  Future<void> testJwtAuth() async {
    try {
      await MinfoSdk.instance.init(
        clientId: "test_client",
        apiKey: "test_jwt_token",
      );
      setState(() => status = "JWT Auth OK");
    } catch (e) {
      setState(() => status = "JWT Auth Error: $e");
    }
  }

  Future<void> testApiKeysAuth() async {
    try {
      await MinfoSdk.instance.init(
        clientId: "test_client",
        publicKey: "test_public_key_64_chars",
        privateKey: "test_private_key_64_chars",
      );
      setState(() => status = "API Keys Auth OK");
    } catch (e) {
      setState(() => status = "API Keys Auth Error: $e");
    }
  }

  Future<void> testGenerateKeys() async {
    try {
      bool success = await MinfoSdk.instance.generateApiKeys();
      setState(() => status = success ? "Keys Generated" : "Generation Failed");
    } catch (e) {
      setState(() => status = "Generation Error: $e");
    }
  }
}
