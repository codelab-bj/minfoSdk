import 'dart:async'; // Ajouté pour StreamSubscription
import 'package:flutter/material.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/audio_session_manager.dart';
import 'dart:developer' as developer;

class MinfoTestWidget extends StatefulWidget {
  const MinfoTestWidget({super.key}); // Ajout du const constructeur

  @override
  State<MinfoTestWidget> createState() => _MinfoTestWidgetState();
}

class _MinfoTestWidgetState extends State<MinfoTestWidget> {
  String _status = "Prêt pour test";
  bool _isDetecting = false;
  StreamSubscription<String>? _subscription; // Pour nettoyer le flux

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _testMinfoEngine() async {
    if (!mounted) return;

    setState(() {
      _status = "Test du moteur Minfo...";
    });

    try {
      developer.log('🧪 Test initialisation moteur...');
      final engineInitialized = await MinfoSdk.instance.audioEngine.initialise();

      if (!engineInitialized) {
        if (mounted) setState(() => _status = "❌ Moteur non initialisé");
        return;
      }

      developer.log('🧪 Test permissions + session audio...');
      final hasAccess = await AudioSessionManager.requestMicrophoneWithAudioSession();

      if (!hasAccess) {
        if (mounted) setState(() => _status = "❌ Pas d'accès audio");
        return;
      }

      if (mounted) {
        setState(() {
          _status = "🎧 Test détection en cours...";
          _isDetecting = true;
        });
      }

      MinfoSdk.instance.configureListener();

      // Annuler l'ancienne souscription si elle existe
      await _subscription?.cancel();

      _subscription = MinfoSdk.instance.soundcodeStream.listen((soundcode) {
        developer.log('🧪 🎯 Signal détecté: $soundcode');
        if (mounted) {
          setState(() {
            _status = "✅ Signal détecté: $soundcode";
            _isDetecting = false;
          });
        }
      });

      await MinfoSdk.instance.audioEngine.startDetection();

      // Timeout automatique
      Future.delayed(const Duration(seconds: 30), () {
        if (_isDetecting && mounted) {
          setState(() {
            _status = "⏰ Timeout - Aucun signal";
            _isDetecting = false;
          });
        }
      });

    } catch (e) {
      developer.log('🧪 ❌ Erreur test: $e');
      if (mounted) {
        setState(() {
          _status = "❌ Erreur: $e";
          _isDetecting = false;
        });
      }
    }
  }

  Future<void> _stopTest() async {
    try {
      await MinfoSdk.instance.arreter();
      if (mounted) {
        setState(() {
          _status = "Test arrêté";
          _isDetecting = false;
        });
      }
    } catch (e) {
      developer.log('🧪 ❌ Erreur arrêt: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Test Moteur Minfo",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Text( // Suppression du const ici car _status est variable
          _status,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isDetecting ? _stopTest : _testMinfoEngine,
          child: Text(_isDetecting ? "Arrêter Test" : "Tester Moteur"),
        ),
      ],
    );
  }
}