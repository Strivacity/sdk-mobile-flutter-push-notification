import 'package:flutter/foundation.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

/// What happened to one enrollment: `error` is null when the backend took the new token.
typedef TokenReportResult = ({Enrollment enrollment, Object? error});

typedef ReportDeviceToken = Future<List<TokenReportResult>> Function((String, DeviceTokenType) deviceToken);

/// Tells the backend the current push token, for every enrollment on this device, and returns how
/// each went. The SDK does not notice a rotation itself. An enrollment the backend refuses does not
/// stop the others. Throws only if the enrollments can't be listed.
Future<List<TokenReportResult>> reportDeviceToken(
  PushNotification sdk,
  (String, DeviceTokenType) deviceToken,
) async {
  debugPrint('Updating enrollments due to token rotation.');
  final results = <TokenReportResult>[];
  for (final enrollment in await sdk.listEnrollments()) {
    Object? error;
    try {
      await sdk.updateDeviceToken(
        issuer: enrollment.issuer,
        accountId: enrollment.accountId,
        deviceToken: deviceToken.$1,
        deviceTokenType: deviceToken.$2,
      );
    } on Object catch (e) {
      debugPrint('Updating the push token for ${enrollment.accountId} failed: $e');
      error = e;
    }
    results.add((enrollment: enrollment, error: error));
  }
  return results;
}
