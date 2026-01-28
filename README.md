# Minfo_sdk

Multi-platform SDK for AudioQR-powered engagement. Connect users to campaigns via inaudible audio watermarks embedded in TV, radio, cinema, and physical spaces.

## 1. Features
The SDK handles the complete AudioQR "connection" process:

1. **Activation**: The SDK activates the microphone and listens for **audible** signals (TV/Radio).
2. **Decoding**: The **Cifrasoft** engine processes the signal in real-time.
3. **Resolution**: The SDK queries Minfo servers to retrieve the associated campaign.
4. **Display**: Content opens automatically in an integrated WebView.

## 2. Step-by-Step Implementation

### Flutter (Your Platform)
1. **Add** the SDK as a local dependency in `pubspec.yaml`

2. **Configurations**:
   
   **Android** - configured in your `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
   ```
   
   **iOS** - configured in your `Info.plist`:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>We need microphone access to detect AudioQR signals.</string>
   ```

3. **Install** dependencies: `flutter pub get`

4. **Initialize** in `main.dart`:
   ```dart
   import 'package:minfo_sdk/minfo_sdk.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     await MinfoSdk.instance.init(
        publicKey: MinfoKeys.publicKey,                                                                                                                                                         
        privateKey: MinfoKeys.privateKey,  
     );
     
     runApp(MyApp());
   }
   ```

5. **Start** detection:
```dart
// Launches capture interface and returns campaign result
try {
  final result = await MinfoSdk.instance.audioEngine.startDetection();
  print("Campaign detected: ${result.campaignName}");
} catch (e) {
  print("Error: $e");
}
```

## 3. Architecture Overview

The SDK relies on communication between Flutter and native engines:

1. **Flutter** requests startup
2. **Native Engines (Cifrasoft)** analyze audio stream
3. **Minfo API** validates signal and returns campaign URL

## 4. Complete Example
A complete implementation example with state management and UI is available in the /example folder of this repository.

## 5. License

This SDK uses proprietary Cifrasoft libraries. See the LICENSE file for more details.
