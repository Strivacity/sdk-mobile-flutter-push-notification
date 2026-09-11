import Flutter
import UIKit

public class StrivacityPushnotificationPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "strivacity_pushnotification", binaryMessenger: registrar.messenger())
        let instance = StrivacityPushnotificationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
