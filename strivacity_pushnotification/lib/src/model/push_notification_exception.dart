import 'package:meta/meta.dart';

/// A push notification call that failed.
///
/// Every failure is one of the subclasses. The message never
/// contains secrets such as one-time tokens or challenge values.
sealed class PushNotificationException implements Exception {
  /// Creates an exception.
  const PushNotificationException({required this.code, required this.message});

  /// A stable identifier of the failure, such as `already_enrolled`, the same on every platform.
  final String code;

  /// A description of the failure.
  final String message;

  /// Names the failure's own type, so a logged exception shows which one it is.
  @override
  @mustBeOverridden
  String toString();
}

/// The enrollment grant is malformed.
final class InvalidGrantException extends PushNotificationException {
  /// Creates the exception.
  const InvalidGrantException({required super.message}) : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'invalid_grant';

  @override
  String toString() => 'InvalidGrantException: $message';
}

/// The issuer is not an absolute https URL.
final class InvalidIssuerException extends PushNotificationException {
  /// Creates the exception.
  const InvalidIssuerException({required super.message})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'invalid_issuer';

  @override
  String toString() => 'InvalidIssuerException: $message';
}

/// The device name is empty or too long.
final class InvalidDeviceNameException extends PushNotificationException {
  /// Creates the exception.
  const InvalidDeviceNameException({required super.message})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'invalid_device_name';

  @override
  String toString() => 'InvalidDeviceNameException: $message';
}

/// The backend rejected the enrollment.
final class EnrollmentRejectedException extends PushNotificationException {
  /// Creates the exception.
  const EnrollmentRejectedException({required super.message, this.status})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'enrollment_rejected';

  /// The HTTP status the backend answered with, if it answered.
  final int? status;

  @override
  String toString() =>
      status == null
          ? 'EnrollmentRejectedException: $message'
          : 'EnrollmentRejectedException(status: $status): $message';
}

/// The device is already enrolled for the account.
final class AlreadyEnrolledException extends PushNotificationException {
  /// Creates the exception.
  const AlreadyEnrolledException({required super.message})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'already_enrolled';

  @override
  String toString() => 'AlreadyEnrolledException: $message';
}

/// The backend rejected the un-enrollment.
final class UnenrollmentRejectedException extends PushNotificationException {
  /// Creates the exception.
  const UnenrollmentRejectedException({required super.message, this.status})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'unenrollment_rejected';

  /// The HTTP status the backend answered with, if it answered.
  final int? status;

  @override
  String toString() =>
      status == null
          ? 'UnenrollmentRejectedException: $message'
          : 'UnenrollmentRejectedException(status: $status): $message';
}

/// The backend rejected the push token update.
final class TokenUpdateRejectedException extends PushNotificationException {
  /// Creates the exception.
  const TokenUpdateRejectedException({required super.message, this.status})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'token_update_rejected';

  /// The HTTP status the backend answered with, if it answered.
  final int? status;

  @override
  String toString() =>
      status == null
          ? 'TokenUpdateRejectedException: $message'
          : 'TokenUpdateRejectedException(status: $status): $message';
}

/// The device holds no enrollment for the account.
final class NotEnrolledException extends PushNotificationException {
  /// Creates the exception.
  const NotEnrolledException({required super.message}) : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'not_enrolled';

  @override
  String toString() => 'NotEnrolledException: $message';
}

/// The challenge could not be read or retrieved.
final class ChallengeUnavailableException extends PushNotificationException {
  /// Creates the exception.
  const ChallengeUnavailableException({required super.message, this.status})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'challenge_unavailable';

  /// The HTTP status the backend answered with, if it answered.
  final int? status;

  @override
  String toString() =>
      status == null
          ? 'ChallengeUnavailableException: $message'
          : 'ChallengeUnavailableException(status: $status): $message';
}

/// The backend sent a challenge type this version does not support.
final class UnsupportedChallengeTypeException
    extends PushNotificationException {
  /// Creates the exception.
  const UnsupportedChallengeTypeException({required super.message})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'unsupported_challenge_type';

  @override
  String toString() => 'UnsupportedChallengeTypeException: $message';
}

/// The key's signing algorithm is not supported.
final class UnsupportedAlgorithmException extends PushNotificationException {
  /// Creates the exception.
  const UnsupportedAlgorithmException({required super.message})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'unsupported_algorithm';

  @override
  String toString() => 'UnsupportedAlgorithmException: $message';
}

/// Reading or writing secure storage failed.
final class StorageFailureException extends PushNotificationException {
  /// Creates the exception.
  const StorageFailureException({required super.message})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'storage_failure';

  @override
  String toString() => 'StorageFailureException: $message';
}

/// Only a software-backed key is available and the app has not allowed one.
final class SoftwareBackedKeyException extends PushNotificationException {
  /// Creates the exception.
  const SoftwareBackedKeyException({required super.message})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'software_backed_key';

  @override
  String toString() => 'SoftwareBackedKeyException: $message';
}

/// The backend could not be reached.
final class NetworkFailureException extends PushNotificationException {
  /// Creates the exception.
  const NetworkFailureException({required super.message})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'network_failure';

  @override
  String toString() => 'NetworkFailureException: $message';
}

/// The selected option is not one the challenge offered.
final class InvalidChallengeOptionException extends PushNotificationException {
  /// Creates the exception.
  const InvalidChallengeOptionException({required super.message})
    : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'invalid_challenge_option';

  @override
  String toString() => 'InvalidChallengeOptionException: $message';
}

/// A failure outside the other categories, including a code this version does not know.
final class UnexpectedException extends PushNotificationException {
  /// Creates the exception.
  const UnexpectedException({required super.message}) : super(code: wireCode);

  /// The code the platform reports for this failure.
  static const wireCode = 'unexpected';

  @override
  String toString() => 'UnexpectedException: $message';
}
