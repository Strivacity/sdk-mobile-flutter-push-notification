import 'package:flutter/foundation.dart' show debugPrint;
import 'package:signals_core/signals_core.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import '../../usecases/answer_challenge.dart';
import '../../usecases/fetch_challenge.dart';
import 'challenge_state.dart';

/// The challenge screen's state, and the answers the user can give.
class ChallengeViewModel {
  ChallengeViewModel({required this._fetchChallenge, required this._answerChallenge});

  final FetchChallenge _fetchChallenge;
  final AnswerChallenge _answerChallenge;

  final _state = signal<ChallengeState>((status: ChallengeStatus.loading, challenge: null, error: null));

  /// What the screen shows. Only this view model changes it.
  ReadonlySignal<ChallengeState> get state => _state;

  /// The current state, read without subscribing, so an effect that calls in here does not come to
  /// depend on it.
  ChallengeState get _value => _state.peek();

  /// The screen is up: fetch the challenge the push [payload] points at.
  Future<void> load(Map<String, Object?> payload) async {
    try {
      final challenge = await _fetchChallenge(payload);
      _emit(_value.copyWith(status: ChallengeStatus.ready, challenge: () => challenge, error: () => null));
    } on PushNotificationException catch (error) {
      debugPrint('$error');
      _emit(_value.copyWith(status: ChallengeStatus.failure, error: () => _describeFetchFailure(error)));
    } on Object catch (error) {
      debugPrint('$error');
      _emit(_value.copyWith(status: ChallengeStatus.failure, error: () => 'The sign-in request could not be loaded.'));
    }
  }

  /// The user approved a simple challenge.
  Future<void> approve() => _resolve((challenge) => challenge is SimpleChallenge ? challenge.approve() : null);

  /// The user picked [option] of a context-matching challenge.
  Future<void> select(String option) =>
      _resolve((challenge) => challenge is ContextMatchingChallenge ? challenge.select(option) : null);

  /// The user denied the challenge.
  Future<void> deny() => _resolve((challenge) => challenge.deny());

  /// Submits the answer [answer] makes of the loaded challenge. Does nothing unless one is loaded
  /// and waiting, so a second tap can't submit twice, and neither can an answer of the wrong kind.
  Future<void> _resolve(ChallengeResolution? Function(Challenge challenge) answer) async {
    final s = _value;
    final challenge = s.challenge;
    if (s.status != ChallengeStatus.ready || challenge == null) return;

    try {
      final resolution = answer(challenge);
      if (resolution == null) return;
      _emit(s.copyWith(status: ChallengeStatus.resolving));
      final result = await _answerChallenge(resolution);
      debugPrint('Challenge ${challenge.challengeId} resolved: $result');
      _emit(_value.copyWith(status: ChallengeStatus.done));
    } on PushNotificationException catch (error) {
      debugPrint('$error');
      _emit(_value.copyWith(status: ChallengeStatus.failure, error: () => _describeResolveFailure(error)));
    } on Object catch (error) {
      debugPrint('$error');
      _emit(_value.copyWith(status: ChallengeStatus.failure, error: () => 'Your answer could not be sent.'));
    }
  }

  /// Sets the state, unless the screen has gone: a fetch or an answer can finish after it closed.
  void _emit(ChallengeState state) {
    if (!_state.disposed) _state.value = state;
  }

  void dispose() => _state.dispose();

  static String _describeFetchFailure(PushNotificationException error) => switch (error) {
    ChallengeUnavailableException() => 'This sign-in request is no longer available. It may have expired.',
    NetworkFailureException() => 'The server could not be reached. Check the connection.',
    NotEnrolledException() => 'This device is not enrolled for that account.',
    _ => 'The sign-in request could not be loaded.',
  };

  static String _describeResolveFailure(PushNotificationException error) => switch (error) {
    NetworkFailureException() => 'Your answer could not be sent. Check the connection.',
    _ => 'Your answer could not be sent.',
  };
}
