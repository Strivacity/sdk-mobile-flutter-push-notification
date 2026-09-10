import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'strivacity_pushnotification_platform_interface.dart';

/// An implementation of [StrivacityPushnotificationPlatform] that uses method channels.
class MethodChannelStrivacityPushnotification extends StrivacityPushnotificationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('strivacity_pushnotification');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
