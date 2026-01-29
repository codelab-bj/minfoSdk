# Minfo_sdk

Multi-platform SDK for AudioQR-powered engagement. Connect users to campaigns via inaudible audio watermarks embedded in TV, radio, cinema, and physical spaces.

## 1. Features
The SDK handles the complete AudioQR "connection" process:

1. **Activation**: The SDK activates the microphone and listens for **audible** signals (TV/Radio).
2. **Decoding**: The **Cifrasoft** engine processes the signal in real-time.
3. **Resolution**: The SDK queries Minfo servers to retrieve the associated campaign data.
4. **Control**: You manage your own UI and user experience.

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
     
     await MinfoSdk.initialize(publicApiKey: 'your_public_key');
     
     runApp(MyApp());
   }
   ```

5. **Listen for campaigns**:
```dart
// Listen to campaign detections
MinfoSdk.instance.campaignStream?.listen((result) {
  if (result.isSuccess) {
    print('Campaign: ${result.campaignName}');
    print('URL: ${result.campaignUrl}');
    print('Description: ${result.campaignDescription}');
    
    // Handle your own UI
    showCampaignDialog(result);
    // or navigate to campaign page
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CampaignPage(campaign: result)
    ));
  } else {
    print('Error: ${result.error}');
  }
});

// Control listening
await MinfoSdk.instance.listen();  // Start listening
await MinfoSdk.instance.pause();   // Pause listening  
await MinfoSdk.instance.listen();  // Resume listening
await MinfoSdk.instance.stop();    // Stop completely
```

## 3. Campaign Data Structure

When a campaign is detected, you receive a `CampaignResult` object with:

```dart
class CampaignResult {
  final int audioId;              // Detected audio ID
  final String? campaignUrl;      // Campaign URL
  final String? campaignName;     // Campaign name
  final String? campaignDescription; // Campaign description
  final String? campaignImage;    // Campaign image URL
  final Map<String, dynamic>? campaignData; // Full campaign data
  final Map<String, dynamic>? metadata;     // Additional metadata
  final DateTime timestamp;       // Detection timestamp
  final String? error;           // Error message if any
  
  bool get isSuccess;            // True if campaign found
  bool get hasError;             // True if error occurred
}
```

## 4. Architecture Overview

The SDK relies on communication between Flutter and native engines:

1. **Flutter** requests startup with `listen()`
2. **Native Engines (Cifrasoft)** analyze audio stream
3. **Minfo API** validates signal and returns campaign data
4. **Your App** receives `CampaignResult` via stream and handles UI

## 5. Complete Example
A complete implementation example with state management and UI is available in the /example folder of this repository.

## 6. License

This SDK uses proprietary Cifrasoft libraries. See the LICENSE file for more details.
