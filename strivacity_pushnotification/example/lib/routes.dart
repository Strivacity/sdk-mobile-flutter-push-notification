import 'package:flutter/material.dart';

import 'features/challenge/challenge_screen.dart';
import 'features/challenge/challenge_view_model.dart';
import 'features/home/home_screen.dart';
import 'features/home/home_view_model.dart';
import 'features/scan/scan_screen.dart';
import 'features/splash/splash_screen.dart';

/// The names of the places the app can navigate to.
abstract final class AppRoute {
  static const splash = '/';
  static const home = '/home';

  /// Pops with the scanned QR code's text, or null when closed.
  static const scan = '/scan';

  /// Takes the push payload, a `Map<String, Object?>`, as its argument.
  static const challenge = '/challenge';
}

/// The screen for each [AppRoute].
Map<String, WidgetBuilder> appRoutes({
  required HomeViewModel Function() createHomeViewModel,
  required ChallengeViewModel Function() createChallengeViewModel,
}) => {
  AppRoute.splash: (context) =>
      const SplashScreen(logoText: 'Authenticator', footerText: 'Device Enrollment Example App'),
  AppRoute.home: (context) => HomeScreen(createViewModel: createHomeViewModel),
  AppRoute.scan: (context) => const ScanScreen(),
  AppRoute.challenge: (context) => ChallengeScreen(
    payload: ModalRoute.settingsOf(context)!.arguments! as Map<String, Object?>,
    createViewModel: createChallengeViewModel,
  ),
};

/// The navigation the app's services make, from outside the widget tree. Screens navigate through
/// [Navigator] themselves.
final class AppNavigator {
  /// Given to the app's navigator, so this one can reach it.
  final navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => navigatorKey.currentState!;

  /// Replaces the screen stack with Home.
  void showHome() => _navigator.pushNamedAndRemoveUntil(AppRoute.home, (route) => false);

  /// Replaces the screen stack with Home and a challenge screen for each of [payloads] on top of it,
  /// the last one topmost.
  void showChallenges(List<Map<String, Object?>> payloads) {
    showHome();
    payloads.forEach(pushChallenge);
  }

  /// Puts a challenge screen for [payload] on top of the current stack.
  void pushChallenge(Map<String, Object?> payload) => _navigator.pushNamed(AppRoute.challenge, arguments: payload);
}
