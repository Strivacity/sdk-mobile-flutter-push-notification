import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import '../../routes.dart';
import 'apns_pushes.dart';

/// Collects the push messages that are sign-in challenges and sends each to the challenge screen.
///
/// Until [open], messages are held, so the first screen can be chosen with them in hand.
class ChallengeInbox {
  ChallengeInbox({required this.navigator, required this.sdk});

  final AppNavigator navigator;
  final Future<PushNotification> sdk;

  final _seen = <String>{};
  final _pending = <Map<String, Object?>>[];
  var _isOpen = false;

  /// Starts listening, and picks up the message that launched the app, if there was one. Firebase
  /// and the SDK must be ready. Listening goes on for as long as the app runs.
  Future<void> start() async {
    FirebaseMessaging.onMessage.listen(
      (message) => unawaited(_receive(message.data)),
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => unawaited(_receive(message.data)),
    );
    if (!kIsWeb && Platform.isIOS) {
      // iOS pushes sent straight through APNs never reach the Firebase streams above.
      await ApnsPushes.listen((data) => unawaited(_receive(data)));
    }
    final launchMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (launchMessage != null) await _receive(launchMessage.data);
  }

  /// Opens the inbox: from now on a challenge goes straight to the challenge screen. Returns the
  /// challenges that arrived before, oldest first, for the caller to show.
  List<Map<String, Object?>> open() {
    _isOpen = true;
    final waiting = List.of(_pending);
    _pending.clear();
    return waiting;
  }

  Future<void> _receive(Map<String, Object?> data) async {
    // The same push can come through more than one source, a tap that starts the app for one.
    // APNs messages have no id, so the content stands in for it.
    if (!_seen.add(jsonEncode(data))) return;

    final payload = Map<String, Object?>.of(data);
    try {
      if (!await (await sdk).canHandleMessage(payload)) return;
    } on Object catch (error) {
      debugPrint('Checking a push message failed: $error');
      return;
    }

    if (_isOpen) {
      navigator.pushChallenge(payload);
    } else {
      _pending.add(payload);
    }
  }
}
