import 'package:flutter_test/flutter_test.dart';
import 'package:strivacity_pushnotification/src/internal/platform_api.g.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import 'fakes/fake_platform_api.dart';

/// Exercises enrolling, un-enrolling, listing and token updates.
void main() {
  late FakePlatformApi api;
  late PushNotification push;

  setUp(() async {
    PushNotification.resetInstance();
    api = FakePlatformApi();
    push = await PushNotification.getInstanceWith(api);
  });

  const grant = EnrollmentGrant(
    issuer: 'https://issuer.example.com',
    oneTimeToken: 'one-time-token',
    accountId: 'account-1',
    displayUserName: 'Ada',
  );

  test('parses an enrollment grant URL', () async {
    final parsed = await push.parseEnrollmentGrant('https://example.com/grant');

    expect(parsed, grant);
  });

  test('passes the grant URL to the platform unchanged', () async {
    await push.parseEnrollmentGrant('https://example.com/grant');

    expect(api.callsTo('parseEnrollmentGrant'), [
      ['https://example.com/grant'],
    ]);
  });

  test('enrolls with the grant, token, token type and device name', () async {
    await push.enrollDevice(
      grant: grant,
      deviceToken: 'token-1',
      deviceTokenType: DeviceTokenType.fcmToken,
      deviceName: 'Pixel',
    );

    final call = api.callsTo('enrollDevice').single;
    expect(
      [
        (call[0] as PlatformEnrollmentGrant).oneTimeToken,
        call[1],
        call[2],
        call[3],
      ],
      ['one-time-token', 'token-1', PlatformDeviceTokenType.fcmToken, 'Pixel'],
    );
  });

  test('returns the enrollment the platform created', () async {
    final enrollment = await push.enrollDevice(
      grant: grant,
      deviceToken: 'token-1',
      deviceTokenType: DeviceTokenType.apns,
      deviceName: 'Pixel',
    );

    expect(
      enrollment,
      const Enrollment(
        issuer: 'https://issuer.example.com',
        accountId: 'account-1',
        keyId: 'key-1',
        userName: 'Ada',
        deviceName: 'Pixel',
      ),
    );
  });

  test('un-enrolls the named account', () async {
    await push.unenrollDevice(
      issuer: 'https://issuer.example.com',
      accountId: 'account-1',
    );

    expect(api.callsTo('unenrollDevice'), [
      ['https://issuer.example.com', 'account-1'],
    ]);
  });

  test('reports whether an enrollment key is held', () async {
    api.hasKey = false;

    final held = await push.hasEnrollment(
      issuer: 'https://issuer.example.com',
      accountId: 'account-1',
    );

    expect(held, isFalse);
  });

  test('lists the enrollments the platform holds', () async {
    api.enrollments = [api.enrollment];

    final enrollments = await push.listEnrollments();

    expect(enrollments.map((e) => e.keyId), ['key-1']);
  });

  test('lists no enrollments when none are held', () async {
    expect(await push.listEnrollments(), isEmpty);
  });

  test('reports a new token with its token type', () async {
    await push.updateDeviceToken(
      issuer: 'https://issuer.example.com',
      accountId: 'account-1',
      deviceToken: 'token-2',
      deviceTokenType: DeviceTokenType.fcmFid,
    );

    expect(api.callsTo('updateDeviceToken'), [
      [
        'https://issuer.example.com',
        'account-1',
        'token-2',
        PlatformDeviceTokenType.fcmFid,
      ],
    ]);
  });

  test('keeps the one-time token out of the grant description', () {
    expect(grant.toString(), isNot(contains('one-time-token')));
  });

  test('treats equal enrollments as equal', () {
    const a = Enrollment(issuer: 'i', accountId: 'a', keyId: 'k');
    const b = Enrollment(issuer: 'i', accountId: 'a', keyId: 'k');

    expect(a, b);
  });
}
