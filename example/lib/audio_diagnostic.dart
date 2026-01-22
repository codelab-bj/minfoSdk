// audio_diagnostic.dart - Diagnostic complet du moteur audio
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioDiagnostic extends StatefulWidget {
  @override
  _AudioDiagnosticState createState() => _AudioDiagnosticState();
}

class _AudioDiagnosticState extends State<AudioDiagnostic> {
  static const platform = MethodChannel('com.minfo_sdk/audioqr');
  
  List<String> _logs = [];
  bool _isListening = false;
  
  @override
  void initState() {
    super.initState();
    
    // Écouter les signaux natifs
    platform.setMethodCallHandler((call) async {
      _addLog("📡 SIGNAL NATIF: ${call.method} - ${call.arguments}");
      
      if (call.method == "onSignalDetected") {
        final type = call.arguments["type"] ?? "Inconnu";
        final codes = call.arguments["codes"] ?? "";
        _addLog("🎯 DÉTECTION: $type | Codes: $codes");
      }
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, "${DateTime.now().toString().substring(11, 19)} - $message");
      if (_logs.length > 50) _logs.removeLast();
    });
    debugPrint(message);
  }

  Future<void> _testPermissions() async {
    _addLog("🔐 Test des permissions...");
    
    final micStatus = await Permission.microphone.status;
    _addLog("🎤 Microphone: $micStatus");
    
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      _addLog("🎤 Demande permission: $result");
    }
  }

  Future<void> _testNativeEngine() async {
    _addLog("⚙️ Test du moteur natif...");
    
    try {
      final result = await platform.invokeMethod('initialise');
      _addLog("✅ Initialisation: $result");
    } catch (e) {
      _addLog("❌ Erreur initialisation: $e");
    }
  }

  Future<void> _startRawDetection() async {
    if (_isListening) {
      _stopRawDetection();
      return;
    }
    
    _addLog("🚀 Démarrage détection brute...");
    setState(() => _isListening = true);
    
    try {
      // Appel direct au moteur Kotlin
      final result = await platform.invokeMethod('startDetection');
      _addLog("🎯 Résultat détection: $result");
    } catch (e) {
      _addLog("❌ Erreur détection: $e");
    } finally {
      setState(() => _isListening = false);
    }
  }

  void _stopRawDetection() {
    _addLog("⏹️ Arrêt détection...");
    platform.invokeMethod('stopDetection');
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diagnostic Audio Minfo'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Boutons de test
          Padding(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testPermissions,
                  child: Text('Test Permissions'),
                ),
                ElevatedButton(
                  onPressed: _testNativeEngine,
                  child: Text('Test Moteur'),
                ),
                ElevatedButton(
                  onPressed: _startRawDetection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red : Colors.green,
                  ),
                  child: Text(_isListening ? 'STOP' : 'Détecter'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _logs.clear()),
                  child: Text('Clear'),
                ),
              ],
            ),
          ),
          
          // Logs en temps réel
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color color = Colors.white;
                  
                  if (log.contains('❌')) color = Colors.red;
                  else if (log.contains('✅')) color = Colors.green;
                  else if (log.contains('🎯')) color = Colors.orange;
                  else if (log.contains('📡')) color = Colors.blue;
                  
                  return Text(
                    log,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
