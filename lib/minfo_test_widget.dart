import 'package:flutter/material.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/audio_session_manager.dart';
import 'dart:developer' as developer;

class MinfoTestWidget extends StatefulWidget {
  @override
  _MinfoTestWidgetState createState() => _MinfoTestWidgetState();
}

class _MinfoTestWidgetState extends State<MinfoTestWidget> {
  String _status = "Prêt pour test";
  bool _isDetecting = false;

  Future<void> _testMinfoEngine() async {
    setState(() {
      _status = "Test du moteur Minfo...";
    });

    try {
      // 1. Test initialisation
      developer.log('🧪 Test initialisation moteur...');
      final engineInitialized = await MinfoSdk.instance.audioEngine.initialise();
      
      if (!engineInitialized) {
        setState(() {
          _status = "❌ Moteur non initialisé";
        });
        return;
      }

      developer.log('🧪 ✅ Moteur initialisé');
      
      // 2. Test permissions + audio
      developer.log('🧪 Test permissions + session audio...');
      final hasAccess = await AudioSessionManager.requestMicrophoneWithAudioSession();
      
      if (!hasAccess) {
        setState(() {
          _status = "❌ Pas d'accès audio";
        });
        return;
      }

      developer.log('🧪 ✅ Accès audio OK');
      
      // 3. Test détection
      setState(() {
        _status = "🎧 Test détection en cours...";
        _isDetecting = true;
      });

      // Configurer listener
      MinfoSdk.instance.configureListener();
      
      // Écouter les résultats
      MinfoSdk.instance.soundcodeStream.listen((soundcode) {
        developer.log('🧪 🎯 Signal détecté: $soundcode');
        setState(() {
          _status = "✅ Signal détecté: $soundcode";
          _isDetecting = false;
        });
      });

      // Démarrer détection
      await MinfoSdk.instance.audioEngine.startDetection();
      
      developer.log('🧪 ✅ Détection démarrée - Jouez un son Minfo');
      
      // Timeout après 30 secondes
      Future.delayed(Duration(seconds: 30), () {
        if (_isDetecting) {
          setState(() {
            _status = "⏰ Timeout - Aucun signal détecté";
            _isDetecting = false;
          });
        }
      });

    } catch (e) {
      developer.log('🧪 ❌ Erreur test: $e');
      setState(() {
        _status = "❌ Erreur: $e";
        _isDetecting = false;
      });
    }
  }

  Future<void> _stopTest() async {
    try {
      await MinfoSdk.instance.arreter();
      setState(() {
        _status = "Test arrêté";
        _isDetecting = false;
      });
    } catch (e) {
      developer.log('🧪 ❌ Erreur arrêt: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Test Moteur Minfo",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Text(
          _status,
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isDetecting ? _stopTest : _testMinfoEngine,
          child: Text(_isDetecting ? "Arrêter Test" : "Tester Moteur"),
        ),
      ],
    );
  }
}
