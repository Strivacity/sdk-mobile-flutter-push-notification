/// The kind of push token the app supplies when it enrolls or reports a new token.
enum DeviceTokenType {
  /// An Apple Push Notification service token, hex encoded. iOS only: on Android, passing it
  /// fails with an `UnexpectedException`.
  apns,

  /// A Firebase Cloud Messaging registration token.
  fcmToken,

  /// A Firebase installation ID.
  fcmFid,
}
