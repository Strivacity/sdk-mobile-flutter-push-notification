import 'package:flutter/foundation.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

typedef EnrollThisDevice =
    Future<List<Enrollment>> Function({
      required EnrollmentGrant grant,
      required (String, DeviceTokenType) deviceToken,
      required String deviceName,
      required List<Enrollment> current,
    });

/// Enrolls this device, and returns the enrollments afterwards. Throws if enrolling fails.
Future<List<Enrollment>> enrollThisDevice({
  required PushNotification sdk,
  required EnrollmentGrant grant,
  required (String, DeviceTokenType) deviceToken,
  required String deviceName,
  required List<Enrollment> current,
}) async {
  final enrollment = await sdk.enrollDevice(
    grant: grant,
    deviceToken: deviceToken.$1,
    deviceTokenType: deviceToken.$2,
    deviceName: deviceName,
  );
  // The list is the SDK's record. If reading it fails, the new enrollment still goes on top.
  try {
    return await sdk.listEnrollments();
  } on Object catch (error) {
    debugPrint('Reading the enrollments failed: $error');
    return [enrollment, ...current];
  }
}
