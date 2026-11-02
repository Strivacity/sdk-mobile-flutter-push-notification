import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The system launch screen.
abstract final class NativeSplashChannel {
  static const _channel = MethodChannel(
    'strivacity_pushnotification_example/splash',
  );

  // Without a system splash screen to remove (a warm start, say), Android never says it is gone.
  static const _giveUpAfter = Duration(seconds: 1);

  /// Completes once the system splash is gone; at once without one, or after a timeout.
  static Future<void> untilGone() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('untilSplashGone').timeout(_giveUpAfter);
    } on Object {
      // Show the screen
    }
  }
}
