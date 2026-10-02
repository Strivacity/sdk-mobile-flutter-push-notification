import 'package:flutter/services.dart';

import '../model/device_token_type.dart';
import '../model/enrollment.dart';
import '../model/enrollment_grant.dart';
import '../model/push_notification_exception.dart';
import '../model/resolution_result.dart';
import 'platform_api.g.dart';

/// The error code the native side reports when the SDK is already built with other options.
const configurationConflictCode = 'configuration_conflict';

/// Runs [call] and turns a platform failure into a [PushNotificationException].
///
/// A configuration conflict becomes a [StateError], because it signals a programming error.
Future<T> guardPlatformCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on PlatformException catch (failure, stackTrace) {
    if (failure.code == configurationConflictCode) {
      Error.throwWithStackTrace(
        StateError(
          failure.message ??
              'The push notification SDK is already configured differently.',
        ),
        stackTrace,
      );
    }
    Error.throwWithStackTrace(_exceptionFor(failure), stackTrace);
  }
}

/// The exception for a platform failure, chosen by the failure's code. A code this version does not
/// know becomes an [UnexpectedException].
PushNotificationException _exceptionFor(PlatformException failure) {
  final details = failure.details;
  final detailStatus = details is Map ? details['status'] : null;
  final message = failure.message ?? 'The push notification call failed.';
  final status = detailStatus is int ? detailStatus : null;

  return switch (failure.code) {
    InvalidGrantException.wireCode => InvalidGrantException(message: message),
    InvalidIssuerException.wireCode => InvalidIssuerException(message: message),
    InvalidDeviceNameException.wireCode => InvalidDeviceNameException(
      message: message,
    ),
    EnrollmentRejectedException.wireCode => EnrollmentRejectedException(
      message: message,
      status: status,
    ),
    AlreadyEnrolledException.wireCode => AlreadyEnrolledException(
      message: message,
    ),
    UnenrollmentRejectedException.wireCode => UnenrollmentRejectedException(
      message: message,
      status: status,
    ),
    TokenUpdateRejectedException.wireCode => TokenUpdateRejectedException(
      message: message,
      status: status,
    ),
    NotEnrolledException.wireCode => NotEnrolledException(message: message),
    ChallengeUnavailableException.wireCode => ChallengeUnavailableException(
      message: message,
      status: status,
    ),
    UnsupportedChallengeTypeException.wireCode =>
      UnsupportedChallengeTypeException(message: message),
    UnsupportedAlgorithmException.wireCode => UnsupportedAlgorithmException(
      message: message,
    ),
    StorageFailureException.wireCode => StorageFailureException(
      message: message,
    ),
    SoftwareBackedKeyException.wireCode => SoftwareBackedKeyException(
      message: message,
    ),
    NetworkFailureException.wireCode => NetworkFailureException(
      message: message,
    ),
    InvalidChallengeOptionException.wireCode => InvalidChallengeOptionException(
      message: message,
    ),
    _ => UnexpectedException(message: message),
  };
}

/// Conversions for [DeviceTokenType].
extension DeviceTokenTypeMapping on DeviceTokenType {
  /// The platform value.
  PlatformDeviceTokenType toPlatform() => switch (this) {
    DeviceTokenType.apns => PlatformDeviceTokenType.apns,
    DeviceTokenType.fcmToken => PlatformDeviceTokenType.fcmToken,
    DeviceTokenType.fcmFid => PlatformDeviceTokenType.fcmFid,
  };
}

/// Conversions for [PlatformResolutionResult].
extension PlatformResolutionResultMapping on PlatformResolutionResult {
  /// The public value.
  ResolutionResult toPublic() => switch (this) {
    PlatformResolutionResult.ok => ResolutionResult.ok,
    PlatformResolutionResult.notOk => ResolutionResult.notOk,
  };
}

/// Conversions for [EnrollmentGrant].
extension EnrollmentGrantMapping on EnrollmentGrant {
  /// The platform value.
  PlatformEnrollmentGrant toPlatform() => PlatformEnrollmentGrant(
    issuer: issuer,
    oneTimeToken: oneTimeToken,
    accountId: accountId,
    displayUserName: displayUserName,
  );
}

/// Conversions for [PlatformEnrollmentGrant].
extension PlatformEnrollmentGrantMapping on PlatformEnrollmentGrant {
  /// The public value.
  EnrollmentGrant toPublic() => EnrollmentGrant(
    issuer: issuer,
    oneTimeToken: oneTimeToken,
    accountId: accountId,
    displayUserName: displayUserName,
  );
}

/// Conversions for [PlatformEnrollment].
extension PlatformEnrollmentMapping on PlatformEnrollment {
  /// The public value.
  Enrollment toPublic() => Enrollment(
    issuer: issuer,
    accountId: accountId,
    keyId: keyId,
    userName: userName,
    deviceName: deviceName,
  );
}
