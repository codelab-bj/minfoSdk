import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'minfo_sdk_method_channel.dart';

abstract class MinfoSdkPlatform extends PlatformInterface {
  /// Constructs a MinfoSdkPlatform.
  MinfoSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static MinfoSdkPlatform _instance = MethodChannelMinfoSdk();

  /// The default instance of [MinfoSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelMinfoSdk].
  static MinfoSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MinfoSdkPlatform] when
  /// they register themselves.
  static set instance(MinfoSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() ;

}
