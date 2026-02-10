import 'dart:async'; // Ajouté pour StreamSubscription
import 'package:flutter/material.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/audio_session_manager.dart'; // Vérifie le chemin exact
import 'dart:developer' as developer;

class MinfoDetectionButton extends StatefulWidget {
  const MinfoDetectionButton({super.key}); // Ajouté pour les bonnes pratiques

  @override
  State<MinfoDetectionButton> createState() => _MinfoDetectionButtonState();
}

class _MinfoDetectionButtonState extends State<MinfoDetectionButton> {
  bool _isDetecting = false;
  String _status = "Prêt";
  StreamSubscription<String>? _subscription; // Pour gérer la mémoire

  @override
  void dispose() {
    _subscription?.cancel(); // Arrête l'écoute du flux
    MinfoSdk.instance.stop(); // Arrête le moteur audio
    super.dispose();
  }

  Future<void> _startDetection() async {
    setState(() {
      _isDetecting = true;
      _status = "Configuration audio...";
    });

    try {
      // Configuration via le manager
      final success = await MinfoDetectionManager.startDetectionWithProperSetup();

      if (success) {
        setState(() {
          _status = "🎧 Écoute en cours...";
        });

        // Nettoyer l'ancienne souscription si elle existe
        await _subscription?.cancel();

        // Écouter les résultats de manière propre
        _subscription = MinfoSdk.instance.soundcodeStream.listen(
              (soundcode) {
            developer.log('🎯 Soundcode reçu: $soundcode');
            if (mounted) { // Vérifie si le widget est toujours affiché
              setState(() {
                _status = "✅ Signal détecté: $soundcode";
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _status = "❌ Erreur flux: $error";
                _isDetecting = false;
              });
            }
          },
        );

      } else {
        setState(() {
          _status = "❌ Permissions refusées";
          _isDetecting = false;
        });
      }
    } catch (e) {
      developer.log('❌ Erreur: $e');
      if (mounted) {
        setState(() {
          _status = "❌ Erreur: $e";
          _isDetecting = false;
        });
      }
    }
  }

  Future<void> _stopDetection() async {
    try {
      await _subscription?.cancel(); // Stop l'écoute Dart
      await MinfoSdk.instance.arreter(); // Stop le moteur Natif
      if (mounted) {
        setState(() {
          _isDetecting = false;
          _status = "Arrêté";
        });
      }
    } catch (e) {
      developer.log('❌ Erreur arrêt: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Plus propre pour l'intégration
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isDetecting ? Icons.mic : Icons.mic_off,
          color: _isDetecting ? Colors.red : Colors.grey,
          size: 48,
        ),
        const SizedBox(height: 10),
        Text(
          _status,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDetecting ? Colors.red : Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: _isDetecting ? _stopDetection : _startDetection,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(_isDetecting ? "Arrêter" : "Démarrer détection"),
          ),
        ),
      ],
    );
  }
}