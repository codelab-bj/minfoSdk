// minfo_sdk.dart
// Minfo SDK v2.3.0
// Copyright (c) Minfo Limited. All rights reserved.

library minfo_sdk;

// ========================================
// AudioQR (EXISTANT)
// ========================================
export 'src/minfo_sdk.dart' ;

export 'src/models.dart';
export 'src/audio_qr_engine.dart';


// ========================================
// Utils (réexportés pour utilisation externe si besoin)
// ========================================
export 'src/utils.dart' show MinfoLogger, LogLevel;

import 'minfo_sdk_platform_interface.dart';
class MinfoSdk{
  Future<String?> getPlatformVersion() {
    return MinfoSdkPlatform.instance.getPlatformVersion();
  }
}