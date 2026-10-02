import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:signals_core/signals_core.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import '../../usecases/enroll_this_device.dart';
import '../../usecases/load_enrollments.dart';
import '../../usecases/push/device_token_source.dart';
import '../../usecases/read_enrollment_grant.dart';
import '../../usecases/report_device_token.dart';
import '../../usecases/unenroll_this_device.dart';
import 'home_state.dart';

/// Home's state, and the actions the screen can take on it.
class HomeViewModel {
  HomeViewModel({
    required this._requestNotificationPermission,
    required this._loadEnrollments,
    required this._readEnrollmentGrant,
    required this._enrollThisDevice,
    required this._unenrollThisDevice,
    required this._deviceTokenSource,
  });

  final Future<bool> Function() _requestNotificationPermission;
  final LoadEnrollments _loadEnrollments;
  final ReadEnrollmentGrant _readEnrollmentGrant;
  final EnrollThisDevice _enrollThisDevice;
  final UnenrollThisDevice _unenrollThisDevice;
  final DeviceTokenSource _deviceTokenSource;

  final _state = signal<HomeState>((
    status: HomeStatus.loading,
    enrollments: const [],
    pendingGrant: null,
    enrolling: false,
    tokenUpdating: false,
    tokenUpdateFailures: null,
    notice: null,
  ));

  /// What the screen shows. Only this view model changes it.
  ReadonlySignal<HomeState> get state => _state;

  /// The current state, read without subscribing, so an effect that calls in here does not come to
  /// depend on it.
  HomeState get _value => _state.peek();

  EffectCleanup? _stopMirroringTokenUpdate;

  /// Removing an enrollment. Not shown; it only stops a second removal starting meanwhile.
  var _unenrolling = false;

  /// Home is on screen: follows the token source and loads the enrollments.
  Future<void> start() async {
    // The token source works on its own, from the splash on. The effect runs at once with what is
    // there now, so an update that finished before Home was built still shows. Only the update is
    // tracked: what the handler reads must not make the effect run again.
    _stopMirroringTokenUpdate ??= effect(() {
      final update = _deviceTokenSource.enrollmentUpdate.value;
      untracked(() => _onTokenUpdateChanged(update));
    });

    // Asked so pushes can show; the answer isn't used. A missing permission doesn't stop the
    // enrollments from showing, so only the enrollments can fail the screen.
    try {
      await _requestNotificationPermission();
    } on Object catch (error) {
      debugPrint('$error');
    }

    try {
      final enrollments = await _loadEnrollments();
      _emit(_value.copyWith(status: HomeStatus.ready, enrollments: enrollments));
    } on Object catch (error) {
      debugPrint('Loading enrollments failed: $error');
      _emit(_value.copyWith(status: HomeStatus.failure, enrollments: const []));
    }
  }

  /// A QR code was scanned; [url] is its text.
  Future<void> enrollmentScanned(String url) async {
    final currentState = _value;
    // A scan while one is being handled would burn a second one-time token.
    if (currentState.enrolling || currentState.pendingGrant != null) return;

    HomeState withNotice(String message) =>
        currentState.copyWith(pendingGrant: () => null, notice: () => (message: message, kind: HomeNoticeKind.error));

    if (_deviceTokenSource.deviceToken() == null) {
      _emit(withNotice('This device has no push token yet, so it cannot be enrolled.'));
      return;
    }
    try {
      final grant = await _readEnrollmentGrant(url);
      _emit(currentState.copyWith(pendingGrant: () => grant, notice: () => null));
    } on PushNotificationException catch (error) {
      debugPrint('$error');
      _emit(withNotice('That QR code is not an enrollment code.'));
    } on Object catch (error) {
      debugPrint('$error');
      _emit(withNotice('The QR code could not be read.'));
    }
  }

