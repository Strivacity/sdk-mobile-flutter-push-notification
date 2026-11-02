import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

typedef FetchChallenge = Future<Challenge> Function(Map<String, Object?> payload);

/// The challenge a push [payload] points at. Makes a network call.
Future<Challenge> fetchChallenge(PushNotification sdk, Map<String, Object?> payload) => sdk.handleMessage(payload);
