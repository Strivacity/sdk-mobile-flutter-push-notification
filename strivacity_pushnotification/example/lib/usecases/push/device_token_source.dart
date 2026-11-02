import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:signals_core/signals_core.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import '../../config.dart';
import '../report_device_token.dart';

/// How often, and for how long, to look for the APNs token. iOS hands it over some time after launch.
const _apnsPollInterval = Duration(milliseconds: 50);
const _apnsWaitCap = Duration(milliseconds: 3000);

/// The push token the app enrolls with, and what happens to the enrollments when FCM rotates it.
///
/// The backend is told only when a rotation is signalled, not at every start, and a rotation that
/// happens while the app is not running is not seen. Only Android signals rotations. On iOS the app
/// enrolls the APNs token, and Firebase has no stream for that one changing, so nothing is reported.
class DeviceTokenSource {
  /// [_ready] completes once Firebase is usable. [_report] sends a token to the backend.
  DeviceTokenSource({required this._ready, required this._report}) {
    // Made here, while there is no token yet, so its first run reports nothing.
    enrollmentUpdate = futureSignal(
      _updateEnrollments,
      options: const AsyncSignalOptions<List<TokenReportResult>>(initialValue: [], lazy: false),
    );
  }

  final Future<void> _ready;
  final ReportDeviceToken _report;

  final _deviceToken = signal<(String, DeviceTokenType)?>(null);
  (String, DeviceTokenType)? _initialToken;
  StreamSubscription<String>? _rotations;

  /// The token the app enrolls with. Null until it has been loaded, then the latest one.
  ReadonlySignal<(String, DeviceTokenType)?> get deviceToken => _deviceToken;

  /// Telling the backend about a rotated token, for every enrollment, and how each went. It is an
  /// empty list while nothing has been rotated, loading while the backend is being told, and the
  /// results afterwards, until the UI has dealt with them and sets it back to an empty list.
  late final FutureSignal<List<TokenReportResult>> enrollmentUpdate;

  /// Starts loading the token and following rotations, without waiting for either.
  void start() => unawaited(_start());

  Future<void> _start() async {
    await _ready;

    // 1. Load the token the app enrolls with. It is noted first, because setting the token below is
    // a change that makes the update run.
    _initialToken = await _loadToken();
    _deviceToken.value = _initialToken;

    // 2. Follow rotations. iOS has no signal for the APNs token changing. A new token is a change
    // of the signal, which makes the update run. Setting the same token again is not a change.
    if (Platform.isIOS) return;
    _rotations = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint('onTokenRefresh listener triggered');
      _deviceToken.value = (token, DeviceTokenType.fcmToken);
    });
  }

  /// Runs each time [enrollmentUpdate] loads. Reading the token here, before any `await`, makes it
  /// load again whenever the token changes. The token loaded at start is not reported.
  Future<List<TokenReportResult>> _updateEnrollments() async {
    final token = _deviceToken();
    return token == null || token == _initialToken ? const [] : _report(token);
  }

  Future<(String, DeviceTokenType)?> _loadToken() async {
    if (Platform.isIOS && appConfiguration.iOSPushService == IOSPushService.apns) {
      final apnsToken = await _waitForApnsToken();
      if (apnsToken == null) {
        debugPrint('APNs token could not be retrieved - receiving notifications not possible');
        return null;
      }
      debugPrint('APNs token: $apnsToken');
      return (apnsToken, DeviceTokenType.apns);
    }
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM token: $token');
    return token == null ? null : (token, DeviceTokenType.fcmToken);
  }

  Future<String?> _waitForApnsToken() =>
      Stream.periodic(_apnsPollInterval, (computationCount) => FirebaseMessaging.instance.getAPNSToken())
          .asyncMap((event) => event)
          .where((token) => token != null)
          .timeout(
            _apnsWaitCap,
            onTimeout: (sink) {
              sink.add(null);
            },
          )
          .first;

  void clearEnrollmentUpdates() {
    enrollmentUpdate.setValue(const []);
  }

  Future<void> dispose() async {
    await _rotations?.cancel();
    enrollmentUpdate.dispose();
    _deviceToken.dispose();
  }
}
