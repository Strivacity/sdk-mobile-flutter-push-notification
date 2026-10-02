import 'package:flutter/foundation.dart' show visibleForTesting;

import 'internal/platform_api.g.dart';
import 'internal/platform_mapping.dart';
import 'model/challenge.dart';
import 'model/device_token_type.dart';
import 'model/enrollment.dart';
import 'model/enrollment_grant.dart';
import 'model/push_notification_exception.dart';
import 'model/resolution_result.dart';

/// Enrolls this device for push-based multi-factor authentication and answers the challenges
/// that arrive.
///
/// The app owns the push token and receives push messages itself. It passes the token to
/// [enrollDevice] and [updateDeviceToken], and passes each received payload to
/// [canHandleMessage] and [handleMessage].
class PushNotification {
  PushNotification._(this._api);

  /// The shared instance, built with [allowSoftwareBackedKeys].
  ///
  /// Repeated calls return the same instance. A repeated call with a different
  /// [allowSoftwareBackedKeys] throws a [StateError].
  ///
  /// [allowSoftwareBackedKeys] lets enrollment use keys that are not hardware backed. It exists
  /// for emulators and simulators and defaults to false.
  static Future<PushNotification> getInstance({
    bool allowSoftwareBackedKeys = false,
  }) => _getInstance(PushNotificationPlatformApi(), allowSoftwareBackedKeys);

  /// Like [getInstance], using [api] to reach the platform.
  @visibleForTesting
  static Future<PushNotification> getInstanceWith(
    PushNotificationPlatformApi api, {
    bool allowSoftwareBackedKeys = false,
  }) => _getInstance(api, allowSoftwareBackedKeys);

