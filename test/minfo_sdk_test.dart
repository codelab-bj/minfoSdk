import 'package:flutter_test/flutter_test.dart';
import 'package:minfo_sdk/minfo_sdk.dart';
import 'package:minfo_sdk/minfo_sdk_platform_interface.dart';
import 'package:minfo_sdk/minfo_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMinfoSdkPlatform
    with MockPlatformInterfaceMixin
    implements MinfoSdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MinfoSdkPlatform initialPlatform = MinfoSdkPlatform.instance;

  test('$MethodChannelMinfoSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMinfoSdk>());
  });

  test('getPlatformVersion', () async {
    MinfoSdk minfoSdkPlugin = MinfoSdk.instance;
    MockMinfoSdkPlatform fakePlatform = MockMinfoSdkPlatform();
    MinfoSdkPlatform.instance = fakePlatform;

    //expect(await minfoSdkPlugin.getPlatformVersion(), '42');
  });
}
