/// The outcome of submitting a resolution.
///
/// A denial is a normal result, not an error. Calls that fail throw a `PushNotificationException`.
enum ResolutionResult {
  /// The backend accepted the resolution.
  ok,

  /// The backend did not accept the resolution.
  notOk,
}
