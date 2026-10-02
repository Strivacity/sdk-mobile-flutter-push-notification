import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

typedef AnswerChallenge = Future<ResolutionResult> Function(ChallengeResolution resolution);

/// Submits the user's answer.
Future<ResolutionResult> answerChallenge(PushNotification sdk, ChallengeResolution resolution) =>
    sdk.resolveChallenge(resolution);
