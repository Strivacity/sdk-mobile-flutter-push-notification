import 'package:firebase_messaging/firebase_messaging.dart';

/// Asks to allow notifications; returns whether they are allowed.
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission();
  return switch (settings.authorizationStatus) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => true,
    AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently || AuthorizationStatus.notDetermined => false,
  };
}
