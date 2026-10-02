import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import 'fakes/fake_platform_api.dart';

/// Exercises how platform failures surface as `PushNotificationException`.
void main() {
  late FakePlatformApi api;
  late PushNotification push;

  setUp(() async {
    PushNotification.resetInstance();
    api = FakePlatformApi();
    push = await PushNotification.getInstanceWith(api);
  });

  Future<PushNotificationException> failureOf(PlatformException failure) async {
    api.failureOnNextCall = failure;
    try {
      await push.listEnrollments();
    } on PushNotificationException catch (e) {
      return e;
    }
    fail('Expected a PushNotificationException.');
  }

  test('maps every native error code to its exception class', () async {
    final classesByCode = <String, Matcher>{
      'invalid_grant': isA<InvalidGrantException>(),
      'invalid_issuer': isA<InvalidIssuerException>(),
      'invalid_device_name': isA<InvalidDeviceNameException>(),
      'enrollment_rejected': isA<EnrollmentRejectedException>(),
      'already_enrolled': isA<AlreadyEnrolledException>(),
      'unenrollment_rejected': isA<UnenrollmentRejectedException>(),
      'token_update_rejected': isA<TokenUpdateRejectedException>(),
      'not_enrolled': isA<NotEnrolledException>(),
      'challenge_unavailable': isA<ChallengeUnavailableException>(),
      'unsupported_challenge_type': isA<UnsupportedChallengeTypeException>(),
      'unsupported_algorithm': isA<UnsupportedAlgorithmException>(),
      'storage_failure': isA<StorageFailureException>(),
      'software_backed_key': isA<SoftwareBackedKeyException>(),
      'network_failure': isA<NetworkFailureException>(),
      'invalid_challenge_option': isA<InvalidChallengeOptionException>(),
      'unexpected': isA<UnexpectedException>(),
    };

    for (final entry in classesByCode.entries) {
      final failure = await failureOf(PlatformException(code: entry.key));

      expect(failure, entry.value, reason: entry.key);
      expect(failure.code, entry.key, reason: entry.key);
    }
  });

  test('maps an unrecognized error code to UnexpectedException', () async {
    final failure = await failureOf(PlatformException(code: 'something_new'));

    expect(failure, isA<UnexpectedException>());
  });

  test('carries the platform message', () async {
    final failure = await failureOf(
      PlatformException(code: 'not_enrolled', message: 'No enrollment'),
    );

    expect(failure.message, 'No enrollment');
  });

  test('carries the backend status from the error details', () async {
    final failure = await failureOf(
      PlatformException(code: 'enrollment_rejected', details: {'status': 401}),
    );

    expect(failure, isA<EnrollmentRejectedException>());
    expect((failure as EnrollmentRejectedException).status, 401);
  });

  test('reports no status when the details carry none', () async {
    final failure = await failureOf(
      PlatformException(code: 'enrollment_rejected', details: 'timeout'),
    );

    expect((failure as EnrollmentRejectedException).status, isNull);
  });

  test(
    'carries a status only on the failures that come from the backend',
    () async {
      final withStatus = <String, Matcher>{
        'enrollment_rejected': isA<EnrollmentRejectedException>().having(
          (e) => e.status,
          'status',
          400,
        ),
        'unenrollment_rejected': isA<UnenrollmentRejectedException>().having(
          (e) => e.status,
          'status',
          400,
        ),
        'token_update_rejected': isA<TokenUpdateRejectedException>().having(
          (e) => e.status,
          'status',
          400,
        ),
        'challenge_unavailable': isA<ChallengeUnavailableException>().having(
          (e) => e.status,
          'status',
          400,
        ),
      };

      for (final entry in withStatus.entries) {
        final failure = await failureOf(
          PlatformException(code: entry.key, details: {'status': 400}),
        );

        expect(failure, entry.value, reason: entry.key);
      }
    },
  );

  test('describes the failure with its code and status', () async {
    final failure = await failureOf(
      PlatformException(
        code: 'enrollment_rejected',
        message: 'Rejected',
        details: {'status': 401},
      ),
    );

    expect(
      failure.toString(),
      'EnrollmentRejectedException(status: 401): Rejected',
    );
  });

  test('names its own type, without a status when there is none', () async {
    final failure = await failureOf(
      PlatformException(code: 'not_enrolled', message: 'No enrollment'),
    );

    expect(failure.toString(), 'NotEnrolledException: No enrollment');
  });

  test('leaves failures that are not platform errors unchanged', () async {
    api.failureOnNextCall = ArgumentError('bad');

    await expectLater(push.listEnrollments(), throwsArgumentError);
  });

  test('maps failures from every kind of call', () async {
    api.failureOnEveryCall = PlatformException(code: 'not_enrolled');

    await expectLater(
      push.hasEnrollment(issuer: 'i', accountId: 'a'),
      throwsA(isA<PushNotificationException>()),
    );
  });

  test('reads a missing code string as UnexpectedException', () async {
    final failure = await failureOf(PlatformException(code: ''));

    expect(failure, isA<UnexpectedException>());
  });
}
