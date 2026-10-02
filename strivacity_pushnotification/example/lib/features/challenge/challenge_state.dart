import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

/// [done] means the answer was submitted, whatever the backend made of it, and the screen closes.
enum ChallengeStatus { loading, ready, resolving, done, failure }

typedef ChallengeState = ({
  ChallengeStatus status,

  /// Null until fetched.
  Challenge? challenge,

  /// The message for a [ChallengeStatus.failure]; null otherwise.
  String? error,
});

extension ChallengeStateCopy on ChallengeState {
  /// A copy with the given fields replaced. A nullable field takes a function returning its new
  /// value, so that null can be set: `copyWith(error: () => null)`.
  ChallengeState copyWith({
    ChallengeStatus? status,
    Challenge? Function()? challenge,
    String? Function()? error,
  }) => (
    status: status ?? this.status,
    challenge: challenge == null ? this.challenge : challenge(),
    error: error == null ? this.error : error(),
  );
}
