import 'strivacity_pushnotification_platform_interface.dart';

/// Entry point of the Strivacity push notification plugin.
class StrivacityPushnotification {
  /// Returns the version of the underlying platform, or `null` when the
  /// platform did not report one.
  Future<String?> getPlatformVersion() =>
      StrivacityPushnotificationPlatform.instance.getPlatformVersion();
}
