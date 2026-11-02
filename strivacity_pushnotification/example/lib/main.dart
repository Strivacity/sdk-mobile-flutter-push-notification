/// Push Notification Example app
///
/// Quick start for example app:
///   - `main` runs [PushExampleApp], which starts the services the application
///     needs and then opens its first screen. Some config options are available
///     in `config.dart`.
///   - Push related functionality, such as enrolling devices and resolving
///     challenges, is in the `usecases` folder. Every PushNotification SDK call
///     is made there.
///   - [ChallengeInbox] service collects challenges from Intents, FCM push
///     notification payloads, APNs callbacks channels. It serializes them and
///     indirectly instructs app to display them in LIFO order
///   - [DeviceTokenSource] for producing the Device Tokens for enrollments. It
///     also watches for FCM token rotations and starts enrollment update
///     mechanism when detected.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'dependency.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'usecases/push/challenge_inbox.dart';
import 'usecases/push/device_token_source.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PushExampleApp(dependencies: createAppDependencies()));
}

class PushExampleApp extends StatefulWidget {
  const PushExampleApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<PushExampleApp> createState() => _PushExampleAppState();
}

class _PushExampleAppState extends State<PushExampleApp> {
  @override
  void initState() {
    super.initState();
    // Starts the app's services and opens its first screen when they are up.
    unawaited(widget.dependencies.launch());
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.data,
    navigatorKey: widget.dependencies.navigator.navigatorKey,
    routes: widget.dependencies.routes,
    // Always start at the splash, whatever route the platform launched the app with (`flutter run
    // --route`). Otherwise the splash, and with it bootstrapping, would be skipped.
    onGenerateInitialRoutes: (initialRoute) => [
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoute.splash),
        builder: widget.dependencies.routes[AppRoute.splash]!,
      ),
    ],
  );
}
