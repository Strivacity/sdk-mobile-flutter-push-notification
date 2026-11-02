import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

typedef LoadEnrollments = Future<List<Enrollment>> Function();

/// This device's enrollments, as the SDK records them.
Future<List<Enrollment>> loadEnrollments(PushNotification sdk) => sdk.listEnrollments();
