import 'package:flutter/foundation.dart';

/// A device's enrollment for one account at one issuer.
@immutable
class Enrollment {
  /// Creates an enrollment.
  const Enrollment({
    required this.issuer,
    required this.accountId,
    required this.keyId,
    this.userName,
    this.deviceName,
  });

  /// The issuer the device is enrolled with.
  final String issuer;

  /// The enrolled account.
  final String accountId;

  /// The identifier of the enrollment's key.
  final String keyId;

  /// The name shown for the user, if known.
  final String? userName;

  /// The name of this device, if known.
  final String? deviceName;

  @override
  bool operator ==(Object other) =>
      other is Enrollment &&
      other.issuer == issuer &&
      other.accountId == accountId &&
      other.keyId == keyId &&
      other.userName == userName &&
      other.deviceName == deviceName;

  @override
  int get hashCode =>
      Object.hash(issuer, accountId, keyId, userName, deviceName);

  @override
  String toString() =>
      'Enrollment(issuer: $issuer, accountId: $accountId, keyId: $keyId)';
}
