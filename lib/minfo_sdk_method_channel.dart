// 1. Définis le canal avec le nom EXACT utilisé dans ton Swift
final methodChannel = const MethodChannel('com.gzone.campaign/audioCapture');

// 2. Dans le constructeur, écoute les messages du natif
MethodChannelMinfoSdk() {
  methodChannel.setMethodCallHandler((call) async {
    if (call.method == "onDetectedId") {
      final List<dynamic> args = call.arguments;
      final int id = args[1]; // C'est le fameux 2394

      // SI TU VOIS CE PRINT, TU AS GAGNÉ !
      debugPrint("🚀 VICTOIRE : Flutter a reçu l'ID $id");

      // Ici, tu devras appeler ton API pour afficher la campagne
      // _maFonctionAffichage(id);
    }
  });
}