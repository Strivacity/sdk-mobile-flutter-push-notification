import 'package:strivacity_pushnotification/src/internal/platform_api.g.dart';

/// A [PushNotificationPlatformApi] that records its calls and answers with configured values.
class FakePlatformApi extends PushNotificationPlatformApi {
  /// The calls made so far, as `method name` to the arguments passed.
  final List<(String, List<Object?>)> calls = [];

  /// Thrown by the next call, then cleared.
  Object? failureOnNextCall;

  /// Thrown by every call while set.
  Object? failureOnEveryCall;

  PlatformEnrollmentGrant grant = PlatformEnrollmentGrant(
    issuer: 'https://issuer.example.com',
    oneTimeToken: 'one-time-token',
    accountId: 'account-1',
    displayUserName: 'Ada',
  );

  PlatformEnrollment enrollment = PlatformEnrollment(
    issuer: 'https://issuer.example.com',
    accountId: 'account-1',
    keyId: 'key-1',
    userName: 'Ada',
    deviceName: 'Pixel',
  );

  List<PlatformEnrollment> enrollments = [];
  bool hasKey = true;
  bool canHandle = true;
  PlatformResolutionResult resolutionResult = PlatformResolutionResult.ok;

  PlatformChallenge challenge = PlatformChallenge(
    type: PlatformChallengeType.simple,
    challengeId: 'challenge-1',
    issuer: 'https://issuer.example.com',
    accountId: 'account-1',
    expiresAt: '2026-10-01T14:30:00Z',
    metadata: {'place': 'New York', 'device': null},
    serialized: 'serialized-challenge',
  );

  /// The arguments of every call to [method].
  List<List<Object?>> callsTo(String method) => [
    for (final (name, arguments) in calls)
      if (name == method) arguments,
  ];

  T _record<T>(String method, List<Object?> arguments, T result) {
    calls.add((method, arguments));
    final failure = failureOnNextCall ?? failureOnEveryCall;
    failureOnNextCall = null;
    if (failure != null) {
      // Tests configure any kind of failure, including non-Error objects.
      // ignore: only_throw_errors
      throw failure;
    }
    return result;
  }

  @override
  Future<void> create(PlatformCreateOptions options) async =>
      _record('create', [options.allowSoftwareBackedKeys], null);

  @override
  Future<PlatformEnrollmentGrant> parseEnrollmentGrant(String url) async =>
      _record('parseEnrollmentGrant', [url], grant);

  @override
  Future<PlatformEnrollment> enrollDevice(
    PlatformEnrollmentGrant grant,
    String deviceToken,
    PlatformDeviceTokenType deviceTokenType,
    String deviceName,
  ) async => _record('enrollDevice', [
    grant,
    deviceToken,
    deviceTokenType,
    deviceName,
  ], enrollment);

  @override
  Future<void> unenrollDevice(String issuer, String accountId) async =>
      _record('unenrollDevice', [issuer, accountId], null);

  @override
  Future<bool> hasEnrollment(String issuer, String accountId) async =>
      _record('hasEnrollment', [issuer, accountId], hasKey);

  @override
  Future<List<PlatformEnrollment>> listEnrollments() async =>
      _record('listEnrollments', [], enrollments);

  @override
  Future<void> updateDeviceToken(
    String issuer,
    String accountId,
    String deviceToken,
    PlatformDeviceTokenType deviceTokenType,
  ) async => _record('updateDeviceToken', [
    issuer,
    accountId,
    deviceToken,
    deviceTokenType,
  ], null);

  @override
  Future<bool> canHandleMessage(Map<String, Object?> payload) async =>
      _record('canHandleMessage', [payload], canHandle);

  @override
  Future<PlatformChallenge> handleMessage(Map<String, Object?> payload) async =>
      _record('handleMessage', [payload], challenge);

  @override
  Future<PlatformResolutionResult> resolveChallenge(
    PlatformChallengeResolution resolution,
  ) async => _record('resolveChallenge', [
    resolution.serialized,
    resolution.action,
    resolution.option,
  ], resolutionResult);
}
