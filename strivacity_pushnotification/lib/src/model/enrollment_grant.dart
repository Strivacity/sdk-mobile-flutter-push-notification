import 'package:flutter/foundation.dart';

/// The payload that authorizes this device to enroll.
///
/// A grant arrives as a URL, scanned from a QR code or opened as a deep link. Parse it with
/// `PushNotification.parseEnrollmentGrant`.
@immutable
class EnrollmentGrant {
  /// Creates a grant.
  const EnrollmentGrant({
    required this.issuer,
    required this.oneTimeToken,
    required this.accountId,
    required this.displayUserName,
  });

  /// The issuer, normalized to scheme plus lowercased authority.
  final String issuer;

  /// The single-use token that authorizes the enrollment.
  final String oneTimeToken;

  /// The account the device enrolls for.
  final String accountId;

  /// The name shown to the user.
  final String displayUserName;

  @override
  bool operator ==(Object other) =>
      other is EnrollmentGrant &&
      other.issuer == issuer &&
      other.oneTimeToken == oneTimeToken &&
      other.accountId == accountId &&
      other.displayUserName == displayUserName;

  @override
  int get hashCode =>
      Object.hash(issuer, oneTimeToken, accountId, displayUserName);

  @override
  String toString() =>
      'EnrollmentGrant(issuer: $issuer, accountId: $accountId, '
      'displayUserName: $displayUserName)';
}