  /// Forgets the shared instance.
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
    _allowSoftwareBackedKeys = null;
  }

  static Future<PushNotification>? _instance;
  static bool? _allowSoftwareBackedKeys;

  final PushNotificationPlatformApi _api;

  static Future<PushNotification> _getInstance(
    PushNotificationPlatformApi api,
    bool allowSoftwareBackedKeys,
  ) {
    final existing = _instance;
    if (existing == null) {
      _allowSoftwareBackedKeys = allowSoftwareBackedKeys;
      return _instance = _create(api, allowSoftwareBackedKeys);
    }
    if (_allowSoftwareBackedKeys != allowSoftwareBackedKeys) {
      return Future.error(
        StateError(
          'PushNotification is already created with allowSoftwareBackedKeys: '
          '$_allowSoftwareBackedKeys.',
        ),
      );
    }
    return existing;
  }

  static Future<PushNotification> _create(
    PushNotificationPlatformApi api,
    bool allowSoftwareBackedKeys,
  ) async {
    try {
      await guardPlatformCall(
        () => api.create(
          PlatformCreateOptions(
            allowSoftwareBackedKeys: allowSoftwareBackedKeys,
          ),
        ),
      );
      return PushNotification._(api);
    } on Object {
      resetInstance();
      rethrow;
    }
  }

  /// Parses an enrollment grant URL, scanned from a QR code or opened as a deep link.
  ///
  /// Throws an [InvalidGrantException] or [InvalidIssuerException] when [url] is not a usable
  /// grant.
  Future<EnrollmentGrant> parseEnrollmentGrant(String url) async {
    final grant = await guardPlatformCall(() => _api.parseEnrollmentGrant(url));
    return grant.toPublic();
  }

  /// Enrolls this device for the account named by [grant].
  ///
  /// The key and enrollment record are stored before the backend is called, and removed again if
  /// it fails. If the app is terminated mid-call the enrollment stays recorded; [unenrollDevice]
  /// removes it.
  ///
  /// [deviceToken] is the push token the app obtained, of the kind [deviceTokenType]. APNs
  /// tokens are hex encoded and only valid on iOS. [deviceName] is 1 to 64 characters after
  /// trimming.
  ///
  /// Throws an [InvalidDeviceNameException], [InvalidIssuerException] or
  /// [AlreadyEnrolledException] (un-enroll first); [SoftwareBackedKeyException],
  /// [UnsupportedAlgorithmException] or [StorageFailureException]; [EnrollmentRejectedException]
  /// (not retryable; obtain a fresh grant) or [NetworkFailureException] from the backend. A failed
  /// rollback replaces the error that caused it.
  Future<Enrollment> enrollDevice({
    required EnrollmentGrant grant,
    required String deviceToken,
    required DeviceTokenType deviceTokenType,
    required String deviceName,
  }) async {
    final enrollment = await guardPlatformCall(
      () => _api.enrollDevice(
        grant.toPlatform(),
        deviceToken,
        deviceTokenType.toPlatform(),
        deviceName,
      ),
    );
    return enrollment.toPublic();
  }

  /// Removes this device's enrollment.
  ///
  /// The backend is called first. The local key and enrollment are then removed whether or not
  /// that succeeded, so a backend failure never blocks re-enrolling — though the backend may still
  /// hold the enrollment, with no key left to retry.
  ///
  /// Throws an [InvalidIssuerException] or [NotEnrolledException]; [StorageFailureException]
  /// looking up or signing with the key (nothing has changed) or removing locally (it replaces any
  /// backend failure, which is lost); [UnenrollmentRejectedException] or
  /// [NetworkFailureException], after the local removal.
  Future<void> unenrollDevice({
    required String issuer,
    required String accountId,
  }) => guardPlatformCall(() => _api.unenrollDevice(issuer, accountId));

  /// Whether this device holds an enrollment for the account, according to the SDK's enrollment
  /// records — the same check [enrollDevice] makes. An unreadable store reads as not enrolled.
  ///
  /// Throws an [InvalidIssuerException].
  Future<bool> hasEnrollment({
    required String issuer,
    required String accountId,
  }) => guardPlatformCall(() => _api.hasEnrollment(issuer, accountId));

  /// Lists this device's enrollments, across issuers and accounts. An unreadable store reads as
  /// empty rather than failing.
  Future<List<Enrollment>> listEnrollments() async {
    final enrollments = await guardPlatformCall(_api.listEnrollments);
    return enrollments.map((e) => e.toPublic()).toList(growable: false);
  }

  /// Reports a new push token for an enrollment.
  ///
  /// Call this once per affected enrollment when the platform rotates the push token. A
  /// [DeviceTokenType.apns] token is only valid on iOS.
  ///
  /// Throws an [InvalidIssuerException], [NotEnrolledException] or [StorageFailureException];
  /// [TokenUpdateRejectedException] or [NetworkFailureException] from the backend.
  Future<void> updateDeviceToken({
    required String issuer,
    required String accountId,
    required String deviceToken,
    required DeviceTokenType deviceTokenType,
  }) => guardPlatformCall(
    () => _api.updateDeviceToken(
      issuer,
      accountId,
      deviceToken,
      deviceTokenType.toPlatform(),
    ),
  );

  /// Whether [payload], the data of a received push message, is a challenge this device can
  /// handle.
  ///
  /// Reads only the push envelope entry, and only when it is a string. Other entries may hold
  /// any value.
  ///
  /// Returns `false`, not an error, for a missing or unrecognised envelope or a malformed issuer.
  /// Throws a [StorageFailureException] looking up the key.
  Future<bool> canHandleMessage(Map<String, Object?> payload) =>
      guardPlatformCall(() => _api.canHandleMessage(payload));

  /// Fetches the challenge that [payload] points at. Makes a network call.
  ///
  /// Call [canHandleMessage] first.
  ///
  /// Throws an [InvalidIssuerException], [NotEnrolledException] or [StorageFailureException];
  /// [ChallengeUnavailableException] (no usable envelope, backend refusal, or a response it can't
  /// read), [UnsupportedChallengeTypeException] or [NetworkFailureException] from the backend.
  Future<Challenge> handleMessage(Map<String, Object?> payload) async {
    final challenge = await guardPlatformCall(
      () => _api.handleMessage(payload),
    );
    return challengeFromPlatform(challenge);
  }

  /// Submits the user's answer.
  ///
  /// Obtain [resolution] from [SimpleChallenge.approve], [ContextMatchingChallenge.select] or
  /// [Challenge.deny]. A denial is a normal result, not an error. An exception means the call
  /// itself failed.
  ///
  /// Throws a [NotEnrolledException] or [StorageFailureException]; [NetworkFailureException], or
  /// [ChallengeUnavailableException] for a backend response that is neither acceptance nor
  /// denial.
  Future<ResolutionResult> resolveChallenge(
    ChallengeResolution resolution,
  ) async {
    final result = await guardPlatformCall(
      () => _api.resolveChallenge(platformResolutionOf(resolution)),
    );
    return result.toPublic();
  }
}
