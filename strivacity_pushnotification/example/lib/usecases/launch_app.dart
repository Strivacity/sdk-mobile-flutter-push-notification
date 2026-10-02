import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import '../routes.dart';
import 'push/challenge_inbox.dart';
import 'push/device_token_source.dart';

typedef LaunchApp = Future<void> Function();

/// Minimum splash time, so its animation plays.
const _minimumSplashTime = Duration(seconds: 2);

/// Starts the app's services in order, then asks [navigator] to open the app: the challenges waiting
/// to be answered, with Home beneath them, or else Home. This is the only place that makes the app's
/// first navigation, so nothing else can replace it.
Future<void> launchApp({
  required Future<void> initializeFirebase,
  required Future<PushNotification> createPushNotification,
  required DeviceTokenSource deviceTokenSource,
  required ChallengeInbox challengeInbox,
  required AppNavigator navigator,
}) async {
  // Runs alongside the services, so the splash is up for at least this long, not this long on top.
  final minimumSplashTime = Future<void>.delayed(_minimumSplashTime);

  await initializeFirebase;
  await createPushNotification;
  deviceTokenSource.start();
  // Listening from here on means a push during the splash is not missed.
  await challengeInbox.start();
  await minimumSplashTime;

  // Opening the inbox makes later challenges go straight to the challenge screen.
  final waiting = challengeInbox.open();
  if (waiting.isEmpty) {
    navigator.showHome();
  } else {
    navigator.showChallenges(waiting);
  }
}
