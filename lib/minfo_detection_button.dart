import 'package:flutter/material.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/audio_session_manager.dart';
import 'dart:developer' as developer;

class MinfoDetectionButton extends StatefulWidget {
  @override
  _MinfoDetectionButtonState createState() => _MinfoDetectionButtonState();
}

class _MinfoDetectionButtonState extends State<MinfoDetectionButton> {
  bool _isDetecting = false;
  String _status = "Prêt";

  Future<void> _startDetection() async {
    setState(() {
      _isDetecting = true;
      _status = "Configuration audio...";
    });

    try {
      // Utiliser le manager avec la séquence correcte
      final success = await MinfoDetectionManager.startDetectionWithProperSetup();
      
      if (success) {
        setState(() {
          _status = "🎧 Écoute en cours...";
        });
        
        // Écouter les résultats
        MinfoSdk.instance.soundcodeStream?.listen((soundcode) {
          developer.log('🎯 Soundcode reçu: $soundcode');
          setState(() {
            _status = "✅ Signal détecté: $soundcode";
          });
        });
        
      } else {
        setState(() {
          _status = "❌ Permissions nécessaires refusées";
          _isDetecting = false;
        });
      }
    } catch (e) {
      developer.log('❌ Erreur: $e');
      setState(() {
        _status = "❌ Erreur: $e";
        _isDetecting = false;
      });
    }
  }

  Future<void> _stopDetection() async {
    try {
      await MinfoSdk.instance.arreter();
      setState(() {
        _isDetecting = false;
        _status = "Arrêté";
      });
    } catch (e) {
      developer.log('❌ Erreur arrêt: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _status,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isDetecting ? _stopDetection : _startDetection,
          child: Text(_isDetecting ? "Arrêter" : "Démarrer détection"),
        ),
      ],
    );
  }
}