  /// The device was named.
  Future<void> deviceNameSubmitted(String name) async {
    final s = _value;
    final grant = s.pendingGrant;
    final token = _deviceTokenSource.deviceToken();
    if (grant == null || token == null || s.enrolling) return;

    _emit(s.copyWith(pendingGrant: () => null, enrolling: true, notice: () => null));

    HomeNotice notice;
    var enrollments = s.enrollments;
    try {
      enrollments = await _enrollThisDevice(grant: grant, deviceToken: token, deviceName: name, current: s.enrollments);
      notice = (
        message: 'Enrolled ${grant.displayUserName}. Push requests will arrive on this device.',
        kind: HomeNoticeKind.success,
      );
    } on PushNotificationException catch (error) {
      debugPrint('$error');
      notice = (message: _describeEnrollFailure(error), kind: HomeNoticeKind.error);
    } on Object catch (error) {
      debugPrint('$error');
      notice = (message: 'Enrollment failed. Scan the QR code again.', kind: HomeNoticeKind.error);
    }

    _emit(_value.copyWith(enrollments: enrollments, enrolling: false, notice: () => notice));
  }

  /// The name sheet was dismissed.
  void enrollmentCancelled() => _emit(_value.copyWith(pendingGrant: () => null));

  /// Removing [enrollment] was confirmed.
  Future<void> unenrollConfirmed(Enrollment enrollment) async {
    if (_unenrolling) return;
    _unenrolling = true;

    final s = _value;
    _emit(s.copyWith(notice: () => null));

    final name = enrollment.userName ?? enrollment.accountId;
    final outcome = await _unenrollThisDevice(enrollment, s.enrollments);
    _unenrolling = false;
    final notice = switch (outcome.error) {
      null => (message: 'Unenrolled $name.', kind: HomeNoticeKind.info),
      final PushNotificationException error => (
        message: _describeUnenrollFailure(error, name),
        kind: HomeNoticeKind.error,
      ),
      _ => (message: 'Unenrolling $name failed.', kind: HomeNoticeKind.error),
    };

    _emit(_value.copyWith(enrollments: outcome.enrollments, notice: () => notice));
  }

  /// The notice was shown.
  void noticeShown() => _emit(_value.copyWith(notice: () => null));

  /// The user has been told about the failed token updates. The only place the failures are cleared
  /// is the source; the state follows it when the source reports its new, empty result.
  void tokenUpdateFailuresShown() => _deviceTokenSource.clearEnrollmentUpdates();

  /// The token source changed state: it is telling the backend about a new push token, or it has a
  /// result, which is empty when there is nothing to report.
  void _onTokenUpdateChanged(AsyncState<List<TokenReportResult>> update) {
    if (update.isLoading) {
      // The results still there belong to an earlier update, so the failures stay as they are.
      _emit(_value.copyWith(tokenUpdating: true));
      return;
    }
    final failed = update.hasValue
        ? [
            for (final result in update.requireValue)
              if (result.error != null) result.enrollment,
          ]
        : const <Enrollment>[];
    _emit(_value.copyWith(tokenUpdating: false, tokenUpdateFailures: () => failed.isEmpty ? null : failed));
  }

  /// Sets the state, unless the screen has gone: async actions can finish after it closed.
  void _emit(HomeState state) {
    if (!_state.disposed) _state.value = state;
  }

  void dispose() {
    _stopMirroringTokenUpdate?.call();
    _state.dispose();
  }

  /// The message for a failed enrollment. Most end in scanning again: the one-time token is spent.
  static String _describeEnrollFailure(PushNotificationException error) => switch (error) {
    AlreadyEnrolledException() => 'This device is already enrolled for that account.',
    EnrollmentRejectedException() =>
      'The server rejected the enrollment. The QR code may have expired; scan a new one.',
    NetworkFailureException() => 'The server could not be reached. Check the connection and scan the QR code again.',
    InvalidDeviceNameException() => 'That device name is not valid.',
    SoftwareBackedKeyException() => 'This device cannot keep the enrollment key in secure hardware.',
    _ => 'Enrollment failed. Scan the QR code again.',
  };

  /// The message for a failed unenrollment. The device drops it locally either way.
  static String _describeUnenrollFailure(PushNotificationException error, String name) => switch (error) {
    NotEnrolledException() => '$name is not enrolled on this device.',
    UnenrollmentRejectedException() || NetworkFailureException() =>
      'Removed $name from this device, but the server could not be told. It may keep sending requests.',
    _ => 'Unenrolling $name failed.',
  };
}
