import 'package:flutter/foundation.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

/// The enrollments after unenrolling, and what went wrong, if anything. The device drops the
/// enrollment either way, so both are always known.
typedef UnenrollOutcome = ({List<Enrollment> enrollments, Object? error});

typedef UnenrollThisDevice = Future<UnenrollOutcome> Function(Enrollment target, List<Enrollment> current);

/// Unenrolls [target]. The SDK removes it locally even when the server can't be told, so the list
/// is read again whatever happened, and a failure is reported in the outcome, not thrown.
Future<UnenrollOutcome> unenrollThisDevice({
  required PushNotification sdk,
  required Enrollment target,
  required List<Enrollment> current,
}) async {
  Object? error;
  try {
    await sdk.unenrollDevice(issuer: target.issuer, accountId: target.accountId);
  } on Object catch (e) {
    debugPrint('$e');
    error = e;
  }
  try {
    return (enrollments: await sdk.listEnrollments(), error: error);
  } on Object catch (e) {
    debugPrint('Reading the enrollments failed: $e');
    return (enrollments: [for (final enrollment in current) if (enrollment != target) enrollment], error: error);
  }
}
