import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'minfo_sdk_platform_interface.dart';

/// An implementation of [MinfoSdkPlatform] that uses method channels.
class MethodChannelMinfoSdk extends MinfoSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('minfo_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
