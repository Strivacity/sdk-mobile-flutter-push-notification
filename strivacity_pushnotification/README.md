# Push Notification Plugin for Flutter

A push-based multi-factor authentication plugin for Flutter apps on Android and iOS. It lets an enrolled device receive and respond to push-based sign-in challenges.

## Table of Contents

- [What This Plugin Does](#what-this-plugin-does)
- [Example App](#example-app)
- [Requirements](#requirements)
- [Installation](#installation)
- [Platform Setup](#platform-setup)
- [Integration Guide](#integration-guide)
  - [1. Create the Instance](#1-create-the-instance)
  - [2. Handle Enrollment](#2-handle-enrollment)
  - [3. Handle Incoming Challenge Pushes](#3-handle-incoming-challenge-pushes)
  - [4. Render the Challenge and Collect a Response](#4-render-the-challenge-and-collect-a-response)
  - [5. Submit the Resolution](#5-submit-the-resolution)
- [Push Services on iOS](#push-services-on-ios)
- [Concepts and Flows](#concepts-and-flows)
- [Handling Enrollments](#handling-enrollments)
- [Error Handling](#error-handling)
- [Running on an Emulator or Simulator](#running-on-an-emulator-or-simulator)
- [Security Considerations](#security-considerations)

## What This Plugin Does

The plugin handles two core flows:

- **Enrollment**: register a device with an issuer on the Strivacity backend using an enrollment grant, delivered through a QR code or a deep link.
- **Challenge resolution**: receive push notifications that carry authentication challenges, and resolve them.

The plugin does **not**:

- Scan QR codes or handle deep links. Your app owns the camera and link handling.
- Register for push tokens, or detect when one rotates. Your app owns push registration and calls `updateDeviceToken` to report a new token (see [Handling Enrollments](#handling-enrollments)).
- Display notifications. Your app decides what appears on screen.
- Manage challenge UI. Your app renders the challenge and collects the user's decision.

## Example App

A complete app lives in the [`example/`](example) directory. It covers enrollment from a scanned QR code, listing and un-enrolling devices, receiving challenge pushes over FCM and APNs, answering challenges, and reporting rotated push tokens. Its README walks through the Firebase and platform setup.

## Requirements

- Flutter 3.29 or later, with Dart 3.7 or later.
- Android API 29 or later.
- iOS 15 or later. The iOS implementation is distributed as a Swift package, so your project needs [Swift Package Manager support](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers) enabled.
- A push provider for your app. The examples below use [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/flutter/client) through the `firebase_messaging` package. On iOS, a device can also enroll with its Apple Push Notification service (APNs) token instead.

## Installation

The plugin is not published to pub.dev yet (`publish_to: none` in its `pubspec.yaml`). Add it to your app from the repository, or from a local checkout:

```bash
flutter pub add strivacity_pushnotification
```

> **Note:** The plugin fetches the native Strivacity Push Notification SDKs from GitHub.
>
> - **Android.** The SDK is published to GitHub Packages (`com.strivacity.android:pushnotification`), which requires GitHub credentials to download. On the machine that builds your app, including CI, provide your GitHub username and a personal access token with the `read:packages` scope, either as the `gpr.user` and `gpr.token` properties in `~/.gradle/gradle.properties` or as the `GITHUB_USER` and `GITHUB_TOKEN` environment variables (authorized for the Strivacity organization if it enforces SSO). Without them the Android build fails while resolving dependencies.
> - **iOS.** Swift Package Manager clones the public repository `https://github.com/Strivacity/sdk-mobile-ios-push-notification.git` while it resolves your project's packages. No credentials are needed.

Then import it:

```dart
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';
```

## Platform Setup

**Android.** Android 13 and later asks the user for permission to show notifications. Declare the permission in `android/app/src/main/AndroidManifest.xml`, before the `<application>` element, and request it at runtime:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

**iOS.** In Xcode, open `ios/Runner.xcworkspace`, select the Runner target, and open **Signing & Capabilities**:

1. Add the **Push Notifications** capability.
2. Add the **Background Modes** capability and enable **Remote notifications** and **Background fetch**.

> 💡 **Tip:** Debug builds register with the APNs sandbox environment. A server that sends pushes to a debug build has to use the sandbox endpoint.

To deliver pushes through Firebase on iOS, upload an APNs authentication key (`.p8`) in the Firebase console under **Project settings → Cloud Messaging**. To enroll with the APNs token instead, the Strivacity backend sends to APNs directly, and the app forwards received payloads to Dart itself (see [Handle Incoming Challenge Pushes](#3-handle-incoming-challenge-pushes)).

## Integration Guide

### 1. Create the Instance

Create the plugin instance once, at app startup:

```dart
import 'package:flutter/foundation.dart';

final pushNotification = await PushNotification.getInstance(
  allowSoftwareBackedKeys: kDebugMode,
);
```

`getInstance` always returns the same instance, and one instance serves every issuer the device is enrolled with. Calling it again with a different `allowSoftwareBackedKeys` value throws a `StateError`.

**Hardware-backed keys are required by default.** Emulators and simulators have no secure hardware, so enrollment on them fails with the `softwareBackedKey` error code. See [Running on an Emulator or Simulator](#running-on-an-emulator-or-simulator).

### 2. Handle Enrollment

Enrollment requires:

1. An enrollment grant, parsed from a scanned QR code or a deep link.
2. The device's current push token and its kind, as a `DeviceTokenType`: `fcmToken` for an FCM registration token, `fcmFid` for a Firebase installation ID, or `apns` for an APNs token (iOS only). The plugin does not infer the kind.

> 💡 **Tip:** As of `firebase_messaging` 16.7.0, the package does not expose Firebase installation IDs as push tokens, so `fcmFid` is not usable through it. Use `fcmToken` with Firebase Cloud Messaging.
3. A device name that the user will recognize. It must be 1 to 64 characters after trimming, otherwise `enrollDevice` fails with the `invalidDeviceName` error code.

#### Parse the enrollment grant

Your app handles QR scanning and deep linking. Pass the scanned string or the link to `parseEnrollmentGrant`:

```dart
try {
  final grant = await pushNotification.parseEnrollmentGrant(qrCodeContent);
} on PushNotificationException catch (e) {
  switch (e) {
    case InvalidGrantException():
      // The grant is malformed. Show an error to the user.
    case InvalidIssuerException():
      // The issuer is not an absolute https URL.
    default:
      // Another failure. Log it.
  }
}
```

The grant exposes the `issuer`, the `accountId`, and a `displayUserName` that you can show while asking the user to confirm.

#### Call `enrollDevice`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

try {
  final enrollment = await pushNotification.enrollDevice(
    grant: grant,
    deviceToken: (await FirebaseMessaging.instance.getToken())!,
    deviceTokenType: DeviceTokenType.fcmToken,
    deviceName: userChosenName,
  );
  // Success. The device is now enrolled.
} on PushNotificationException catch (e) {
  switch (e) {
    case AlreadyEnrolledException():
      // This issuer and account are already enrolled on this device.
      // Un-enroll first to replace the enrollment.
    case EnrollmentRejectedException():
      // The Strivacity backend refused the enrollment. It is not retryable:
      // the user needs a fresh enrollment grant.
    case SoftwareBackedKeyException():
      // Running on an emulator or simulator without allowSoftwareBackedKeys.
    default:
      // Another failure. Log it.
  }
}
```

> ⚠️ **Important:** The one-time token in a grant is single-use. A failed enrollment cannot be retried with the same grant.

### 3. Handle Incoming Challenge Pushes

Your app receives push messages. Pass the data of each message to the plugin to check whether it is a challenge it can handle, then fetch the challenge:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> onPushData(Map<String, Object?> data) async {
  if (!await pushNotification.canHandleMessage(data)) {
    // Not a challenge, or the device is not enrolled for it.
    // Handle it as an ordinary app message.
    return;
  }
  try {
    final challenge = await pushNotification.handleMessage(data);
    // Show your challenge UI.
  } on PushNotificationException catch (e) {
    // The challenge could not be fetched. Log it and show an error.
  }
}
```

Feed `onPushData` from every place a push can arrive. With Firebase Cloud Messaging, that is three:

```dart
// The app is in the foreground.
FirebaseMessaging.onMessage.listen((message) => onPushData(message.data));

// The user tapped a notification while the app was in the background.
FirebaseMessaging.onMessageOpenedApp.listen((message) => onPushData(message.data));

// The user tapped a notification that started the app.
final initial = await FirebaseMessaging.instance.getInitialMessage();
if (initial != null) await onPushData(initial.data);
```

> 💡 **Tip:** The same push can reach the app through more than one of these sources. Ignore a payload you have already handled, so the user is not shown the same challenge twice.

> ⚠️ **Important:** On iOS, a push that the Strivacity backend sends straight to APNs never reaches the Firebase streams above. If you enroll with an APNs token, receive these pushes in your `AppDelegate` and forward their custom entries (everything except `aps`) to Dart, for example over a method channel. See [Push Services on iOS](#push-services-on-ios).

### 4. Render the Challenge and Collect a Response

`handleMessage` returns a sealed `Challenge` with two variants. Render a screen suited to the variant:

```dart
switch (challenge) {
  case SimpleChallenge():
    // Show an approve or deny screen.
    final resolution = userApproved ? challenge.approve() : challenge.deny();
    await submitResolution(resolution);

  case ContextMatchingChallenge(:final options):
    // Show the options and let the user pick one, or deny.
    final resolution = pickedOption == null
        ? challenge.deny()
        : challenge.select(pickedOption);
    await submitResolution(resolution);
}
```

Every challenge also carries `challengeId`, `issuer`, `accountId`, `expiresAt`, and a `metadata` map that gives the user context for the decision, such as the device, location or time. Metadata keys are not guaranteed, values are strings or `null`, and any entry of another type is left out.

`ContextMatchingChallenge.select` throws an `InvalidChallengeOptionException` if the option is not one of `options`.

### 5. Submit the Resolution

Once the user has decided, sign and submit the resolution:

```dart
Future<void> submitResolution(ChallengeResolution resolution) async {
  try {
    switch (await pushNotification.resolveChallenge(resolution)) {
      case ResolutionResult.ok:
        // The Strivacity backend accepted the resolution.
      case ResolutionResult.notOk:
        // The Strivacity backend did not accept it. This includes explicit denials.
    }
  } on PushNotificationException catch (e) {
    // The call itself failed, for example because of a network error.
  }
}
```

## Push Services on iOS

On iOS, a device can enroll with either of two push tokens:

| | FCM | APNs |
| --- | --- | --- |
| Token type | `DeviceTokenType.fcmToken` | `DeviceTokenType.apns` |
| Delivery | The Strivacity backend sends through Firebase, which delivers through APNs. It needs the APNs key uploaded to Firebase. | The Strivacity backend sends straight to APNs. It needs its own APNs credentials. The same `.p8` key can be reused. |
| Received in Dart through | `FirebaseMessaging.onMessage`, `onMessageOpenedApp` and `getInitialMessage` | Code you write: the Firebase streams never see these pushes |

Android always uses FCM. The plugin itself does not care which service delivers a push. It only needs the payload you pass to `canHandleMessage` and `handleMessage`.

### Using FCM and APNs together

An app can support both options, for example to let a deployment choose. iOS allows only one notification delegate (`UNUserNotificationCenterDelegate`) per app, and `firebase_messaging` expects to be it. The Firebase plugin also ignores any push that did not come through Firebase, so APNs pushes have to be picked up elsewhere. The approach is:

1. The app's `AppDelegate` is the single notification delegate.
2. It tells the two kinds of push apart. A push that came through Firebase carries a `gcm.message_id` entry. Those pushes are passed on to the plugins registered with Flutter, which includes `firebase_messaging`, and the Firebase streams in Dart work as usual.
3. A push without `gcm.message_id` came straight from APNs. The `AppDelegate` sends its custom entries (everything except `aps`) to Dart over a method channel. A tap that starts the app arrives before Dart is listening, so pushes are held until Dart asks for them.
4. In Dart, both sources feed the same function that calls `canHandleMessage` and `handleMessage`.

To obtain the APNs token in Dart, `firebase_messaging` exposes `FirebaseMessaging.instance.getAPNSToken()`. It can return `null` for a short time after launch while iOS registers the device, so retry for a moment before giving up.

> 💡 **Tip:** The same push can reach Dart through more than one source, for example when a tap starts the app. Ignore a payload you have already handled.

> ⚠️ **Important:** The plugin does not provide this notification delegate. It has to live in your app, because only the app can own the single delegate that iOS allows.

The [example app](example) implements all of this. These are the files to read:

- [`ios/Runner/AppDelegate.swift`](example/ios/Runner/AppDelegate.swift): the single notification delegate, the routing by `gcm.message_id`, and the method channel that hands APNs pushes to Dart.
- [`lib/usecases/push/apns_pushes.dart`](example/lib/usecases/push/apns_pushes.dart): the Dart side of that channel.
- [`lib/usecases/push/challenge_inbox.dart`](example/lib/usecases/push/challenge_inbox.dart): collects pushes from the Firebase streams and the APNs channel and passes them to the plugin.
- [`lib/usecases/push/device_token_source.dart`](example/lib/usecases/push/device_token_source.dart): picks the APNs or FCM token for enrollment.
- [`lib/config.dart`](example/lib/config.dart): the `iOSPushService` setting that chooses between the two.

## Concepts and Flows

### Enrollment Flow

Enrollment establishes a trusted relationship between a device, a user account, and an issuer on the Strivacity backend.

1. **Parse the grant.** Your app scans a QR code or handles a deep link. The grant identifies the issuer, the account, and the one-time token that authorizes the enrollment.
2. **Generate and register.** `enrollDevice` generates a key pair for the issuer and account and stores it on the device, together with the enrollment's details, for later lookups and token updates. The private key never leaves the device. It then sends the public key to the Strivacity backend together with the one-time token, and removes the key pair and the enrollment again if the backend refuses or can't be reached.
3. **Constraints.**
   - A device holds at most one enrollment per issuer and account. A second enrollment for the same pair fails with `alreadyEnrolled`. Un-enroll first to replace it.
   - The one-time token is single-use. A fresh grant is required after a failed enrollment.
   - If the app is terminated while `enrollDevice` is waiting for the backend, the enrollment stays recorded on the device even though the backend may never have accepted it. It then appears in `listEnrollments`, and `updateDeviceToken` for it is refused. Call `unenrollDevice` to remove it: the local removal completes even though the backend call fails.
   - On iOS, enrollments survive deleting and reinstalling the app, because the key and the enrollment's details are kept together in the Keychain. After a reinstall `listEnrollments` still returns them, and enrolling the same pair again fails with `alreadyEnrolled`. The push token usually changes on a reinstall, so report the new one with `updateDeviceToken` for each listed enrollment. On Android a reinstall starts clean.
   - Enrollments never carry over to another device, for example through a backup restore.

### Challenge Flow

A challenge is an authentication request pushed to an enrolled device. The user reviews it and makes a decision.

1. **A push arrives.** Your app receives it and calls `canHandleMessage` to check whether it is a challenge for an enrollment on this device.
2. **Fetch the details.** `handleMessage` retrieves the full challenge from the Strivacity backend. It is either a `SimpleChallenge` (approve or deny) or a `ContextMatchingChallenge` (pick from the options, or deny).
3. **Collect the decision.** Your app renders a screen for the challenge type and captures the user's choice.
4. **Submit the resolution.** `resolveChallenge` signs the response with the enrolled key and sends it to the Strivacity backend.
5. **Read the result.** The Strivacity backend answers `ResolutionResult.ok` or `ResolutionResult.notOk`.

**A denial is not an error.** An explicit refusal by the user is a normal outcome and is submitted like any other resolution. Exceptions are reserved for real failures, such as network errors or a missing key.

**Expiry.** `challenge.expiresAt` is an ISO 8601 instant, for example `2026-10-01T14:30:00Z`. Use it to display the remaining time or to warn the user. The plugin does not enforce it, because the Strivacity backend is the authority.

## Handling Enrollments

### Check Whether the Device Is Enrolled

Before calling `enrollDevice`, check whether an enrollment already exists. This is the same check `enrollDevice` makes, and an unreadable store reads as not enrolled:

```dart
final isEnrolled = await pushNotification.hasEnrollment(
  issuer: issuer,
  accountId: accountId,
);
```

### Un-enroll

```dart
try {
  await pushNotification.unenrollDevice(issuer: issuer, accountId: accountId);
  // The device is un-enrolled.
} on PushNotificationException catch (e) {
  switch (e) {
    case NotEnrolledException():
      // Nothing to un-enroll.
    case UnenrollmentRejectedException():
    case NetworkFailureException():
      // The Strivacity backend call failed, but the local enrollment was
      // removed anyway. The backend may still believe the device is enrolled.
    default:
      // Looking up the key, or removing the enrollment locally, failed.
  }
}
```

The local key and enrollment are always removed, even when the backend call fails, so a backend failure never leaves the device unable to enroll again. The trade-off is that the backend may keep a stale enrollment. If the local removal itself fails, `unenrollDevice` throws that failure (`StorageFailureException`) even when the backend call failed too, and the backend's failure is lost.

### List Enrollments

```dart
final enrollments = await pushNotification.listEnrollments();
for (final enrollment in enrollments) {
  print('${enrollment.userName} at ${enrollment.issuer}');
}
```

Each `Enrollment` carries the `issuer`, `accountId`, `keyId`, and, when known, the `userName` and `deviceName`.

### Report a Refreshed Push Token

Your app owns push registration, including detecting when the token rotates. When it does, list the enrollments and decide what to do with each: update all of them, warn the user first, or skip the ones you do not recognize:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
  for (final enrollment in await pushNotification.listEnrollments()) {
    try {
      await pushNotification.updateDeviceToken(
        issuer: enrollment.issuer,
        accountId: enrollment.accountId,
        deviceToken: token,
        deviceTokenType: DeviceTokenType.fcmToken,
      );
    } on PushNotificationException catch (e) {
      // `tokenUpdateRejected`: the Strivacity backend refused the update for
      // this enrollment. Anything else, such as `networkFailure`: retry later,
      // or skip it.
    }
  }
});
```

## Error Handling

Every failure is a `PushNotificationException`, a sealed class with one subclass per kind of failure, so a `switch` over it can be checked for completeness. `message` describes the failure, and `code` is a stable string such as `already_enrolled` that is the same on every platform, which is useful for logging and error reporting. Exceptions never contain sensitive material such as tokens, keys or signed values. The four failures that come from a Strivacity backend response (`EnrollmentRejectedException`, `UnenrollmentRejectedException`, `TokenUpdateRejectedException` and `ChallengeUnavailableException`) also carry the HTTP `status`, when there was one; no other exception has it. A failure the native SDK doesn't describe, such as a raw Keystore or CryptoKit error, arrives as an `UnexpectedException`, with only its type as the message.

```dart
try {
  await pushNotification.listEnrollments();
} on PushNotificationException catch (e) {
  final text = switch (e) {
    NetworkFailureException() => 'Check your connection.',
    StorageFailureException() => 'The device could not read its stored enrollments.',
    _ => 'Something went wrong (${e.code}).',
  };
}
```

| Exception | Meaning |
| --- | --- |
| `InvalidGrantException` | The enrollment grant is malformed. |
| `InvalidIssuerException` | The issuer is not an absolute https URL. |
| `InvalidDeviceNameException` | The device name, after trimming, is not 1 to 64 characters. |
| `EnrollmentRejectedException` | The Strivacity backend refused the enrollment, for example because the one-time token is invalid. Not retryable. |
| `AlreadyEnrolledException` | An enrollment already exists for this issuer and account. Un-enroll first. |
| `UnenrollmentRejectedException` | The Strivacity backend refused the un-enrollment. The local enrollment is removed regardless. |
| `TokenUpdateRejectedException` | The Strivacity backend refused a push token update. |
| `NotEnrolledException` | The device holds no enrollment for this issuer and account. |
| `ChallengeUnavailableException` | The push payload is not a challenge the plugin can read, or the Strivacity backend refused it, returned one the plugin can't read, or failed its resolution. |
| `UnsupportedChallengeTypeException` | The Strivacity backend sent a challenge type this version does not support. |
| `UnsupportedAlgorithmException` | The key's signing algorithm is not supported. |
| `StorageFailureException` | Generating, reading or signing with a key, or recording or removing an enrollment, failed. |
| `SoftwareBackedKeyException` | Only a software-backed key is available, and the app has not allowed one. |
| `NetworkFailureException` | The Strivacity backend could not be reached, or its response was unreadable. |
| `InvalidChallengeOptionException` | The selected option is not one the challenge offered. |
| `UnexpectedException` | A failure outside the other categories, including platform errors the native SDK doesn't wrap. Passing an `apns` token on Android also ends here. |

## Running on an Emulator or Simulator

Emulators and simulators have no secure hardware, so they produce software-backed keys. Enrollment on them fails with `softwareBackedKey` unless you opt in when creating the instance:

```dart
final pushNotification = await PushNotification.getInstance(
  allowSoftwareBackedKeys: kDebugMode,
);
```

> ⚠️ **Important:** Enable `allowSoftwareBackedKeys` only in debug builds. A production build should never allow software-backed keys. Tying the flag to `kDebugMode` guarantees that a release build cannot sign with a software key.

Push delivery has its own limits: iOS pushes need a physical device, and an Android emulator needs a Google Play system image.

## Security Considerations

- **Keys are hardware-backed by default.** On physical devices they live in the Android Keystore (TEE or StrongBox) or the iOS Secure Enclave. The plugin requires this unless you opt out explicitly.
- **Private keys never leave the device.** Signing happens in secure hardware, and only signatures cross the network.
- **Enrollment details are protected differently per platform.** On iOS the issuer, account id, user name and device name sit in the same Keychain item as the key. On Android the plugin records them in a private `SharedPreferences` file without encrypting it, while the key itself stays in the Keystore.
- **The one-time token is single-use.** A failed enrollment cannot be retried with the same token.
- **The challenge value prevents replay.** It is a single-use value that the Strivacity backend invalidates on first use, and it is bound into the signed resolution.
- **The default is the secure option.** Software-backed keys must be allowed explicitly.
