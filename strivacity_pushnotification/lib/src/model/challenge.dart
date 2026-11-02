import '../internal/platform_api.g.dart';
import 'push_notification_exception.dart';

/// An MFA request waiting on a decision.
///
/// A challenge is obtained from `PushNotification.handleMessage`. The user's decision becomes a
/// [ChallengeResolution] through [SimpleChallenge.approve], [ContextMatchingChallenge.select] or
/// [Challenge.deny], and `PushNotification.resolveChallenge` submits it.
sealed class Challenge {
  Challenge._({
    required this.challengeId,
    required this.issuer,
    required this.accountId,
    required this.expiresAt,
    required Map<String, String?> metadata,
    required String serialized,
  }) : metadata = Map.unmodifiable(metadata),
       _serialized = serialized;

  /// The identifier of the challenge.
  final String challengeId;

  /// The issuer the challenge came from.
  final String issuer;

  /// The account the challenge is for.
  final String accountId;

  /// When the challenge expires, as an ISO 8601 instant. The backend enforces it.
  final String expiresAt;

  /// Backend-supplied context for the decision, such as device, location or time.
  ///
  /// Keys are not guaranteed and values may be null.
  final Map<String, String?> metadata;

  // Holds the single-use challenge value, so it is read only by [ChallengeResolution].
  final String _serialized;

  /// The user refused. A denial is a normal result, not an error.
  ChallengeResolution deny() =>
      ChallengeResolution._(this, PlatformResolutionAction.deny);

  @override
  String toString() =>
      '$runtimeType(challengeId: $challengeId, issuer: $issuer, '
      'accountId: $accountId, expiresAt: $expiresAt)';
}

/// A challenge that asks only whether to allow the sign-in.
final class SimpleChallenge extends Challenge {
  SimpleChallenge._({
    required super.challengeId,
    required super.issuer,
    required super.accountId,
    required super.expiresAt,
    required super.metadata,
    required super.serialized,
  }) : super._();

  /// The user allowed the sign-in.
  ChallengeResolution approve() =>
      ChallengeResolution._(this, PlatformResolutionAction.approve);
}

/// A challenge that asks the user to pick one of [options], shown alongside the same value on
/// the device signing in.
final class ContextMatchingChallenge extends Challenge {
  ContextMatchingChallenge._({
    required super.challengeId,
    required super.issuer,
    required super.accountId,
    required super.expiresAt,
    required super.metadata,
    required super.serialized,
    required List<String> options,
  }) : options = List.unmodifiable(options),
       super._();

  /// The options the user chooses from.
  final List<String> options;

  /// The user chose [option].
  ///
  /// Throws an [InvalidChallengeOptionException] when [option] is not one of [options].
  ChallengeResolution select(String option) {
    if (!options.contains(option)) {
      throw InvalidChallengeOptionException(
        message:
            "The selected option was not among those offered for challenge '$challengeId'",
      );
    }
    return ChallengeResolution._(this, PlatformResolutionAction.select, option);
  }
}

/// A user's answer to a challenge, ready to submit with `PushNotification.resolveChallenge`.
///
/// Obtained from [SimpleChallenge.approve], [ContextMatchingChallenge.select] or
/// [Challenge.deny]. It carries the challenge's single-use value, which its description omits.
final class ChallengeResolution {
  ChallengeResolution._(
    Challenge challenge,
    PlatformResolutionAction action, [
    String? option,
  ]) : _challengeId = challenge.challengeId,
       _resolution = PlatformChallengeResolution(
         serialized: challenge._serialized,
         action: action,
         option: option,
       );

  final String _challengeId;
  final PlatformChallengeResolution _resolution;

  @override
  String toString() {
    final action = switch (_resolution.action) {
      PlatformResolutionAction.approve => 'approve',
      PlatformResolutionAction.deny => 'deny',
      PlatformResolutionAction.select => _resolution.option,
    };
    return 'ChallengeResolution(challengeId: $_challengeId, action: $action)';
  }
}

/// The platform form of [resolution], which the native side acts on. Not exported.
PlatformChallengeResolution platformResolutionOf(
  ChallengeResolution resolution,
) => resolution._resolution;

/// The public challenge for a platform [challenge]. Not exported.
Challenge challengeFromPlatform(PlatformChallenge challenge) {
  switch (challenge.type) {
    case PlatformChallengeType.simple:
      return SimpleChallenge._(
        challengeId: challenge.challengeId,
        issuer: challenge.issuer,
        accountId: challenge.accountId,
        expiresAt: challenge.expiresAt,
        metadata: challenge.metadata,
        serialized: challenge.serialized,
      );
    case PlatformChallengeType.contextMatching:
      final options = challenge.options;
      if (options == null || options.isEmpty) {
        throw const UnexpectedException(
          message: 'A context-matching challenge arrived without options.',
        );
      }
      return ContextMatchingChallenge._(
        challengeId: challenge.challengeId,
        issuer: challenge.issuer,
        accountId: challenge.accountId,
        expiresAt: challenge.expiresAt,
        metadata: challenge.metadata,
        serialized: challenge.serialized,
        options: options,
      );
  }
}
