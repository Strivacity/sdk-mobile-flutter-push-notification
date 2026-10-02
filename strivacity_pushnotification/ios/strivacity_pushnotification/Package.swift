// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "strivacity_pushnotification",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
        .library(name: "strivacity-pushnotification", targets: ["strivacity_pushnotification"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Strivacity/sdk-mobile-ios-push-notification.git", exact: "1.0.0-rc1"),
    ],
    targets: [
        .target(
            name: "strivacity_pushnotification",
            dependencies: [
                .product(name: "PushNotification", package: "sdk-mobile-ios-push-notification"),
            ],
            resources: [
                // If your plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        ),
        .testTarget(
            name: "strivacity_pushnotificationTests",
            dependencies: [
                "strivacity_pushnotification",
                .product(name: "PushNotification", package: "sdk-mobile-ios-push-notification"),
            ]
        ),
    ]
)
