import 'package:pigeon/pigeon.dart';

/// Schema of the calls between Dart and the native push notification SDKs. Running
/// `dart run pigeon --input pigeons/push_notification_api.dart` regenerates the Dart, Kotlin and
/// Swift sources.
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/internal/platform_api.g.dart',
    kotlinOut: 'android/src/main/kotlin/com/strivacity/flutter/strivacity_pushnotification/PlatformApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.strivacity.flutter.strivacity_pushnotification',
    ),
    swiftOut: 'ios/strivacity_pushnotification/Sources/strivacity_pushnotification/PlatformApi.g.swift',
    dartPackageName: 'strivacity_pushnotification',
  ),
)
/// The kind of push token the app supplies.
enum PlatformDeviceTokenType {
  /// An Apple Push Notification service token.
  apns,

  /// A Firebase Cloud Messaging registration token.
  fcmToken,

  /// A Firebase installation ID.
  fcmFid,
}

/// The outcome of submitting a resolution.
enum PlatformResolutionResult {
  /// The backend accepted the resolution.
  ok,

  /// The backend did not accept the resolution.
  notOk,
}

/// The kind of decision a challenge asks for.
enum PlatformChallengeType {
  /// Approve or deny.
  simple,

  /// Choose one of the offered options, or deny.
  contextMatching,
}

/// What a resolution does with its challenge.
enum PlatformResolutionAction {
  /// Allows the sign-in.
  approve,

  /// Refuses the sign-in.
  deny,

  /// Answers a context-matching challenge with one of its options.
  select,
}

/// Settings applied when the native SDK is built.
class PlatformCreateOptions {
  /// Creates the settings.
  PlatformCreateOptions({required this.allowSoftwareBackedKeys});

  /// Whether enrollment may use keys that are not hardware backed.
  bool allowSoftwareBackedKeys;
}

/// The payload that authorizes this device to enroll.
class PlatformEnrollmentGrant {
  /// Creates a grant.
  PlatformEnrollmentGrant({
    required this.issuer,
    required this.oneTimeToken,
    required this.accountId,
    required this.displayUserName,
  });

  /// The issuer, normalized to scheme plus lowercased authority.
  String issuer;

  /// The single-use token that authorizes the enrollment.
  String oneTimeToken;

  /// The account the device enrolls for.
  String accountId;

  /// The name shown to the user.
  String displayUserName;
}

/// A device's enrollment for one account at one issuer.
class PlatformEnrollment {
  /// Creates an enrollment.
  PlatformEnrollment({
    required this.issuer,
    required this.accountId,
    required this.keyId,
    this.userName,
    this.deviceName,
  });

  /// The issuer the device is enrolled with.
  String issuer;

  /// The enrolled account.
  String accountId;

  /// The identifier of the enrollment's key.
  String keyId;

  /// The name shown for the user, if known.
  String? userName;

  /// The name of this device, if known.
  String? deviceName;
}

/// A challenge waiting on a decision.
class PlatformChallenge {
  /// Creates a challenge.
  PlatformChallenge({
    required this.type,
    required this.challengeId,
    required this.issuer,
    required this.accountId,
    required this.expiresAt,
    required this.metadata,
    required this.serialized,
    this.options,
  });

  /// The kind of decision the challenge asks for.
  PlatformChallengeType type;

  /// The identifier of the challenge.
  String challengeId;

  /// The issuer the challenge came from.
  String issuer;

  /// The account the challenge is for.
  String accountId;

  /// When the challenge expires, as an ISO 8601 instant.
  String expiresAt;

  /// Backend-supplied context for the decision.
  Map<String, String?> metadata;

  /// An opaque string the native side reads back to resolve this challenge.
  String serialized;

  /// The offered options of a context-matching challenge.
  List<String>? options;
}

/// A user's answer to a challenge.
class PlatformChallengeResolution {
  /// Creates a resolution.
  PlatformChallengeResolution({
    required this.serialized,
    required this.action,
    this.option,
  });

  /// The opaque string of the challenge being resolved.
  String serialized;

  /// What the resolution does with the challenge.
  PlatformResolutionAction action;

  /// The chosen option. Set for [PlatformResolutionAction.select] only.
  String? option;
}

/// The native push notification SDK, as called from Dart.
@HostApi()
abstract class PushNotificationPlatformApi {
  /// Builds the native SDK with the platform defaults.
  ///
  /// Repeating the call with the same options is a no-op. Different options fail with the
  /// error code `configuration_conflict`.
  @async
  void create(PlatformCreateOptions options);

  /// Parses an enrollment grant URL.
  @async
  PlatformEnrollmentGrant parseEnrollmentGrant(String url);

  /// Enrolls this device.
  @async
  PlatformEnrollment enrollDevice(
    PlatformEnrollmentGrant grant,
    String deviceToken,
    PlatformDeviceTokenType deviceTokenType,
    String deviceName,
  );

  /// Removes this device's enrollment.
  @async
  void unenrollDevice(String issuer, String accountId);

  /// Whether this device holds an enrollment for the account.
  @async
  bool hasEnrollment(String issuer, String accountId);

  /// Lists this device's enrollments.
  @async
  List<PlatformEnrollment> listEnrollments();

  /// Reports a new push token for an enrollment.
  @async
  void updateDeviceToken(
    String issuer,
    String accountId,
    String deviceToken,
    PlatformDeviceTokenType deviceTokenType,
  );

  /// Whether the push payload is a challenge this device can handle.
  @async
  bool canHandleMessage(Map<String, Object?> payload);

  /// Fetches the challenge a push payload points at.
  @async
  PlatformChallenge handleMessage(Map<String, Object?> payload);

  /// Submits the user's answer to a challenge.
  @async
  PlatformResolutionResult resolveChallenge(
    PlatformChallengeResolution resolution,
  );
}
