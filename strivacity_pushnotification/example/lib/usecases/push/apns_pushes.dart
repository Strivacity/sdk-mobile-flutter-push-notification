import 'dart:io';

import 'package:flutter/services.dart';

/// The pushes that reach iOS straight from APNs, which the Firebase plugin ignores.
abstract final class ApnsPushes {
  // Must match `ApnsPushes` in ios/Runner/AppDelegate.swift.
  static const _channel = MethodChannel('com.strivacity.flutter.strivacity_pushnotification_example/apns_pushes');

  /// Calls [onPush] with the data of each such push: first those that arrived before this was
  /// called, then every new one. Does nothing off iOS.
  static Future<void> listen(void Function(Map<String, Object?> data) onPush) async {
    if (!Platform.isIOS) return;
    // The handler comes first: native sends live pushes from the moment it hands over the queue.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'push') onPush(_dataOf(call.arguments));
    });
    final queued = await _channel.invokeListMethod<Object?>('takeQueued') ?? const [];
    queued.map(_dataOf).forEach(onPush);
  }

  static Map<String, Object?> _dataOf(Object? arguments) =>
      Map<String, Object?>.of((arguments! as Map<Object?, Object?>).cast<String, Object?>());
}
