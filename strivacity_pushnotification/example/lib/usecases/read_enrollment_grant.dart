import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

typedef ReadEnrollmentGrant = Future<EnrollmentGrant> Function(String url);

/// The grant a scanned QR code carries. Throws if [url] is not a usable grant.
Future<EnrollmentGrant> readEnrollmentGrant(PushNotification sdk, String url) => sdk.parseEnrollmentGrant(url);
