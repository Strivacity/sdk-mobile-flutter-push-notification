import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import 'features/challenge/challenge_view_model.dart';
import 'features/home/home_view_model.dart';
import 'routes.dart';
import 'usecases/answer_challenge.dart';
import 'usecases/enroll_this_device.dart';
import 'usecases/fetch_challenge.dart';
import 'usecases/launch_app.dart';
import 'usecases/load_enrollments.dart';
import 'usecases/push/challenge_inbox.dart';
import 'usecases/push/device_token_source.dart';
import 'usecases/push/firebase.dart';
import 'usecases/push/notification_permission.dart';
import 'usecases/read_enrollment_grant.dart';
import 'usecases/report_device_token.dart';
import 'usecases/unenroll_this_device.dart';

/// What the app needs from its object graph: its screens, navigation, and starting the services.
typedef AppDependencies = ({Map<String, WidgetBuilder> routes, AppNavigator navigator, LaunchApp launch});

/// Builds the app's objects, each once. The only place that knows what each one gets.
AppDependencies createAppDependencies() {
  final firebase = initializeFirebase();
  // Every SDK call is a use case, under `usecases/`; each is handed the SDK once it is ready.
  final sdk = PushNotification.getInstance(allowSoftwareBackedKeys: kDebugMode);

  final deviceTokenSource = DeviceTokenSource(
    ready: firebase,
    report: (deviceToken) async => reportDeviceToken(await sdk, deviceToken),
  );

  // A view model is made for each screen, so the routes get functions that make one.
  final routes = appRoutes(
    createHomeViewModel: () => HomeViewModel(
      requestNotificationPermission: requestNotificationPermission,
      loadEnrollments: () async => loadEnrollments(await sdk),
      readEnrollmentGrant: (url) async => readEnrollmentGrant(await sdk, url),
      enrollThisDevice: ({required grant, required deviceToken, required deviceName, required current}) async =>
          enrollThisDevice(
            sdk: await sdk,
            grant: grant,
            deviceToken: deviceToken,
            deviceName: deviceName,
            current: current,
          ),
      unenrollThisDevice: (target, current) async =>
          unenrollThisDevice(sdk: await sdk, target: target, current: current),
      deviceTokenSource: deviceTokenSource,
    ),
    createChallengeViewModel: () => ChallengeViewModel(
      fetchChallenge: (payload) async => fetchChallenge(await sdk, payload),
      answerChallenge: (resolution) async => answerChallenge(await sdk, resolution),
    ),
  );

  final navigator = AppNavigator();
  final challengeInbox = ChallengeInbox(navigator: navigator, sdk: sdk);

  return (
    routes: routes,
    navigator: navigator,
    launch: () => launchApp(
      initializeFirebase: firebase,
      createPushNotification: sdk,
      deviceTokenSource: deviceTokenSource,
      challengeInbox: challengeInbox,
      navigator: navigator,
    ),
  );
}
