import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification_method_channel.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification_platform_interface.dart';

class MockStrivacityPushnotificationPlatform
    with MockPlatformInterfaceMixin
    implements StrivacityPushnotificationPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final initialPlatform = StrivacityPushnotificationPlatform.instance;

  test('$MethodChannelStrivacityPushnotification is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelStrivacityPushnotification>());
  });

  test('getPlatformVersion', () async {
    final strivacityPushnotificationPlugin = StrivacityPushnotification();
    final fakePlatform = MockStrivacityPushnotificationPlatform();
    StrivacityPushnotificationPlatform.instance = fakePlatform;

    expect(await strivacityPushnotificationPlugin.getPlatformVersion(), '42');
  });
}
