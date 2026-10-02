import Flutter
@_spi(PluginBridge) import PushNotification

/// Connects the Dart push notification API to the native iOS SDK.
public class StrivacityPushnotificationPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let host = PushNotificationHost(
            sdkFactory: { allowSoftwareBackedKeys in
                PushNotification(
                    storage: DefaultPushNotificationStorage(allowSoftwareBackedKeys: allowSoftwareBackedKeys)
                )
            },
            parseGrant: { url in
                guard let parsed = URL(string: url) else {
                    throw PushNotificationError.invalidGrant(message: "The enrollment grant is not a valid URL")
                }
                return try EnrollmentGrant.parse(parsed)
            }
        )
        PushNotificationPlatformApiSetup.setUp(binaryMessenger: registrar.messenger(), api: host)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        PushNotificationPlatformApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
    }
}
