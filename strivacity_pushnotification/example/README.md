# strivacity_pushnotification_example

Demonstrates how to use the `strivacity_pushnotification` plugin.

The example receives push messages through Firebase Cloud Messaging (FCM) on Android and iOS, and passes the device token and received payloads to the plugin. On iOS, the device token is the APNs token by default. See [Choosing the iOS push service](#choosing-the-ios-push-service).

## Code tour

The app starts at `lib/main.dart`, which runs `PushExampleApp` with the objects made by `createAppDependencies()` in `lib/dependency.dart`.

- **Startup:** `usecases/launch_app.dart` starts Firebase, the push SDK, the device token source, and the challenge inbox, then makes the first navigation. Nothing else navigates first.
- **Wiring:** `dependency.dart` is the only place that builds objects and decides what each one receives. It makes one view model for each screen, and each use case is handed the SDK once it is ready. Add new dependencies there, and pass them in through constructors.
- **Configuration:** `config.dart` holds the iOS push service and Firebase options. `firebase_options.dart` is generated and git-ignored.
- **SDK access:** every call to the push SDK is made in `usecases/`, and each use case takes the SDK as a parameter. Features and widgets import SDK types, such as `Enrollment`, but do not call the SDK.
- **Use cases:** `usecases/` has one file per action, such as enrolling, unenrolling, fetching and answering a challenge, and reporting the device token.
- **Push:** `usecases/push/` holds the device token source (APNs or FCM, including token rotation), the challenge inbox (collects challenge pushes from FCM, APNs, and launch intents), notification permission, and the native APNs channel.
- **Screens:** `features/<name>/` has a screen and, for home and challenge, a view model and its state. A view model holds its state in signals, and the screen rebuilds from them.
- **Navigation:** `routes.dart` defines the route names (`AppRoute`), the screen for each route, and `AppNavigator`. `AppNavigator` is how code outside the widget tree, such as startup and push challenges, navigates. Links in the app's URL scheme open the app but are not acted on: deep linking is turned off in `Info.plist` and `AndroidManifest.xml`.
- **Shared UI:** `widgets/` and `theme/`. `previews.dart` holds the widget previews, which the app does not use.

## Contents

- [Code tour](#code-tour)
- [Requirements](#requirements)
- [Firebase setup](#firebase-setup)
  - [1. Add the apps to a Firebase project](#1-add-the-apps-to-a-firebase-project)
  - [2. Android](#2-android)
  - [3. iOS](#3-ios)
    - [Choosing the iOS push service](#choosing-the-ios-push-service)
  - [4. Run the app](#4-run-the-app)
- [Troubleshooting](#troubleshooting)
  - [`cannot load such file -- xcodeproj`](#cannot-load-such-file----xcodeproj)

## Requirements

- A Firebase project, and the [Firebase CLI](https://firebase.google.com/docs/cli).
- For iOS: an Apple Developer Program membership and a physical iPhone. Push notifications through FCM and APNs need a physical device.
- For Android: a device, or an emulator that uses a Google Play system image. The emulator should run API 33 or higher to see the notification permission prompt.
- The platform minimums of the plugin and of Firebase Cloud Messaging: Android API 29 and iOS 15.

## Firebase setup

The example needs its own Firebase project configuration, which is not part of the repository. These files are specific to a Firebase project, so they are git-ignored. Generate them with the FlutterFire CLI before building the example:

- `firebase.json`
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

> ⚠️ **Important:** Without these files the example does not build and run. The Android build fails because `google-services.json` is missing, and Firebase cannot initialize without its configuration.

Firebase's own guides cover the same ground in more depth: [Add Firebase to your Flutter app](https://firebase.google.com/docs/flutter/setup) and [Set up a Firebase Cloud Messaging client app on Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client).

### 1. Add the apps to a Firebase project

Create a Firebase project, or choose an existing one, and add the Android and iOS apps to it. The Firebase console shows the steps for a Flutter app as you add each one, including installing the FlutterFire CLI.

From this directory, run the CLI and select Android and iOS to generate the four files listed above:

```bash
flutterfire configure
```

The example currently uses the application ID `com.strivacity.flutter.strivacity_pushnotification_example` on Android and the bundle identifier `com.strivacity.flutter.strivacityPushnotificationExample` on iOS. Changing them later means registering new apps.

### 2. Android

`android/settings.gradle.kts` declares the Google Services Gradle plugin, and `android/app/build.gradle.kts` applies it. The FlutterFire CLI normally adds both. If either is missing, add the declaration, with the version your Firebase setup requires:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.3.15" apply false
}
```

The example's `android/app/src/main/AndroidManifest.xml` does not declare the notification permission yet. Add it to the manifest, before the `<application>` element. Android 13 and later asks the user at runtime:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 3. iOS

Open `ios/Runner.xcworkspace` in Xcode.

1. On the Runner target, open **Signing & Capabilities**, select your team, and add the **Push Notifications** capability.
2. Add the **Background Modes** capability, and enable **Remote notifications** and **Background fetch**.
3. In the Apple Developer portal, create an **APNs authentication key** (`.p8`). Note the key ID and your team ID.
4. In the Firebase console, open **Project settings → Cloud Messaging** and upload the key with its key ID and team ID.
5. Confirm that `GoogleService-Info.plist` appears in the Runner group and is a member of the Runner target.

> 💡 **Tip:** Debug builds register with the APNs sandbox environment. A server that sends pushes to a debug build has to use the sandbox endpoint.

#### Choosing the iOS push service

The `iOSPushService` value in `lib/config.dart` selects which token the device enrolls with:

- `IOSPushService.apns` (the default): the device enrolls with its APNs token.
- `IOSPushService.fcm`: the device enrolls with its FCM token.

With `IOSPushService.fcm`, Firebase delivers the push through APNs, so it needs the APNs key you uploaded in step 3. With `IOSPushService.apns`, Strivacity sends directly to APNs and needs its own APNs credentials (the same `.p8` file can be reused). The Firebase upload in step 3 is not needed for delivery. The capabilities in steps 3.1 and 3.2 apply to both options.

### 4. Run the app

```bash
flutter run
```

Run it on a physical device for iOS. On Android, use an emulator or device with Google Play services.

## Troubleshooting

### `cannot load such file -- xcodeproj`

**Symptom.** `flutterfire configure` stops with an error like this:

```
/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/2.6.0/rubygems/core_ext/kernel_require.rb:54:in `require': cannot load such file -- xcodeproj (LoadError)
```

`android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` may already exist at this point, but `lib/firebase_options.dart` has not been generated.

**Cause.** For iOS, the CLI runs a Ruby script that updates the Xcode project, and the script needs the `xcodeproj` gem. The `ruby` that ran it is macOS's built-in Ruby 2.6, which does not include the gem. CocoaPods installed with Homebrew typically keeps its own copy of `xcodeproj`, which other Ruby installations cannot see.

**What to try.**

1. Check which Ruby runs and whether it can load the gem:

   ```bash
   ruby -v
   ```

   ```bash
   gem list xcodeproj
   ```

2. Install the gem for the Ruby that will run the CLI. With a newer Ruby first on the `PATH` (for example a Homebrew or version-manager Ruby), run the install and the CLI in the same shell:

   ```bash
   gem install xcodeproj
   ```

3. Run `flutterfire configure` again. Re-running is safe, and it can reuse the apps it already registered.
