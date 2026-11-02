import Flutter
import UIKit
import UserNotifications
import firebase_messaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let apnsPushes = ApnsPushes()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // This app delegate is the one notification delegate. The Firebase plugin leaves it in place
    // because it is a FlutterAppDelegate, and is reached through `registeredPlugins` below.
    UNUserNotificationCenter.current().delegate = self
    FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Registering plugins leaves this app delegate in place. If a plugin ever
    // took the delegate, it would forward back to us and we to it, in a loop.
    if UNUserNotificationCenter.current().delegate !== self {
      NSLog("Notification delegate was replaced by a plugin: \(String(describing: UNUserNotificationCenter.current().delegate))")
    }
    apnsPushes.attach(engineBridge.applicationRegistrar.messenger())
  }

  // MARK: Notification delegate

  // A push that came through FCM carries `gcm.message_id`, and goes to the plugins registered with
  // Flutter. One that came straight from APNs has none, and goes to `apnsPushes`, because the
  // Firebase plugin ignores it.

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if apnsPushes.handle(notification.request.content.userInfo) {
      // No banner: the app opens the challenge itself.
      completionHandler([])
    } else {
      registeredPlugins.willPresent(center, notification, completionHandler)
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if apnsPushes.handle(response.notification.request.content.userInfo) {
      completionHandler()
    } else {
      registeredPlugins.didReceive(center, response, completionHandler)
    }
  }

  /// `super` under a name that says what it does. FlutterAppDelegate passes these calls to every
  /// plugin registered with Flutter for app callbacks, such as `firebase_messaging` (FCM), which
  /// then also calls the completion handler. This is how to reach the other registered plugins'
  /// notification handling; do not call the completion handler as well.
  private var registeredPlugins: RegisteredPlugins {
    RegisteredPlugins(
      willPresent: { center, notification, completionHandler in
        super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
      },
      didReceive: { center, response, completionHandler in
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
      }
    )
  }
}

private struct RegisteredPlugins {
  let willPresent: (UNUserNotificationCenter, UNNotification, @escaping (UNNotificationPresentationOptions) -> Void) -> Void
  let didReceive: (UNUserNotificationCenter, UNNotificationResponse, @escaping () -> Void) -> Void
}

/// Hands Dart the pushes that came straight from APNs.
///
/// A tap that starts the app arrives before Dart is listening, so pushes are held until Dart
/// collects them with `takeQueued`, and sent live from then on.
final class ApnsPushes {
  // Must match `ApnsPushes` in lib/push/apns_pushes.dart.
  private static let channelName = "com.strivacity.flutter.strivacity_pushnotification_example/apns_pushes"

  private var channel: FlutterMethodChannel?
  private var queued: [[String: Any]] = []
  private var dartIsListening = false

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "takeQueued", let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      let held = self.queued
      self.queued = []
      self.dartIsListening = true
      result(held)
    }
    self.channel = channel
  }

  /// Takes the push if it came straight from APNs, and returns whether it did.
  func handle(_ userInfo: [AnyHashable: Any]) -> Bool {
    guard userInfo["gcm.message_id"] == nil else { return false }
    // The custom entries only, as Firebase's `data` has.
    var payload: [String: Any] = [:]
    for (key, value) in userInfo {
      if let key = key as? String, key != "aps" { payload[key] = value }
    }
    if dartIsListening {
      channel?.invokeMethod("push", arguments: payload)
    } else {
      queued.append(payload)
    }
    return true
  }
}
