import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'strivacity_pushnotification_method_channel.dart';

/// The interface that platform-specific implementations of the Strivacity
/// push notification plugin must extend.
///
/// Platform implementations should extend this class rather than implement it,
/// so that new methods added here do not break existing implementations.
abstract class StrivacityPushnotificationPlatform extends PlatformInterface {
  /// Constructs a StrivacityPushnotificationPlatform.
  StrivacityPushnotificationPlatform() : super(token: _token);

  static final Object _token = Object();

  static StrivacityPushnotificationPlatform _instance = MethodChannelStrivacityPushnotification();

  /// The default instance of [StrivacityPushnotificationPlatform] to use.
  ///
  /// Defaults to [MethodChannelStrivacityPushnotification].
  static StrivacityPushnotificationPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [StrivacityPushnotificationPlatform] when
  /// they register themselves.
  static set instance(StrivacityPushnotificationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the version of the underlying platform, or `null` when the
  /// platform did not report one.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
