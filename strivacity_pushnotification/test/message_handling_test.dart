import 'package:flutter_test/flutter_test.dart';
import 'package:strivacity_pushnotification/src/internal/platform_api.g.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import 'fakes/fake_platform_api.dart';

/// Exercises handling a push payload and answering the challenge it carries.
void main() {
  late FakePlatformApi api;
  late PushNotification push;

  setUp(() async {
    PushNotification.resetInstance();
    api = FakePlatformApi();
    push = await PushNotification.getInstanceWith(api);
  });

  const payload = <String, Object?>{
    'com.strivacity': '{"version":"1"}',
    'aps': {'alert': 'Approve sign-in'},
  };

  PlatformChallenge contextMatching({List<String>? options}) =>
      PlatformChallenge(
        type: PlatformChallengeType.contextMatching,
        challengeId: 'challenge-2',
        issuer: 'https://issuer.example.com',
        accountId: 'account-1',
        expiresAt: '2026-10-01T14:30:00Z',
        metadata: {},
        serialized: 'serialized-context-matching',
        options: options,
      );

  test('asks the platform whether the payload can be handled', () async {
    api.canHandle = false;

    final canHandle = await push.canHandleMessage(payload);

    expect(canHandle, isFalse);
  });

  test(
    'passes the whole payload to the platform, nested values included',
    () async {
      await push.canHandleMessage(payload);

      expect(api.callsTo('canHandleMessage'), [
        [payload],
      ]);
    },
  );

  test('returns a simple challenge for a simple platform challenge', () async {
    final challenge = await push.handleMessage(payload);

    expect(challenge, isA<SimpleChallenge>());
  });

  test('carries the challenge fields into the public challenge', () async {
    final challenge = await push.handleMessage(payload);

    expect(
      [
        challenge.challengeId,
        challenge.issuer,
        challenge.accountId,
        challenge.expiresAt,
      ],
      [
        'challenge-1',
        'https://issuer.example.com',
        'account-1',
        '2026-10-01T14:30:00Z',
      ],
    );
  });

  test('keeps metadata entries whose value is null', () async {
    final challenge = await push.handleMessage(payload);

    expect(challenge.metadata, {'place': 'New York', 'device': null});
  });

  test('returns a context-matching challenge with its options', () async {
    api.challenge = contextMatching(options: ['12', '26', '84']);

    final challenge = await push.handleMessage(payload);

    expect((challenge as ContextMatchingChallenge).options, ['12', '26', '84']);
  });

  test(
    'rejects a context-matching challenge that arrives without options',
    () async {
      api.challenge = contextMatching();

      await expectLater(
        push.handleMessage(payload),
        throwsA(isA<UnexpectedException>()),
      );
    },
  );

  test(
    'submitting an approval resolves the challenge the platform handed out',
    () async {
      final challenge = await push.handleMessage(payload) as SimpleChallenge;

      await push.resolveChallenge(challenge.approve());

      expect(api.callsTo('resolveChallenge'), [
        ['serialized-challenge', PlatformResolutionAction.approve, null],
      ]);
    },
  );

  test(
    'submitting a denial resolves the challenge the platform handed out',
    () async {
      final challenge = await push.handleMessage(payload);

      await push.resolveChallenge(challenge.deny());

      expect(api.callsTo('resolveChallenge'), [
        ['serialized-challenge', PlatformResolutionAction.deny, null],
      ]);
    },
  );

  test('submitting a selection sends the chosen option', () async {
    api.challenge = contextMatching(options: ['12', '26']);
    final challenge =
        await push.handleMessage(payload) as ContextMatchingChallenge;

    await push.resolveChallenge(challenge.select('26'));

    expect(api.callsTo('resolveChallenge'), [
      ['serialized-context-matching', PlatformResolutionAction.select, '26'],
    ]);
  });

  test('building a resolution does not call the platform', () async {
    final challenge = await push.handleMessage(payload) as SimpleChallenge;

    // The statement is a single call; a cascade would only obscure it.
    // ignore: cascade_invocations
    challenge.approve();

    expect(api.callsTo('resolveChallenge'), isEmpty);
  });

  test('a resolution can be submitted again', () async {
    final challenge = await push.handleMessage(payload);
    final resolution = challenge.deny();

    await push.resolveChallenge(resolution);
    await push.resolveChallenge(resolution);

    expect(api.callsTo('resolveChallenge'), hasLength(2));
  });

  test('selecting an offered option does not throw', () async {
    api.challenge = contextMatching(options: ['12', '26']);
    final challenge =
        await push.handleMessage(payload) as ContextMatchingChallenge;

    expect(() => challenge.select('12'), returnsNormally);
  });

  test('selecting an option that was not offered throws immediately', () async {
    api.challenge = contextMatching(options: ['12', '26']);
    final challenge =
        await push.handleMessage(payload) as ContextMatchingChallenge;

    expect(
      () => challenge.select('99'),
      throwsA(isA<InvalidChallengeOptionException>()),
    );
  });

  test('a rejected selection never reaches the platform', () async {
    api.challenge = contextMatching(options: ['12', '26']);
    final challenge =
        await push.handleMessage(payload) as ContextMatchingChallenge;

    try {
      challenge.select('99');
    } on PushNotificationException {
      // Expected: the option was not offered.
    }

    expect(api.callsTo('resolveChallenge'), isEmpty);
  });

  test('reports an accepted resolution as ok', () async {
    final challenge = await push.handleMessage(payload) as SimpleChallenge;

    expect(
      await push.resolveChallenge(challenge.approve()),
      ResolutionResult.ok,
    );
  });

  test('reports a refused resolution as notOk', () async {
    api.resolutionResult = PlatformResolutionResult.notOk;
    final challenge = await push.handleMessage(payload) as SimpleChallenge;

    expect(
      await push.resolveChallenge(challenge.approve()),
      ResolutionResult.notOk,
    );
  });

  test('describes a resolution by challenge id and action', () async {
    final challenge = await push.handleMessage(payload) as SimpleChallenge;

    expect(
      challenge.approve().toString(),
      'ChallengeResolution(challengeId: challenge-1, action: approve)',
    );
  });

  test('describes a selection by the chosen option', () async {
    api.challenge = contextMatching(options: ['12', '26']);
    final challenge =
        await push.handleMessage(payload) as ContextMatchingChallenge;

    expect(
      challenge.select('26').toString(),
      'ChallengeResolution(challengeId: challenge-2, action: 26)',
    );
  });

  test(
    'keeps the serialized challenge out of a resolution description',
    () async {
      final challenge = await push.handleMessage(payload);

      expect(
        challenge.deny().toString(),
        isNot(contains('serialized-challenge')),
      );
    },
  );

  test('keeps the serialized challenge out of its description', () async {
    final challenge = await push.handleMessage(payload);

    expect(challenge.toString(), isNot(contains('serialized-challenge')));
  });

  test('exposes metadata as read-only', () async {
    final challenge = await push.handleMessage(payload);

    expect(() => challenge.metadata['extra'] = 'x', throwsUnsupportedError);
  });

  test('exposes options as read-only', () async {
    api.challenge = contextMatching(options: ['12']);
    final challenge =
        await push.handleMessage(payload) as ContextMatchingChallenge;

    expect(() => challenge.options.add('99'), throwsUnsupportedError);
  });
}
